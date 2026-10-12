"""Contraste reproducible contra fixtures exportados de MATLAB R2024a."""
import argparse
from pathlib import Path
import numpy as np
from scipy.io import loadmat
from f16py.simulation import simulate
from f16py.control import trim,design
from f16py.dynamics import rhs,environment
from f16py import fits
from f16py.io import write_json,save_record
from f16py.visualization import plots,animate
from f16py.validation import require_close

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--salida',type=Path,default=Path('validacion_python'))
    ap.add_argument('--vuelos',nargs='+',choices=['waypoints','autopiloto','trayectoria'],default=['waypoints','autopiloto','trayectoria'])
    ap.add_argument('--video',action='store_true');args=ap.parse_args();out=args.salida
    if out.exists():raise FileExistsError(out)
    out.mkdir(parents=True);refs=Path(__file__).resolve().parent/'references';f=loadmat(refs/'matlab_reference.mat',simplify_cells=True)
    fits_error=[]
    for case in f['fit_cases']:
        fn=getattr(fits,case['name']);inputs=np.asarray(case['inputs']).reshape(17,-1)
        fits_error.append(float(np.max(abs(np.array([fn(*v) for v in inputs])-case['outputs']))))
    derivative_error=max(float(np.max(abs(rhs(0,c['x'],c['u'])-c['dx']))) for c in f['cases'])
    assert max(fits_error)<1e-8,'Ajustes no equivalentes a MATLAB'
    loads_error=max(float(np.max(abs(environment(c['x'],c['u'])[0]-c['loads']))) for c in f['cases'])
    x,u,info=trim();c=design(x,u,True,True)
    summary={'fits_max_abs':max(fits_error),'dx_max_abs':derivative_error,'loads_max_abs':loads_error,
        'trim_x_max_abs':float(max(abs(x-f['xt']))),'trim_u_max_abs':float(max(abs(u-f['ut']))),
        'A14_max_abs':float(np.max(abs(c['A14']-f['A14']))),'B14_max_abs':float(np.max(abs(c['B14']-f['B14']))),'vuelos':{}}
    assert derivative_error<2e-10 and loads_error<2e-9
    require_close('trim X',x,f['xt'],1e-8);require_close('trim U',u,f['ut'],1e-8)
    require_close('A14',c['A14'],f['A14'],2e-6);require_close('B14',c['B14'],f['B14'],2e-6)
    from f16py.control import jacobian
    radial=loadmat(refs/'jacobiano15.mat',simplify_cells=True)
    A15=jacobian(lambda z:rhs(0,z,radial['u']),radial['x']);B15=jacobian(lambda v:rhs(0,radial['x'],v),radial['u'])
    summary['A15_max_abs']=require_close('A15',A15,radial['A15'],2e-6)
    summary['B15_max_abs']=require_close('B15',B15,radial['B15'],2e-6)
    for name in args.vuelos:
        m=loadmat(refs/(name+'.mat'),simplify_cells=True)['r'];cfg=m['config']
        opts=dict(escenario=name,duracion=float(cfg['duracion']),paso=float(cfg['paso']),VT=float(cfg['VT']),
            altitud=float(cfg['altitud']),semilla=int(cfg['semilla']),tramo=float(cfg['tramo']))
        if name=='waypoints':opts['waypoints_ned']=m['navegacion']['waypoints_ned']
        if name=='trayectoria':
            nt=int(np.ceil(opts['duracion']/opts['tramo']))
            opts['targets']=np.array([m['objetivo'][int(round(j*opts['tramo']/opts['paso']))] for j in range(nt)])
        print('Comparando vuelo',name,flush=True);r=simulate(**opts);folder=save_record(r,out/name)
        n=min(len(r['t']),len(m['t']));err=r['X'][:n]-m['X'][:n];errU=r['U_real'][:n]-m['U_real'][:n]
        summary['vuelos'][name]={'samples_python':len(r['t']),'samples_matlab':len(m['t']),
            'max_state_abs_by_column':np.max(abs(err),axis=0),'rms_state_by_column':np.sqrt(np.mean(err**2,axis=0)),
            'max_control_abs_by_column':np.max(abs(errU),axis=0),'metrics_python':r['metricas'],'metrics_matlab':m['metricas'],
            'position_max_error_m':float(max(np.linalg.norm(err[:,12:15],axis=1))),
            'Klon_max_abs':float(np.max(abs(r['control']['Klon']-m['control']['Klon']))),
            'Klat_max_abs':float(np.max(abs(r['control']['Klat']-m['control']['Klat'])))}
        require_close('Klon',r['control']['Klon'],m['control']['Klon'],1e-4)
        require_close('Klat',r['control']['Klat'],m['control']['Klat'],1e-4)
        tol=np.array([1e-6,1e-6,1e-6]+[1e-7]*9+[.1]*3+[1e-6]*3)
        require_close('X',r['X'][:n],m['X'][:n],tol)
        require_close('U real',r['U_real'][:n],m['U_real'][:n],1e-6)
        require_close('Referencias',r['referencia'][:n],m['referencia'][:n],[1e-6,1e-8,1e-8])
        plots(r,folder)
        if args.video and name=='waypoints':animate(r,folder/'vuelo_3d.mp4',snapshot=folder/'animacion_final.png')
        print('Max diferencia posicion:',summary['vuelos'][name]['position_max_error_m'],'m',flush=True)
        if len(r['t'])!=len(m['t']) or summary['vuelos'][name]['position_max_error_m']>.1:
            write_json(out/'comparacion.json',summary);raise AssertionError('Replica fuera de tolerancia: revisar comparacion.json')
    write_json(out/'comparacion.json',summary);print('REPLICA MATLAB/PYTHON: PASS',flush=True)

if __name__=='__main__':main()
