"""Registros sin pickle, sin sobreescritura y sin dependencia de MATLAB."""
import json
from pathlib import Path
import numpy as np

def jsonable(value):
    if isinstance(value,np.ndarray):return jsonable(value.tolist())
    if isinstance(value,np.generic):return jsonable(value.item())
    if isinstance(value,complex):return {'real':value.real,'imag':value.imag}
    if isinstance(value,float) and not np.isfinite(value):return None
    if isinstance(value,dict):return {k:jsonable(v) for k,v in value.items()}
    if isinstance(value,(list,tuple)):return [jsonable(v) for v in value]
    return value

def write_json(path,value):
    with Path(path).open('x',encoding='utf-8') as f:json.dump(jsonable(value),f,ensure_ascii=False,indent=2,allow_nan=False)

def save_record(r,folder):
    folder=Path(folder);folder.mkdir(parents=True,exist_ok=False);arrays={}
    def pack(value,key):
        if isinstance(value,np.ndarray):arrays[key]=value;return {'__array__':key}
        if isinstance(value,dict):return {k:pack(v,key+'__'+k) for k,v in value.items()}
        return jsonable(value)
    metadata=pack(r,'r');arrays['metadata_json']=np.array(json.dumps(metadata,ensure_ascii=False))
    np.savez_compressed(folder/'registro.npz',**arrays);write_json(folder/'metricas.json',r['metricas'])
    data=np.column_stack([r['t'],r['X'][:,12:15],r['altitud_m'],r['X'][:,2:8],r['U_real']])
    np.savetxt(folder/'registro.csv',data,delimiter=',',header='t_s,N_m,E_m,D_m,h_m,VT_m_s,alpha_rad,beta_rad,p_rad_s,q_rad_s,r_rad_s,de_deg,da_deg,dr_deg,throttle',comments='')
    return folder

def load_record(path):
    with np.load(path,allow_pickle=False) as f:
        def unpack(value):
            if isinstance(value,dict) and set(value)=={'__array__'}:return f[value['__array__']].copy()
            if isinstance(value,dict):return {k:unpack(v) for k,v in value.items()}
            return value
        return unpack(json.loads(str(f['metadata_json'])))
