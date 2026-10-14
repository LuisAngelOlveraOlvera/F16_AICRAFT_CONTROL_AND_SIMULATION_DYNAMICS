"""Figuras del motor visual Python; cada figura recibe registros calculados."""
import numpy as np
from matplotlib.figure import Figure
from mpl_toolkits.mplot3d.art3d import Poly3DCollection

VARIABLES={
 'Altitud [m]':lambda r:r['altitud_m'],
 'Velocidad [m/s]':lambda r:r['X'][:,2],
 'Alfa [°]':lambda r:np.degrees(r['X'][:,3]),
 'Beta [°]':lambda r:np.degrees(r['X'][:,4]),
 'Alabeo [°]':lambda r:np.degrees(r['angulos_rad'][:,0]),
 'Cabeceo [°]':lambda r:np.degrees(r['angulos_rad'][:,1]),
 'Rumbo [°]':lambda r:np.degrees(np.unwrap(r['angulos_rad'][:,2])),
 'p [°/s]':lambda r:np.degrees(r['X'][:,5]),
 'q [°/s]':lambda r:np.degrees(r['X'][:,6]),
 'r [°/s]':lambda r:np.degrees(r['X'][:,7]),
 'Elevador [°]':lambda r:r['U_real'][:,0],
 'Alerón [°]':lambda r:r['U_real'][:,1],
 'Timón [°]':lambda r:r['U_real'][:,2],
 'Throttle [0–1]':lambda r:r['U_real'][:,3],
 'Mach':lambda r:r['Mach'],
 'Empuje [N]':lambda r:r['empuje_N'],
 'Presión dinámica [Pa]':lambda r:r['qbar_Pa'],
 'Normal específica [g]':lambda r:r['an_g'],
 'Fuerza X [N]':lambda r:r['fuerzas_N'][:,0],
 'Fuerza Y [N]':lambda r:r['fuerzas_N'][:,1],
 'Fuerza Z [N]':lambda r:r['fuerzas_N'][:,2],
 'Momento L [N·m]':lambda r:r['momentos_Nm'][:,0],
 'Momento M [N·m]':lambda r:r['momentos_Nm'][:,1],
 'Momento N [N·m]':lambda r:r['momentos_Nm'][:,2],
 'Ráfaga u [m/s]':lambda r:r['rafaga_m_s'][:,0],
 'Ráfaga v [m/s]':lambda r:r['rafaga_m_s'][:,1],
 'Ráfaga w [m/s]':lambda r:r['rafaga_m_s'][:,2],
 'LEF [°]':lambda r:r['LEF_deg'],
}

def figure():return Figure(figsize=(8,5),dpi=100,layout='constrained')

def aircraft_figure(fig):
    from ..visualization import geometry
    from .experiments import aircraft_data
    fig.clear();ax=fig.add_subplot(111,projection='3d')
    ax.add_collection3d(Poly3DCollection(geometry(),facecolor='#708aa4',edgecolor='#364860',linewidth=.3))
    ax.set(xlim=(-9,9),ylim=(-6,6),zlim=(-4,4),xlabel='x cuerpo [m]',ylabel='y cuerpo [m]',zlabel='z cuerpo [m]')
    ax.set_box_aspect([18,12,8]);ax.view_init(28,38)
    b=aircraft_data()['envergadura_m'];ax.plot([-3.7,-3.7],[-b/2,b/2],[.7,.7],color='#c45c20')
    ax.text(-3.7,0,1.2,f'Envergadura del modelo: {b:.3f} m')
    ax.set_title('Geometría docente · ejes cuerpo x adelante, y derecha, z abajo')

def plot_comparison(fig,a,b,variable):
    fig.clear();ax=fig.add_subplot(111)
    for record,label,style,color in [(a,'A','--','#1767a0'),(b,'B','-','#bd531b')]:
        if record is None:continue
        cfg=record['config'];name=record.get('laboratorio',{}).get('perfil',cfg['escenario'])
        ax.plot(record['t'],VARIABLES[variable](record),style,color=color,label=f'{label} · {name}')
    if variable=='Alfa [°]' and b is not None and 'referencia_alfa_deg' in b:
        ax.plot(b['t'],b['referencia_alfa_deg'],':',color='#526173',label='Referencia B')
    if b is not None and variable in ('Altitud [m]','Velocidad [m/s]','Rumbo [°]'):
        col={'Altitud [m]':0,'Velocidad [m/s]':1,'Rumbo [°]':2}[variable];ref=b['referencia'][:,col]
        if col==2:ref=np.degrees(np.unwrap(ref))
        ax.plot(b['t'],ref,':',color='#526173',label='Referencia B')
    if b is not None and b['config']['escenario']=='comparacion':
        columns={'Alfa [°]':(0,180/np.pi),'Cabeceo [°]':(1,180/np.pi),'Velocidad [m/s]':(2,1),'q [°/s]':(3,180/np.pi)}
        if variable in columns:
            j,scale=columns[variable]
            ax.plot(b['t'],b['He'][:,j]*scale,':',color='#627180',label='Euler')
        linear={'Alfa [°]':(1,b['Xtrim'][3],180/np.pi),'Velocidad [m/s]':(0,b['Xtrim'][2],1),'q [°/s]':(2,0,180/np.pi)}
        if variable in linear:
            j,base,scale=linear[variable]
            for key,label,style,color in [('Xl','Lineal abierto','-.','#526173'),('Xp','Lineal + PID',':','#498166'),('Xk','Lineal + LQR','--','#80629a')]:
                ax.plot(b['t'],(b[key][:,j]+base)*scale,style,color=color,label=label)
        if variable=='Elevador [°]':
            ax.plot(b['t'],b['up']+b['Utrim'][0],':',label='Lineal + PID')
            ax.plot(b['t'],b['uk'][:,0]+b['Utrim'][0],'--',label='Lineal + LQR')
    ax.set(xlabel='Tiempo [s]',ylabel=variable,title='Comparación sobre el mismo eje de tiempo');ax.grid(alpha=.25)
    if a is not None or b is not None:ax.legend(loc='best')
    return ax

class StatesView:
    """Nueve paneles de estados físicos, sin modificar el registro."""
    def __init__(self,fig):self.fig=fig;self.record=None;self.axes={};self.cursors=[]
    def set_record(self,r):
        self.record=r;self.fig.clear();self.axes={};self.cursors=[]
        panels=[('altitud','Altitud','h [m]'),('velocidad','Velocidad','VT [m/s]'),
          ('aero','Ángulos aerodinámicos','[°]'),('actitud','Actitud','[°]'),
          ('rumbo','Rumbo','ψ [°]'),('tasas','Tasas de giro','[°/s]'),
          ('motor','Potencia del motor','P3 [%]'),('lef','Filtro y deflexión LEF','[°]'),
          ('posicion','Posición horizontal','[m]')]
        ix=np.unique(np.linspace(0,len(r['t'])-1,min(2500,len(r['t']))).astype(int));t=r['t'][ix]
        series={
          'altitud':[(r['altitud_m'],'Real')],
          'velocidad':[(r['X'][:,2],'Real')],
          'aero':[(np.degrees(r['X'][:,3]),'α'),(np.degrees(r['X'][:,4]),'β')],
          'actitud':[(np.degrees(r['angulos_rad'][:,0]),'φ'),(np.degrees(r['angulos_rad'][:,1]),'θ')],
          'rumbo':[(np.degrees(np.unwrap(r['angulos_rad'][:,2])),'Real')],
          'tasas':[(np.degrees(r['X'][:,5]),'p'),(np.degrees(r['X'][:,6]),'q'),(np.degrees(r['X'][:,7]),'r')],
          'motor':[(r['X'][:,0],'P3')],
          'lef':[(r['X'][:,1],'α filtro'),(r['LEF_deg'],'LEF')],
          'posicion':[(r['X'][:,12],'Norte'),(r['X'][:,13],'Este')]}
        refs={'altitud':r['referencia'][:,0],'velocidad':r['referencia'][:,1],
              'rumbo':np.degrees(np.unwrap(r['referencia'][:,2]))}
        if 'referencia_alfa_deg' in r:refs['aero']=r['referencia_alfa_deg']
        first=None
        for i,(key,title,unit) in enumerate(panels):
            ax=self.fig.add_subplot(3,3,i+1,sharex=first);first=ax if first is None else first;self.axes[key]=ax
            for j,(values,label) in enumerate(series[key]):
                ax.plot(t,values[ix],['-','--','-.'][j],linewidth=1.2,label=label)
            if key in refs:ax.plot(t,refs[key][ix],':',color='#64717f',linewidth=1.2,label='Referencia')
            ax.set(title=title,ylabel=unit);ax.grid(alpha=.2);ax.tick_params(labelsize=8)
            ax.ticklabel_format(axis='y',useOffset=False)
            ax.set_title(title,fontsize=10);ax.yaxis.label.set_size(9)
            if i>=6:ax.set_xlabel('Tiempo [s]',fontsize=9)
            else:ax.tick_params(labelbottom=False)
            if len(series[key])>1 or key in refs:ax.legend(fontsize=7,ncol=min(3,len(series[key])+int(key in refs)),loc='best')
            self.cursors.append(ax.axvline(r['t'][0],color='#526173',linewidth=.9))
        self.cursor(r['t'][0])
    def cursor(self,seconds):
        if self.record is None:return 0
        t=self.record['t'];k=min(len(t)-1,max(0,int(np.searchsorted(t,seconds,side='right')-1)))
        for line in self.cursors:line.set_xdata([t[k],t[k]])
        return k

class FlightView:
    def __init__(self,fig):self.fig=fig;self.record=None
    def set_record(self,record):
        from ..visualization import geometry
        self.record=record;self.fig.clear();self.global_ax=self.fig.add_subplot(121,projection='3d');self.local_ax=self.fig.add_subplot(122,projection='3d')
        r=record;self.xyz=np.c_[r['X'][:,13],r['X'][:,12],r['altitud_m']]/1000
        ix=np.unique(np.linspace(0,len(self.xyz)-1,min(2500,len(self.xyz))).astype(int))
        ax=self.global_ax;ax.plot(*self.xyz[ix].T,color='#8a9cb0',label='Vuelo')
        if 'ruta_nominal_ned' in r:
            route=r['ruta_nominal_ned'][:,[1,0,2]]/1000;route[:,2]*=-1;ax.plot(*route[ix].T,'--',color='#64717f',label='Ruta')
        if 'navegacion' in r:
            wp=r['navegacion']['waypoints_ned'][:,[1,0,2]].copy()/1000;wp[:,2]*=-1;ax.scatter(*wp.T,marker='s',color='#c67c21')
        span=np.maximum(np.ptp(self.xyz,axis=0),[.2,.2,.1]);mid=(self.xyz.max(0)+self.xyz.min(0))/2
        ax.set(xlim=mid[0]+np.array([-.6,.6])*span[0],ylim=mid[1]+np.array([-.6,.6])*span[1],zlim=mid[2]+np.array([-.6,.6])*span[2],xlabel='Este [km]',ylabel='Norte [km]',zlabel='Altitud [km]',title='Trayectoria calculada')
        ax.set_box_aspect(span);ax.legend();ax.view_init(25,35)
        self.dot,=ax.plot([],[],[],'o',color='#bd531b');self.trail,=ax.plot([],[],[],color='#1767a0')
        local=self.local_ax;local.set(xlim=(-9,9),ylim=(-9,9),zlim=(-7,7),xlabel='Este [m]',ylabel='Norte [m]',zlabel='Arriba [m]',title='Actitud · geometría docente')
        local.set_box_aspect([18,18,14]);local.view_init(24,38);self.base=geometry()
        self.model=Poly3DCollection(self.base,facecolor='#708aa4',edgecolor='#364860',linewidth=.15);local.add_collection3d(self.model)
        self.cursor(0)
    def cursor(self,time):
        from ..dynamics import pose_enu
        if self.record is None:return 0
        r=self.record;k=min(len(r['t'])-1,max(0,int(np.searchsorted(r['t'],time,side='right')-1)))
        self.dot.set_data_3d(*self.xyz[k:k+1].T);ix=np.unique(np.linspace(0,k,min(1500,k+1)).astype(int));self.trail.set_data_3d(*self.xyz[ix].T)
        T=pose_enu(r['X'][k,8:12],r['X'][k,12:15]);self.model.set_verts([p@T[:3,:3].T for p in self.base]);return k
