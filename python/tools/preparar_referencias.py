"""Genera derivados compactos, sin rutas personales; nunca sobrescribe fuentes."""
import argparse,hashlib,json
from pathlib import Path
import numpy as np
from scipy.io import loadmat,savemat

def clean(value):
    if isinstance(value,dict):return {k:clean(v) for k,v in value.items() if not k.startswith('__')}
    if isinstance(value,str) and ('C:\\Users\\' in value or 'C:/Users/' in value):return 'Ruta local omitida en paquete publicable'
    if isinstance(value,list):return [clean(v) for v in value]
    if isinstance(value,np.ndarray) and value.dtype==object:
        out=np.empty(value.shape,dtype=object)
        for i in np.ndindex(value.shape):out[i]=clean(value[i])
        return out
    if value is None:return np.array([])
    return value

def compact(source):
    data=clean(loadmat(source,simplify_cells=True))
    if 'r' in data:
        r=data['r'];keys=['config','t','X','U_real','referencia','objetivo','control','metricas']
        data['r']={k:r[k] for k in keys if k in r}
    if source.name=='paridad.mat':
        data['lat']={k:data['lat'][k] for k in ['manual_A','condition_component','remaining_model_component','control_derivatives']}
        data['estandar']={'matrices':data['estandar']['matrices']}
    return data

def main():
    p=argparse.ArgumentParser();p.add_argument('--python',type=Path,required=True);p.add_argument('--matlab',type=Path,required=True);p.add_argument('--salida',type=Path,required=True);a=p.parse_args()
    out=a.salida;out.mkdir(parents=True,exist_ok=False);manifest=[]
    def emit(src,dst):
        dst.parent.mkdir(parents=True,exist_ok=True);savemat(dst,compact(src),do_compression=True,oned_as='column')
        manifest.append({'archivo':str(dst.relative_to(out)).replace('\\','/'),'sha256':hashlib.sha256(dst.read_bytes()).hexdigest(),'sha256_fuente':hashlib.sha256(src.read_bytes()).hexdigest(),'origen':'MATLAB generado localmente; metadatos depurados, valores numericos conservados'})
    for src in sorted((a.python/'references').glob('*.mat')):emit(src,out/src.name)
    cases=['nivelado','lateral_abierto','longitudinal_abierto','lateral_lqr','viraje','ascenso','autopiloto','trayectoria','dryden_abierto','dryden_lqr']
    base=a.matlab/'ejecucion_guia_f16_20261010'/'resultados_completos'
    for name in cases:emit(base/('trayectoria_final' if name=='trayectoria' else name)/'registro.mat',out/'integral'/name/'registro.mat')
    (out/'manifest_referencias.json').write_text(json.dumps(manifest,indent=2,ensure_ascii=False),encoding='utf-8')
    (out/'fuentes_ajustes.json').write_bytes((a.python/'references'/'fuentes_ajustes.json').read_bytes())
    print('REFERENCIAS: generadas; fuentes conservadas')
if __name__=='__main__':main()
