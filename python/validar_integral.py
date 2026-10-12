"""Contraste de los diez escenarios completos con registros MATLAB conservados."""
import argparse
from pathlib import Path
import numpy as np
from scipy.io import loadmat
from f16py.io import load_record,write_json
from f16py.validation import require_close

def main():
    p=argparse.ArgumentParser();p.add_argument('carpeta',type=Path)
    p.add_argument('--matlab',type=Path,default=Path(__file__).resolve().parent/'references'/'integral')
    p.add_argument('--salida',type=Path,required=True);a=p.parse_args();results=[]
    cases=['nivelado','lateral_abierto','longitudinal_abierto','lateral_lqr','viraje','ascenso','autopiloto','trayectoria','dryden_abierto','dryden_lqr']
    for name in cases:
        original='trayectoria_final' if name=='trayectoria' and (a.matlab/'trayectoria_final').is_dir() else name
        m=loadmat(a.matlab/original/'registro.mat',simplify_cells=True)['r'];r=load_record(a.carpeta/name/'registro.npz')
        require_close(name+' t',r['t'],np.asarray(m['t']).ravel(),1e-9)
        require_close(name+' X',r['X'],m['X'],1e-6,1e-9)
        require_close(name+' U',r['U_real'],m['U_real'],1e-6,1e-9)
        require_close(name+' referencias',r['referencia'],m['referencia'],1e-7,1e-9)
        results.append({'escenario':name,'max_estado_abs':float(np.max(abs(r['X']-m['X']))),
            'max_posicion_m':float(np.max(np.linalg.norm(r['X'][:,12:15]-m['X'][:,12:15],axis=1))),
            'max_mando_abs':float(np.max(abs(r['U_real']-m['U_real']))),'muestras':len(r['t'])})
    write_json(a.salida,{'estado':'PASS','escenarios':results});print('PARIDAD_INTEGRAL: PASS (10 escenarios)')
if __name__=='__main__':main()
