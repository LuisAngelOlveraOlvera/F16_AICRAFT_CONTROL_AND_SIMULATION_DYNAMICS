"""Mismos puntos de entrada y orden docente que el proyecto MATLAB."""
import argparse,unittest,tempfile,sys,hashlib
from datetime import datetime
from pathlib import Path
import numpy as np
from scipy.io import loadmat
from .io import save_record,write_json,load_record
from .simulation import simulate
from .control import trim,design,compare_lewis
from .dynamics import rhs,rhs_euler,rhs_body,rkf_step,PAR,quaternion,quat_to_euler
from .audit import lateral_audit,standard_audit,sensitivity_audit,source_audit,fd
from .demonstrations import pid_demo,longitudinal_demo,comparison_demo,comparison_plots
from .visualization import plots,animate

ROOT=Path(__file__).resolve().parents[1]
ORDER=('run_tests','verificar_simetria','validar_A','prueba_trim_refinado','prueba_regresion_lewis',
 'prueba_6dof_estandarizado','prueba_simulador_academico','prueba_calc_ABCD','validar_lewis',
 'auditar_lateral_lewis','comparar_f16_estandarizado','sensibilidad_jacobiano_6dof',
 'validar_fuentes_aerodinamicas','pruebarkf','prueba_lqr','prueba_lqr_lat','prueba_comparacion',
 'prueba_autopiloto','prueba_dryden','prueba_trayectoria','prueba_ruta_salida_f16',
 'prueba_exportacion_json_f16','prueba_bordes_guia_f16','prueba_visualizacion_f16',
 'prueba_waypoints_f16','prueba_paso_waypoints_f16','ejecutar_guia_f16','ejecutar_waypoints_f16')

def fresh(name,path=None):
    p=Path(path) if path else ROOT/'resultados'/f'{name}_{datetime.now():%Y%m%d_%H%M%S_%f}'
    if p.exists():raise FileExistsError(f'Salida existente: {p}')
    return p

def verify(condition,message):
    if not bool(condition):raise AssertionError(message)

def run_tests():
    x,u,info=trim();e=quat_to_euler(x)
    verify(info['converge'] and abs(info['alfa_deg']-2.884)<.05 and abs(u[0]+1.885)<.05,'T1 trim');print('T1 PASS')
    x2,_,i2=trim(170,3000,0,0);verify(np.max(abs(x2-x))<1e-8,'T2 trim general');print('T2 PASS')
    _,_,i3=trim(170,3000,0,3);verify(abs(i3['fi_deg']-np.degrees(np.arctan2(np.radians(3)*170,PAR[1])))<1,'T3 viraje');print('T3 PASS')
    verify(np.max(abs(rhs(0,x,u)[[4,5,7]]))<1e-10,'T4 simetria');print('T4 PASS')
    body_validation();print('T5 PASS')
    q=x.copy();q[3]+=np.radians(3);e[3]+=np.radians(3)
    for k in range(1000):q=rkf_step(rhs,k*.002,.002,q,u);e=rkf_step(rhs_euler,k*.002,.002,e,u)
    verify(abs(q[3]-e[3])<1e-10 and abs(q[2]-e[2])<1e-8,'T6 Euler/cuat');print('T6 PASS')
    z=design(x,u)['polos_lon'];sp=z[(abs(z.imag)>1)&(z.real<-.5)];ph=z[(abs(z.imag)<.2)&(abs(z.imag)>.01)]
    verify(len(sp)>0 and abs(sp[0].real+1.22)<.3 and len(ph)>0 and abs(abs(ph[0].imag)-.076)<.02,'T7 modos locales');print('T7 PASS')
    z=x.copy()
    for k in range(5000):z=rkf_step(rhs,k*.002,.002,z,u)
    verify(abs(z[2]-170)<.5 and abs(np.degrees(z[3]-x[3]))<.1 and abs(np.degrees(z[5]))<.05,'T8 sostenimiento');print('T8 PASS')
    from .dynamics import atmosphere,thrust
    verify(abs(atmosphere(3000)[2]-.9093)<.005 and thrust(50,.5,0)>thrust(50,.5,-10000)>0,'T9 motor');print('T9 PASS')
    return {'pruebas':9,'estado':'PASS'}

def body_validation():
    b=np.r_[150,8,20,.02,.01,-.015,quaternion(.1,.05,.2),0,0,-3000.];u=np.array([0,0,0,.7])
    a=fd(lambda z:rhs_body(0,z,u,0),b,1e-5,4);a2=fd(lambda z:rhs_body(0,z,u,0),b,1e-6,2)
    verify(np.max(abs(a-a2))<1e-4*max(1,np.max(abs(a2))),'A13 cuerpo FD orden2/4')
    return dict(A13=a,referencia_fd2=a2,error_absoluto=abs(a-a2),etiqueta='Cuerpo auxiliar; validacion FD2/FD4, no derivadas legacy')

def regression_lewis():
    a=lateral_audit();verify(a['verified_reference'][3,3]==-.49849,'Referencia A44')
    verify(a['extraction']['good_vs_euler']<1e-7,'ZYX/extraccion')
    verify(a['manual_vs_fd_max']<1e-7,'Inercia/momentos')
    return {'estado':'PASS','nfail':0}

def standard_check():
    r=standard_audit();v=r['verificacion']
    for key,tol in [('max_identidad_no_lineal',1e-7),('max_newton_euler',1e-8),('covarianza_A_quat',1e-6),
        ('covarianza_A_cuerpo',1e-6),('covarianza_B_quat',1e-6),('covarianza_B_cuerpo',1e-6),
        ('integracion_quat_euler',1e-6),('integracion_cuerpo_euler',1e-6),('error_actuadores',1e-7)]:verify(v[key]<tol,key)
    verify(r['propio_trim']['valido'] and not r['punto_lewis_en_modelo_local']['valido'],'Equilibrio')
    verify(r['polos_espiral'].real>0 and r['altitud_frontera']['no_diferenciable'],'Espiral/frontera')
    return r

def tests_selected(names):
    sys.path.insert(0,str(ROOT/'tests'))
    try:
        suite=unittest.defaultTestLoader.loadTestsFromNames(names)
        result=unittest.TextTestRunner(verbosity=2).run(suite)
        if not result.wasSuccessful():raise AssertionError('Pruebas fallaron')
        return {'estado':'PASS','pruebas':result.testsRun}
    finally:sys.path.pop(0)

TESTS={
 'prueba_simulador_academico':['test_replica.ReplicaTests','test_features.Features.test_once_escenarios_y_18_actuadores','test_features.Features.test_limits_y_config_invalidas'],
 'prueba_exportacion_json_f16':['test_features.Features.test_npz_roundtrip_y_no_sobrescritura'],
 'prueba_bordes_guia_f16':['test_features.Features.test_tramos_decimales_y_validacion_estricta','test_features.Features.test_rng_local_y_rafaga_explicita'],
 'prueba_visualizacion_f16':['test_features.Features.test_animacion_y_graficas'],
 'prueba_waypoints_f16':['test_replica.ReplicaTests.test_pose_ejes','test_replica.ReplicaTests.test_captura_lateral'],
 'prueba_paso_waypoints_f16':['test_features.Features.test_paso_y_jacobianos']}

def trajectory(duracion=180,paso=.002):
    # La demostracion original: seis consignas cada 30s, semilla MATLAB 11.
    ref=loadmat(ROOT/'references'/'trayectoria.mat',simplify_cells=True)['r']
    nt=int(np.ceil(duracion/30));indices=np.arange(6)*15000
    targets=np.asarray(ref['objetivo'])[indices]
    if nt>6:raise ValueError('Demostracion original limitada a 180 s')
    return simulate(escenario='trayectoria',duracion=duracion,paso=paso,tramo=30,semilla=11,targets=targets[:nt])

def export_flight(r,out,show=False,video=False):
    save_record(r,out);plots(r,out)
    if r['config']['escenario']=='comparacion':comparison_plots(r,out)
    if video:animate(r,Path(out)/'vuelo_3d.mp4',show=show,snapshot=Path(out)/'animacion_final.png')
    elif show:
        plots(r)
        if r['config']['escenario']=='comparacion':comparison_plots(r)
        import matplotlib.pyplot as plt
        plt.show()
    return r

def dryden_demo(out,show=False,duracion=30,paso=.002):
    from .demonstrations import dryden_pair
    a,b=dryden_pair(duracion,paso);out.mkdir(parents=True,exist_ok=False)
    export_flight(a,out/'sin_control');export_flight(b,out/'con_lqr')
    import matplotlib.pyplot as plt
    fig,axes=plt.subplots(2,2,figsize=(11,7),layout='constrained')
    for ax,col,label in zip(axes.flat,[3,4,-1,0],['alpha [deg]','beta [deg]','phi [deg]','Rafaga vertical [m/s]']):
        for r,name in [(a,'Sin control'),(b,'LQR')]:
            y=r['rafaga_m_s'][:,2] if col==0 else (np.degrees(r['angulos_rad'][:,0]) if col==-1 else np.degrees(r['X'][:,col]))
            ax.plot(r['t'],y,label=name)
        ax.set(xlabel='t [s]',ylabel=label);ax.grid();ax.legend()
    fig.savefig(out/'dryden_comparacion.png',dpi=140)
    if show:plt.show()
    else:plt.close(fig)
    return {'estado':'PASS','casos':['sin_control','con_lqr']}

def integrated(out,video=True,validate=True,legacy=True):
    out.mkdir(parents=True,exist_ok=False)
    sources={str(p.relative_to(ROOT)):hashlib.sha256(p.read_bytes()).hexdigest() for p in ROOT.rglob('*.py') if '__pycache__' not in str(p)}
    write_json(out/'fuentes_codigo.json',sources)
    if validate:
        run_tests();regression_lewis();standard_check();tests_selected(TESTS['prueba_simulador_academico'])
    if legacy:
        run_step('prueba_lqr_lat',out/'original_prueba_lqr_lat')
        run_step('prueba_autopiloto',out/'original_prueba_autopiloto')
        dryden_demo(out/'original_prueba_dryden')
        run_step('prueba_trayectoria',out/'original_prueba_trayectoria')
    durations=[20,30,20,15,60,20,40,180,30,30];scenarios=['nivelado','lateral_abierto','longitudinal_abierto','lateral_lqr','viraje','ascenso','autopiloto','trayectoria','dryden_abierto','dryden_lqr'];summaries=[]
    for name,duration in zip(scenarios,durations):
        print('Integrando',name,flush=True)
        noise=loadmat(ROOT/'references'/'dryden_original.mat',simplify_cells=True)['d']['W'].T if name.startswith('dryden') else None
        r=trajectory() if name=='trayectoria' else simulate(escenario=name,duracion=duration,semilla=7 if name.startswith('dryden') else 11,noise_series=noise)
        export_flight(r,out/name,video=video and name in ('autopiloto','trayectoria'))
        summaries.append(dict(escenario=name,duracion_s=r['t'][-1],metricas=r['metricas']))
    write_json(out/'resumen.json',summaries);return summaries

def run_step(name,out=None,show=False,video=False,duracion=None,validar=True,legado=True):
    if name not in ORDER:raise ValueError('Paso desconocido: '+name)
    if name=='run_tests':return run_tests()
    if name=='prueba_waypoints_f16':return waypoint_check()
    if name=='prueba_paso_waypoints_f16':return waypoint_step_check()
    if name=='prueba_bordes_guia_f16':return edge_check()
    if name=='prueba_exportacion_json_f16':return json_check()
    if name in TESTS:return tests_selected(TESTS[name])
    if name=='prueba_ruta_salida_f16':
        old=Path.cwd()
        import os
        with tempfile.TemporaryDirectory() as d:
            try:
                os.chdir(d);p=Path('salida').resolve();p.mkdir();write_json(p/'prueba.json',{'valor':1});verify((p/'prueba.json').is_file(),'Ruta salida')
            finally:os.chdir(old)
        return {'estado':'PASS'}
    if name=='verificar_simetria':
        x,u,_=trim();e=quat_to_euler(x)
        from .audit import to_body
        b=to_body(e)
        verify(np.max(abs(rhs(0,x,u)[[4,5,7]]))<1e-10,'Simetria cuat')
        verify(np.max(abs(rhs_euler(0,e,u)[[4,5,7]]))<1e-10,'Simetria Euler')
        verify(np.max(abs(rhs_body(0,b[:13],u,x[1])[[1,3,5]]))<1e-10,'Simetria cuerpo')
        return {'estado':'PASS'}
    if name=='prueba_trim_refinado':
        _,_,i=trim(170,3000,0,3);verify(i['residuo']<1e-6,'Trim viraje');return i
    if name=='prueba_regresion_lewis':return regression_lewis()
    if name=='prueba_6dof_estandarizado':return standard_check()
    if name=='ejecutar_guia_f16':return integrated(fresh(name,out),video,validar,legado)
    p=fresh(name,out)
    demos={'pruebarkf':(pid_demo,15),'prueba_lqr':(longitudinal_demo,20),'prueba_comparacion':(comparison_demo,15)}
    scenarios={'prueba_lqr_lat':('lateral_lqr',15),'prueba_autopiloto':('autopiloto',40),'ejecutar_waypoints_f16':('waypoints',180)}
    if name in demos:
        fun,d=demos[name];return export_flight(fun(d if duracion is None else duracion),p,show,video)
    if name in scenarios:
        scenario,d=scenarios[name];return export_flight(simulate(escenario=scenario,duracion=d if duracion is None else duracion),p,show,video)
    if name=='prueba_trayectoria':return export_flight(trajectory(180 if duracion is None else duracion),p,show,video)
    if name=='prueba_dryden':return dryden_demo(p,show,30 if duracion is None else duracion)
    if name=='validar_A':result=body_validation()
    elif name=='prueba_calc_ABCD':
        b=np.r_[1,0,0,0,0,0,quaternion(0,0,0),0,0,0.];u=np.array([0,0,0,.7])
        result={'A13':fd(lambda z:rhs_body(0,z,u,0),b),'etiqueta':'Punto original u=1 m/s: snapshot, no trim ni modos de vuelo'}
    elif name=='validar_lewis':result=compare_lewis()
    elif name=='auditar_lateral_lewis':result=lateral_audit()
    elif name=='comparar_f16_estandarizado':result=standard_audit()
    elif name=='sensibilidad_jacobiano_6dof':result=sensitivity_audit()
    elif name=='validar_fuentes_aerodinamicas':result=source_audit()
    else:raise ValueError(name)
    p.mkdir(parents=True);write_json(p/'evidencia.json',result);print('Evidencia:',p)
    return result

def waypoint_check():
    from .guidance import guide
    w=np.array([[0,0,3000],[8000,0,3100],[16000,3000,3200.]])
    u,g=guide([1000,200,-3000],w,0,170);verify(-np.pi/4<u[2]<0 and 3000<u[0]<3100 and u[1]==170,'Guia Norte')
    u,g=guide([0,1000,-3000],np.array([[0,0,3000],[0,8000,3000]]),0,170)
    verify(abs(u[2]-np.pi/2)<1e-12 and g['error_transversal_m']<1e-10,'Guia Este')
    _,g=guide([16000,3000,-3200],w,1,170);verify(g['finalizado'],'Captura final')
    r=simulate(escenario='waypoints',duracion=40,paso=.004,waypoints_ned=[[0,0,-3000],[12000,0,-3000]],posicion_inicial_ned=[0,200,-3000])
    verify(r['X'].shape[1]==18 and np.isfinite(r['X']).all() and abs(r['X'][-1,13])<50,'Captura lateral18')
    verify(r['navegacion']['error_transversal_m'][-1]<50 and max(abs(r['norma_cuaternion']-1))<1e-8,'Error espacial/norma')
    verify(max(abs(np.diff(r['referencia'][:,2])/.004))<=np.radians(3)+1e-8 and max(abs(np.diff(r['referencia'][:,0])/.004))<=10+1e-7,'Limites referencia')
    return {'estado':'PASS'}

def waypoint_step_check():
    opts=dict(escenario='waypoints',duracion=20,waypoints_ned=[[0,0,-3000],[12000,0,-3000]],posicion_inicial_ned=[0,200,-3000])
    a=simulate(paso=.004,**opts);b=simulate(paso=.002,**opts);delta=np.linalg.norm(a['X'][-1,12:15]-b['X'][-1,12:15])
    verify(delta<.5 and max(abs(a['X'][-1,2:8]-b['X'][-1,2:8]))<.01,'Sensibilidad guiado discreto')
    c=simulate(escenario='waypoints',duracion=20,paso=.004,waypoints_ned=[[0,0,-3000],[2000,0,-3000]])
    verify(c['metricas']['ruta_completada'] and c['t'][-1]<20 and 249<c['metricas']['distancia_final_m']<=250,'Llegada recta')
    return {'estado':'PASS','diferencia_posicion_m':delta,'llegada_s':float(c['t'][-1])}

def json_check():
    import json
    with tempfile.TemporaryDirectory() as d:
        p=Path(d)/'datos.json';data={'texto':'versión','valor':1.25};write_json(p,data);before=p.read_bytes()
        verify(json.loads(before.decode('utf-8'))==data,'JSON UTF8')
        try:write_json(p,{'valor':0})
        except FileExistsError:pass
        else:raise AssertionError('Sobrescritura permitida')
        verify(p.read_bytes()==before,'Preservacion JSON')
    return {'estado':'PASS'}

def edge_check():
    ref=loadmat(ROOT/'references'/'trayectoria.mat',simplify_cells=True)['r']['objetivo'][np.arange(6)*15000]
    r=simulate(escenario='trayectoria',duracion=.06,tramo=.01,targets=ref)
    verify(np.max(abs(r['objetivo'][np.arange(6)*5]-ref))<1e-10,'Tramos/consignas MATLAB')
    verify(np.max(abs(r['objetivo'][-1]-r['objetivo'][-2]))<1e-12,'Ultimo tramo')
    with tempfile.TemporaryDirectory() as d:
        r=simulate(escenario='nivelado',duracion=.02);a=animate(r,Path(d)/'lento.gif',fps=20,speed=.01)
        from PIL import Image
        with Image.open(Path(d)/'lento.gif') as im:
            duration=0
            for j in range(im.n_frames):im.seek(j);duration+=im.info.get('duration',0)/1000
            verify(2<=duration<=2.1,'Velocidad de video lento')
    return {'estado':'PASS'}

def main(default=None):
    parser=argparse.ArgumentParser(description='Pasos equivalentes al repositorio MATLAB')
    if default is None:parser.add_argument('paso',nargs='?',choices=ORDER)
    parser.add_argument('--listar',action='store_true');parser.add_argument('--salida',type=Path)
    parser.add_argument('--mostrar',action='store_true');parser.add_argument('--sin-video',action='store_true')
    parser.add_argument('--duracion',type=float);parser.add_argument('--sin-validar',action='store_true');parser.add_argument('--sin-legado',action='store_true')
    args=parser.parse_args()
    if args.listar:
        for k,name in enumerate(ORDER,1):print(f'{k:02d}. {name}')
        return
    name=default or args.paso
    if name is None:parser.error('Indica el paso o --listar')
    r=run_step(name,args.salida,args.mostrar,not args.sin_video,args.duracion,not args.sin_validar,not args.sin_legado)
    print(name+': COMPLETADO',flush=True)
    return r
