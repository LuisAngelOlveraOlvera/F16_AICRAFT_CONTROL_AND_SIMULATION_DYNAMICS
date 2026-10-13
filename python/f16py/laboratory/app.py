"""Interfaz nativa Python: tabs, proceso de cálculo y registros independientes."""
from copy import deepcopy
from datetime import datetime
import json
from pathlib import Path
import time
import tkinter as tk
from tkinter import ttk,messagebox,filedialog
import numpy as np
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg,NavigationToolbar2Tk
from .profiles import PROFILES,defaults,applicable_fields
from .experiments import aircraft_data,validate,validate_record
from .views import figure,aircraft_figure,plot_comparison,FlightView,StatesView,VARIABLES
from .worker import ExperimentWorker

FIELDS={
 'Simulación':[
  ('duracion','Duración [s]'),('paso','Paso de integración [s]'),('VT','Velocidad inicial [m/s]'),
  ('altitud','Altitud inicial [m]'),('semilla','Semilla aleatoria'),('tramo','Intervalo de consignas [s]')],
 'Condiciones iniciales':[
  ('initial.alpha_deg','Δ alfa respecto al trim [°]'),('initial.beta_deg','Δ beta respecto al trim [°]'),
  ('initial.phi_deg','Δ alabeo [°]'),('initial.theta_deg','Δ cabeceo [°]'),('initial.psi_deg','Δ rumbo [°]'),
  ('initial.p_deg_s','Δ p [°/s]'),('initial.q_deg_s','Δ q [°/s]'),('initial.r_deg_s','Δ r [°/s]')],
 'Control':[
  ('pid.kp','PID: Kp'),('pid.ki','PID: Ki'),('pid.kq','PID: Kq'),('pid.alpha_ref_deg','PID: referencia alfa [°]'),
  ('pid.alpha_initial_deg','PID: alfa inicial base [°]'),('pid.throttle','PID: throttle [0–1]'),
  ('weights.q_lon','LQR/LQI: factor Q longitudinal'),('weights.r_lon','LQR/LQI: factor R longitudinal'),
  ('weights.q_lat','LQR/LQI: factor Q lateral'),('weights.r_lat','LQR/LQI: factor R lateral'),
  ('reference.delta_h_m','Autopiloto: cambio de altitud [m]'),('reference.delta_v_m_s','Autopiloto: cambio de velocidad [m/s]'),
  ('reference.delta_psi_deg','Autopiloto: cambio de rumbo [°]'),('reference.time_s','Autopiloto: instante de cambio [s]'),
  ('reference.h_rate_m_s','Referencia: límite vertical [m/s]'),('reference.v_rate_m_s2','Referencia: límite aceleración [m/s²]'),
  ('reference.psi_rate_deg_s','Referencia: límite de rumbo [°/s]'),('reference.gamma_deg','Ascenso: ángulo [°]'),('reference.turn_deg_s','Viraje: tasa [°/s]'),
  ('reference.trayectoria_h_m','Trayectoria: amplitud de altitud [m]'),('reference.trayectoria_rumbo_deg','Trayectoria: incremento de rumbo [°]'),
  ('manual.elevador_deg','Manual: elevador [°]'),('manual.aleron_deg','Manual: alerón [°]'),('manual.timon_deg','Manual: timón [°]'),
  ('manual.throttle','Manual: throttle [0–1]'),('manual.time_s','Manual: instante de aplicación [s]')],
 'Turbulencia':[
  ('turbulence.sigma_u','Intensidad u [m/s]'),('turbulence.sigma_v','Intensidad v [m/s]'),('turbulence.sigma_w','Intensidad w [m/s]'),
  ('turbulence.length_u','Escala u [m]'),('turbulence.length_v','Escala v [m]'),('turbulence.length_w','Escala w [m]')],
}

class LaboratoryApp:
    def __init__(self,root):
        self.root=root;root.title('Laboratorio F-16 · Python');root.geometry('1200x820');root.minsize(920,680)
        self.worker=ExperimentWorker();self.profile='pid';self.values={};self.entries={};self.record_a=None;self.record_b=None;self.records=();self.current_index=0;self.playing=False;self.closed=False;self.poll_id=None;self.play_id=None
        self.profile_name=tk.StringVar();self.original=tk.BooleanVar(value=True);self.status=tk.StringVar(value='Configuración original README · lista para ejecutar');self.time_value=tk.DoubleVar(value=0)
        header=ttk.Frame(root,padding=(16,12));header.pack(fill='x')
        ttk.Label(header,text='LABORATORIO ACADÉMICO F-16',font=('Segoe UI',16,'bold')).pack(side='left')
        ttk.Label(header,text='Python · motor visual independiente',foreground='#526173').pack(side='right')
        bar=ttk.Frame(root,padding=(16,0,16,10));bar.pack(fill='x')
        combo=ttk.Combobox(bar,textvariable=self.profile_name,values=[v[0] for v in PROFILES.values()],state='readonly',width=48);combo.pack(side='left');combo.bind('<<ComboboxSelected>>',lambda e:self.load_profile(next(k for k,v in PROFILES.items() if v[0]==self.profile_name.get())))
        ttk.Checkbutton(bar,text='Configuración original README',variable=self.original,command=self.sync_fields).pack(side='left',padx=12)
        ttk.Button(bar,text='Restaurar original',command=self.restore).pack(side='left')
        self.run_button=ttk.Button(bar,text='Simular',command=self.run);self.run_button.pack(side='right',padx=4)
        self.cancel_button=ttk.Button(bar,text='Cancelar',command=self.cancel,state='disabled');self.cancel_button.pack(side='right')
        self.notebook=ttk.Notebook(root);self.notebook.pack(fill='both',expand=True,padx=14,pady=4)
        self.tabs={name:ttk.Frame(self.notebook,padding=12) for name in ['Avión','Simulación','Condiciones iniciales','Control','Ruta','Turbulencia','Estados','Comparación','Vuelo y resultados']}
        for name,frame in self.tabs.items():self.notebook.add(frame,text=name)
        self.build_aircraft()
        for name,fields in FIELDS.items():self.build_form(name,fields)
        self.build_route();self.build_comparison();self.build_flight();self.build_states()
        foot=ttk.Frame(root,padding=(16,8));foot.pack(fill='x',side='bottom',before=self.notebook);ttk.Label(foot,textvariable=self.status,wraplength=1000).pack(side='left',fill='x',expand=True)
        self.progress=ttk.Progressbar(foot,mode='indeterminate',length=120);self.progress.pack(side='right')
        self.load_profile('pid');root.protocol('WM_DELETE_WINDOW',self.close);self.poll_id=root.after(120,self.poll)

    def embed(self,fig,parent,toolbar=True):
        canvas=FigureCanvasTkAgg(fig,master=parent);canvas.get_tk_widget().pack(fill='both',expand=True)
        if toolbar:
            nav=NavigationToolbar2Tk(canvas,parent,pack_toolbar=False);nav.pack(side='bottom',fill='x',before=canvas.get_tk_widget())
        canvas.draw_idle();return canvas

    def build_aircraft(self):
        frame=self.tabs['Avión'];left=ttk.Frame(frame);left.pack(side='left',fill='both',expand=True)
        fig=figure();aircraft_figure(fig);self.aircraft_canvas=self.embed(fig,left)
        right=ttk.Frame(frame,padding=(12,0));right.pack(side='right',fill='y',before=left)
        ttk.Label(right,text='Parámetros fijos del modelo',font=('Segoe UI',12,'bold')).pack(anchor='w',pady=(0,10))
        data=aircraft_data();labels=[('masa_kg','Masa [kg]'),('peso_N','Peso = masa × g [N]'),('gravedad_m_s2','Gravedad [m/s²]'),
          ('superficie_m2','Superficie alar [m²]'),('envergadura_m','Envergadura [m]'),('cuerda_m','Cuerda media [m]'),
          ('cg_fraccion','CG / cuerda media'),('cg_referencia_fraccion','CG referencia / cuerda'),
          ('Ix_kg_m2','Ix [kg·m²]'),('Iy_kg_m2','Iy [kg·m²]'),('Iz_kg_m2','Iz [kg·m²]'),('Ixz_kg_m2','Ixz [kg·m²]'),
          ('momento_motor_kg_m2_s','Momento angular motor [kg·m²/s]')]
        for key,label in labels:
            row=ttk.Frame(right);row.pack(fill='x',pady=3);ttk.Label(row,text=label,width=29).pack(side='left');ttk.Label(row,text=f'{data[key]:,.5f}'.rstrip('0').rstrip('.')).pack(side='right')
        ttk.Label(right,text='Longitud y altura reales: no disponibles.\nGeometría docente, no dimensiones certificadas.\nValores utilizados por la planta actual.\nConsulta solamente.',wraplength=310,foreground='#526173').pack(anchor='w',pady=16)

    def build_form(self,name,fields):
        frame=self.tabs[name]
        notes={'Simulación':'Duración múltiplo del paso. Límites actuales: VT 100–200 m/s, altitud 0–10 000 m, paso ≤0.02 s.',
          'Condiciones iniciales':'Perturbaciones respecto al trim. En PID se suman al estado inicial original, que no es trim.',
          'Control':'Ganancias predeterminadas intactas. Q/R son factores positivos sobre los pesos originales, según el escenario.',
          'Turbulencia':'Dryden simplificado. Original: ruido de referencia MATLAB; personalizado: generador local y sigma/escalas editables.'}
        ttk.Label(frame,text=notes[name],wraplength=1080).pack(anchor='w',pady=(0,12))
        if name=='Simulación':
            ttk.Label(frame,text='Escenario (editable en perfil genérico)').pack(anchor='w')
            self.scenario=tk.StringVar();from ..simulation import SCENARIOS
            self.scenario_widget=ttk.Combobox(frame,textvariable=self.scenario,values=(*SCENARIOS,'manual'),state='readonly',width=30);self.scenario_widget.pack(anchor='w',pady=(0,12));self.scenario_widget.bind('<<ComboboxSelected>>',lambda e:self.change_scenario())
        if name=='Control':
            area=ttk.Frame(frame);area.pack(fill='both',expand=True);scroll=tk.Canvas(area,highlightthickness=0);scroll.pack(side='left',fill='both',expand=True)
            scrollbar=ttk.Scrollbar(area,orient='vertical',command=scroll.yview);scrollbar.pack(side='right',fill='y');scroll.configure(yscrollcommand=scrollbar.set)
            grid=ttk.Frame(scroll);window=scroll.create_window((0,0),window=grid,anchor='nw');grid.bind('<Configure>',lambda e:scroll.configure(scrollregion=scroll.bbox('all')));scroll.bind('<Configure>',lambda e:scroll.itemconfigure(window,width=e.width))
        else:grid=ttk.Frame(frame);grid.pack(fill='x')
        for i,(key,label) in enumerate(fields):
            row,col=divmod(i,2);cell=ttk.Frame(grid,padding=(0,5,25,5));cell.grid(row=row,column=col,sticky='ew');grid.columnconfigure(col,weight=1)
            ttk.Label(cell,text=label).pack(side='left');v=tk.StringVar();entry=ttk.Entry(cell,textvariable=v,width=16);entry.pack(side='right');self.values[key]=v;self.entries[key]=entry
        if name=='Simulación':
            buttons=ttk.Frame(frame);buttons.pack(anchor='w',pady=16)
            ttk.Button(buttons,text='Guardar configuración…',command=self.export_config).pack(side='left',padx=(0,8));ttk.Button(buttons,text='Cargar configuración…',command=self.import_config).pack(side='left')

    def build_route(self):
        frame=self.tabs['Ruta'];ttk.Label(frame,text='Waypoints en Norte / Este / altitud positiva [m]. Selecciona un punto o pulsa sobre el plano para editarlo.').pack(anchor='w')
        columns=ttk.Frame(frame);columns.pack(fill='both',expand=True,pady=8);left=ttk.Frame(columns);left.pack(side='left',fill='both',expand=True)
        self.route_table=ttk.Treeview(left,columns=('n','e','h'),show='headings',height=7,selectmode='browse')
        for col,title in zip(('n','e','h'),('Norte [m]','Este [m]','Altitud [m]')):self.route_table.heading(col,text=title);self.route_table.column(col,width=120,anchor='e')
        self.route_table.pack(fill='x');self.route_table.bind('<<TreeviewSelect>>',self.select_waypoint)
        self.route_vars=[tk.StringVar(value=v) for v in ('0','0','3000')];edit=ttk.Frame(left);edit.pack(fill='x',pady=8)
        for title,v in zip(('Norte','Este','Altitud'),self.route_vars):
            cell=ttk.Frame(edit);cell.pack(side='left',padx=3);ttk.Label(cell,text=title).pack();ttk.Entry(cell,textvariable=v,width=12).pack()
        buttons=ttk.Frame(left);buttons.pack(fill='x')
        for label,command in [('Añadir',self.add_waypoint),('Actualizar',self.update_waypoint),('Eliminar',self.remove_waypoint),('↑',lambda:self.move_waypoint(-1)),('↓',lambda:self.move_waypoint(1))]:ttk.Button(buttons,text=label,command=command).pack(side='left',padx=2)
        for key,label in [('anticipacion_m','Anticipación [m]'),('radio_captura_m','Radio de captura [m]')]:
            row=ttk.Frame(left);row.pack(fill='x',pady=6);ttk.Label(row,text=label).pack(side='left');self.values[key]=tk.StringVar();entry=ttk.Entry(row,textvariable=self.values[key],width=15);entry.pack(side='right');self.entries[key]=entry
        self.custom_position=tk.BooleanVar(value=False);ttk.Checkbutton(left,text='Posición inicial distinta del primer waypoint',variable=self.custom_position).pack(anchor='w',pady=8)
        self.pos_vars=[tk.StringVar(value=v) for v in ('0','0','3000')];row=ttk.Frame(left);row.pack(fill='x')
        for label,v in zip(('N inicial','E inicial','h inicial'),self.pos_vars):
            cell=ttk.Frame(row);cell.pack(side='left',padx=4);ttk.Label(cell,text=label).pack();ttk.Entry(cell,textvariable=v,width=11).pack()
        right=ttk.Frame(columns);right.pack(side='right',fill='both',expand=True,padx=(15,0));self.route_fig=figure();self.route_canvas=self.embed(self.route_fig,right)
        self.route_canvas.mpl_connect('button_press_event',self.route_click)

    def build_comparison(self):
        frame=self.tabs['Comparación'];bar=ttk.Frame(frame);bar.pack(fill='x')
        ttk.Button(bar,text='Guardar B como A',command=self.save_a).pack(side='left');ttk.Button(bar,text='Cargar registro A…',command=lambda:self.load_record('A')).pack(side='left',padx=6);ttk.Button(bar,text='Cargar registro B…',command=lambda:self.load_record('B')).pack(side='left')
        self.variable=tk.StringVar(value='Alfa [°]');combo=ttk.Combobox(bar,textvariable=self.variable,values=list(VARIABLES),state='readonly',width=24);combo.pack(side='right');combo.bind('<<ComboboxSelected>>',lambda e:self.redraw_comparison())
        self.compare_info=tk.StringVar(value='A: sin registro · B: sin registro');ttk.Label(frame,textvariable=self.compare_info,wraplength=1080).pack(anchor='w',pady=8)
        self.compare_fig=figure();self.compare_canvas=self.embed(self.compare_fig,frame);self.metric_info=tk.StringVar();ttk.Label(frame,textvariable=self.metric_info,wraplength=1080).pack(fill='x',pady=8,side='bottom',before=self.compare_canvas.get_tk_widget())
        self.redraw_comparison()

    def build_flight(self):
        frame=self.tabs['Vuelo y resultados'];bar=ttk.Frame(frame);bar.pack(fill='x')
        self.record_choice=tk.StringVar();self.record_picker=ttk.Combobox(bar,textvariable=self.record_choice,state='readonly',width=32);self.record_picker.pack(side='left');self.record_picker.bind('<<ComboboxSelected>>',lambda e:self.select_record())
        ttk.Button(bar,text='Guardar ensayo…',command=self.export_record).pack(side='left',padx=8)
        self.camera=tk.StringVar(value='Perspectiva');camera=ttk.Combobox(bar,textvariable=self.camera,values=['Perspectiva','Superior','Lateral'],state='readonly',width=14);camera.pack(side='right');camera.bind('<<ComboboxSelected>>',lambda e:self.set_camera())
        self.flight_fig=figure();self.flight_canvas=self.embed(self.flight_fig,frame);self.flight=FlightView(self.flight_fig)
        bottom=ttk.Frame(frame);bottom.pack(side='bottom',fill='x',before=self.flight_canvas.get_tk_widget());bar=ttk.Frame(bottom);bar.pack(fill='x');self.play_button=ttk.Button(bar,text='Reproducir',command=self.toggle_play);self.play_button.pack(side='left')
        ttk.Label(bar,text='Velocidad ×').pack(side='left',padx=(12,3));self.speed=tk.StringVar(value='6');ttk.Combobox(bar,textvariable=self.speed,values=['0.5','1','2','6','12'],state='readonly',width=5).pack(side='left')
        self.time_scale=ttk.Scale(bar,variable=self.time_value,from_=0,to=1,command=self.scrub);self.time_scale.pack(side='left',fill='x',expand=True,padx=12)
        self.time_label=tk.StringVar(value='0.00 s');ttk.Label(bar,textvariable=self.time_label,width=12).pack(side='right')
        self.telemetry=tk.StringVar(value='Ejecuta un ensayo para explorar los resultados.');ttk.Label(bottom,textvariable=self.telemetry,wraplength=880).pack(fill='x',pady=8)

    def load_profile(self,profile):
        self.profile=profile;self.profile_name.set(PROFILES[profile][0]);self.apply_config(defaults(profile));self.status.set('Configuración original README restaurada' if self.original.get() else 'Perfil genérico · ensayo personalizado')
    def build_states(self):
        frame=self.tabs['Estados'];top=ttk.Frame(frame);top.pack(fill='x',pady=(0,5))
        self.states_picker=ttk.Combobox(top,textvariable=self.record_choice,state='readonly',width=32);self.states_picker.pack(side='left');self.states_picker.bind('<<ComboboxSelected>>',lambda e:self.select_record())
        ttk.Label(top,text='Estados del ensayo B · referencias punteadas · pulsa una gráfica para seleccionar tiempo').pack(side='left',padx=12)
        bottom=ttk.Frame(frame);bottom.pack(side='bottom',fill='x')
        self.states_play_button=ttk.Button(bottom,text='Reproducir',command=self.toggle_play);self.states_play_button.pack(side='left')
        ttk.Label(bottom,text='Velocidad ×').pack(side='left',padx=(12,3));ttk.Combobox(bottom,textvariable=self.speed,values=['0.5','1','2','6','12'],state='readonly',width=5).pack(side='left')
        self.states_scale=ttk.Scale(bottom,variable=self.time_value,from_=0,to=1,command=self.scrub);self.states_scale.pack(side='left',fill='x',expand=True,padx=12)
        ttk.Label(bottom,textvariable=self.time_label,width=12).pack(side='right')
        self.states_fig=figure();self.states_canvas=self.embed(self.states_fig,frame);self.states=StatesView(self.states_fig)
        self.states_canvas.mpl_connect('button_press_event',self.states_click)
    def states_click(self,event):
        if self.record_b is not None and event.inaxes in self.states.axes.values() and event.xdata is not None:
            if self.states_canvas.toolbar.mode:return
            self.pause();self.seek(event.xdata)
    def restore(self):self.load_profile(self.profile)
    def apply_config(self,cfg):
        self.original.set(cfg['original']);self.scenario.set(cfg['escenario'])
        for key,v in self.values.items():
            parts=key.split('.');value=cfg[parts[0]] if len(parts)==1 else cfg[parts[0]][parts[1]];v.set(str(value))
        for item in self.route_table.get_children():self.route_table.delete(item)
        for point in cfg['waypoints']:self.route_table.insert('',tk.END,values=point)
        self.custom_position.set(cfg['posicion_inicial'] is not None)
        for v,value in zip(self.pos_vars,cfg['posicion_inicial'] or [0,0,cfg['altitud']]):v.set(str(value))
        self.sync_fields();self.draw_route()
    def change_scenario(self):
        scenario=self.scenario.get();base=defaults('generico')['initial']
        if scenario in ('lateral_abierto','lateral_lqr'):base.update(beta_deg=2.,phi_deg=10.)
        elif scenario in ('longitudinal_abierto','longitudinal_lqr'):base['alpha_deg']=3.
        for k,v in base.items():self.values['initial.'+k].set(str(v))
        self.sync_fields()
    def sync_fields(self):
        original=self.original.get();s=self.scenario.get()
        self.scenario_widget.configure(state='readonly' if self.profile=='generico' and not original else 'disabled')
        available=applicable_fields(s)
        for key,entry in self.entries.items():
            editable=not original and key in available
            if key in ('duracion','paso'):editable=True
            entry.configure(state='normal' if editable else 'disabled')

    def configuration(self):
        cfg=defaults(self.profile);cfg['original']=bool(self.original.get());cfg['escenario']=self.scenario.get()
        for key,var in self.values.items():
            raw=var.get().strip()
            try:value=int(raw) if key=='semilla' else float(raw)
            except ValueError:raise ValueError('Valor inválido: '+key)
            parts=key.split('.')
            if len(parts)==1:cfg[key]=value
            else:cfg[parts[0]][parts[1]]=value
        cfg['waypoints']=[[float(v) for v in self.route_table.item(i,'values')] for i in self.route_table.get_children()]
        cfg['posicion_inicial']=[float(v.get()) for v in self.pos_vars] if self.custom_position.get() else None
        return cfg
    def run(self):
        try:
            cfg=validate(self.profile,self.configuration());self.worker.start(self.profile,cfg)
        except Exception as exc:self.show_error(exc);return
        self.progress.start(12);self.run_button.configure(state='disabled');self.cancel_button.configure(state='normal');self.status.set('Calculando el ensayo en Python… puedes cancelar. Los resultados anteriores se conservan.')
    def poll(self):
        if self.closed:return
        result=self.worker.poll()
        if result is not None:
            self.finish_busy()
            if result[0]=='ok':
                try:self.accept_records(result[1])
                except Exception as exc:self.show_error(exc)
            else:self.show_error(result[1])
        self.poll_id=self.root.after(120,self.poll)
    def finish_busy(self):self.progress.stop();self.run_button.configure(state='normal');self.cancel_button.configure(state='disabled')
    def cancel(self):self.worker.cancel();self.finish_busy();self.status.set('Cálculo cancelado. Registros anteriores conservados.')
    def show_error(self,exc):self.status.set('Error: '+str(exc));messagebox.showerror('No se completó el ensayo',str(exc),parent=self.root)
    def accept_records(self,records):
        if not records:raise ValueError('Sin registros para mostrar')
        for record in records:validate_record(record)
        old=(self.records,self.record_a,self.record_b)
        self.pause();self.records=tuple(records)
        labels=[f'{i+1} · {r["config"]["escenario"]}' for i,r in enumerate(records)];self.record_picker.configure(values=labels);self.states_picker.configure(values=labels);self.record_choice.set(labels[-1]);self.record_b=records[-1]
        if len(records)==2:self.record_a=deepcopy(records[0])
        try:self.refresh_record()
        except Exception:
            self.records,self.record_a,self.record_b=old
            if self.record_b is not None:self.refresh_record()
            else:self.flight.record=None;self.flight_fig.clear();self.flight_canvas.draw_idle();self.redraw_comparison()
            raise
        self.status.set('Ensayo calculado. Estados muestra las curvas; Vuelo y resultados reproduce el avión.');self.notebook.select(self.tabs['Estados'])
    def select_record(self):
        values=list(self.record_picker.cget('values'));self.record_b=self.records[values.index(self.record_choice.get())];self.pause();self.refresh_record()
    def refresh_record(self):
        self.flight.set_record(self.record_b);self.states.set_record(self.record_b)
        self.time_scale.configure(to=float(self.record_b['t'][-1]));self.states_scale.configure(to=float(self.record_b['t'][-1]));self.time_value.set(0);self.seek(0);self.redraw_comparison()
    def save_a(self):
        if self.record_b is None:self.status.set('Calcula o carga primero un ensayo B.');return
        self.record_a=deepcopy(self.record_b);self.redraw_comparison();self.status.set('Referencia A guardada en memoria; sus condiciones quedan congeladas.')
    def redraw_comparison(self):
        ax=plot_comparison(self.compare_fig,self.record_a,self.record_b,self.variable.get());self.compare_cursor=ax.axvline(self.time_value.get(),color='#64717f',linewidth=1);self.compare_canvas.draw_idle()
        def detail(r,label):
            if r is None:return label+': sin registro'
            c=r['config'];meta=r.get('laboratorio',{});return f'{label}: {c["escenario"]} · {c["VT"]:g} m/s · {c["altitud"]:g} m · {r["t"][-1]:g} s · '+('original README' if meta.get('original') else 'personalizado / registro cargado')
        self.compare_info.set(detail(self.record_a,'A')+'\n'+detail(self.record_b,'B'))
        metrics=[]
        for label,r in [('A',self.record_a),('B',self.record_b)]:
            if r is not None:
                m=r['metricas'];metrics.append(f'{label}: RMS h={m["rms_altitud_m"]:.3g} m · VT={m["rms_velocidad_m_s"]:.3g} m/s · rumbo={m["rms_rumbo_deg"]:.3g}°')
        self.metric_info.set('   |   '.join(metrics)+'\nRMS calculado frente a la referencia de cada ensayo; compara condiciones antes de interpretar diferencias.' if metrics else '')
    def seek(self,seconds):
        if self.record_b is None:return
        self.current_index=self.flight.cursor(float(seconds));r=self.record_b;k=self.current_index;x=r['X'][k];a=np.degrees(r['angulos_rad'][k]);u=r['U_real'][k]
        self.time_value.set(float(r['t'][k]))
        self.states.cursor(float(r['t'][k]));self.states_canvas.draw_idle()
        self.time_label.set(f'{r["t"][k]:.2f} s')
        if hasattr(self,'compare_cursor'):self.compare_cursor.set_xdata([r['t'][k],r['t'][k]]);self.compare_canvas.draw_idle()
        self.telemetry.set(f'VT {x[2]:.2f} m/s · h {-x[14]:.2f} m · α {np.degrees(x[3]):.2f}° · β {np.degrees(x[4]):.2f}° · φ/θ/ψ {a[0]:.2f}/{a[1]:.2f}/{a[2]:.2f}°\nElevador/Alerón/Timón {u[0]:.2f}/{u[1]:.2f}/{u[2]:.2f}° · throttle {u[3]:.3f} · Mach {r["Mach"][k]:.3f} · an {r["an_g"][k]:.2f} g')
        self.flight_canvas.draw_idle()
    def scrub(self,value):self.pause();self.seek(value)
    def pause(self):
        self.playing=False;self.play_button.configure(text='Reproducir')
        if hasattr(self,'states_play_button'):self.states_play_button.configure(text='Reproducir')
        if self.play_id is not None:self.root.after_cancel(self.play_id);self.play_id=None
    def toggle_play(self):
        if self.record_b is None:return
        if self.playing:self.pause();return
        if self.time_value.get()>=self.record_b['t'][-1]:self.time_value.set(0)
        self.playing=True;self.play_button.configure(text='Pausar');self.states_play_button.configure(text='Pausar');self.last_tick=time.monotonic();self.tick()
    def tick(self):
        if not self.playing:return
        now=time.monotonic();t=min(float(self.record_b['t'][-1]),self.time_value.get()+(now-self.last_tick)*float(self.speed.get()));self.last_tick=now;self.time_value.set(t);self.seek(t)
        if t>=self.record_b['t'][-1]:self.pause()
        else:self.play_id=self.root.after(50,self.tick)
    def set_camera(self):
        if self.record_b is None:return
        elev,azim={'Perspectiva':(25,35),'Superior':(90,-90),'Lateral':(0,0)}[self.camera.get()]
        for ax in (self.flight.global_ax,self.flight.local_ax):ax.view_init(elev,azim)
        self.flight_canvas.draw_idle()

    def select_waypoint(self,event=None):
        selected=self.route_table.selection()
        if selected:
            for var,value in zip(self.route_vars,self.route_table.item(selected[0],'values')):var.set(value)
    def route_values(self):
        point=[float(v.get()) for v in self.route_vars]
        if not np.isfinite(point).all():raise ValueError('Coordenadas deben ser finitas')
        return point
    def route_editable(self):
        if self.original.get() or self.scenario.get()!='waypoints':
            self.status.set('Selecciona Waypoints y desactiva configuración original para editar la ruta.');return False
        return True
    def add_waypoint(self):
        if not self.route_editable():return
        try:self.route_table.insert('',tk.END,values=self.route_values());self.draw_route()
        except Exception as exc:self.show_error(exc)
    def update_waypoint(self):
        if not self.route_editable():return
        selected=self.route_table.selection()
        if selected:
            try:self.route_table.item(selected[0],values=self.route_values());self.draw_route()
            except Exception as exc:self.show_error(exc)
    def remove_waypoint(self):
        if not self.route_editable():return
        for item in self.route_table.selection():self.route_table.delete(item)
        self.draw_route()
    def move_waypoint(self,delta):
        if not self.route_editable():return
        selected=self.route_table.selection()
        if selected:self.route_table.move(selected[0],'',max(0,self.route_table.index(selected[0])+delta));self.draw_route()
    def draw_route(self):
        self.route_fig.clear();ax=self.route_fig.add_subplot(111);points=np.array([[float(v) for v in self.route_table.item(i,'values')] for i in self.route_table.get_children()])
        if len(points):
            ax.plot(points[:,1],points[:,0],'-o',color='#1767a0')
            for i,p in enumerate(points):ax.annotate(str(i+1),(p[1],p[0]),xytext=(5,5),textcoords='offset points')
        ax.set(xlabel='Este [m]',ylabel='Norte [m]',title='Ruta configurada · vista superior');ax.grid(alpha=.25);ax.set_aspect('equal',adjustable='datalim');self.route_canvas.draw_idle()
    def route_click(self,event):
        if event.inaxes and event.xdata is not None and event.ydata is not None:
            self.route_vars[0].set(f'{event.ydata:.1f}');self.route_vars[1].set(f'{event.xdata:.1f}')
    def export_record(self):
        if self.record_b is None:self.status.set('No hay ensayo calculado para guardar.');return
        folder=filedialog.askdirectory(title='Carpeta donde crear un nuevo ensayo',parent=self.root)
        if not folder:return
        from ..io import save_record
        try:
            path=Path(folder)/f'ensayo_{datetime.now():%Y%m%d_%H%M%S_%f}';save_record(self.record_b,path);self.status.set('Ensayo guardado: '+str(path))
        except Exception as exc:self.show_error(exc)
    def load_record(self,slot):
        filename=filedialog.askopenfilename(title='Cargar registro '+slot,filetypes=[('Registro F-16','*.npz')],parent=self.root)
        if not filename:return
        from ..io import load_record
        try:
            r=validate_record(load_record(filename))
            if slot=='A':
                old=self.record_a;self.record_a=r
                try:self.redraw_comparison()
                except Exception:self.record_a=old;self.redraw_comparison();raise
            else:self.accept_records((r,))
        except Exception as exc:self.show_error(exc)
    def export_config(self):
        try:cfg=validate(self.profile,self.configuration())
        except Exception as exc:self.show_error(exc);return
        filename=filedialog.asksaveasfilename(title='Guardar nueva configuración',defaultextension='.json',filetypes=[('JSON','*.json')],parent=self.root)
        if filename:
            from ..io import write_json
            try:write_json(filename,dict(contrato=1,perfil=self.profile,opciones=cfg));self.status.set('Configuración guardada.')
            except Exception as exc:self.show_error(exc)
    def import_config(self):
        filename=filedialog.askopenfilename(title='Cargar configuración',filetypes=[('JSON','*.json')],parent=self.root)
        if filename:
            try:
                from .profiles import merge
                data=json.loads(Path(filename).read_text(encoding='utf-8'));profile=data['perfil']
                if data.get('contrato')!=1:raise ValueError('Versión de contrato desconocida')
                cfg=validate(profile,merge(defaults(profile),data['opciones']));self.load_profile(profile);self.apply_config(cfg);self.status.set('Configuración cargada; pulsa Simular para calcular.')
            except Exception as exc:self.show_error(exc)
    def close(self):
        self.closed=True;self.pause();self.worker.cancel()
        if self.poll_id is not None:self.root.after_cancel(self.poll_id)
        self.root.destroy()

def main():
    root=tk.Tk();style=ttk.Style(root)
    if 'vista' in style.theme_names():style.theme_use('vista')
    LaboratoryApp(root);root.mainloop()
