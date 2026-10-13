"""Servicio sin UI: cálculos existentes y metadatos de ensayo independientes."""
import hashlib
import math
from numbers import Real
from pathlib import Path
import numpy as np
from .profiles import defaults,merge,applicable_fields

def aircraft_data():
    from ..dynamics import PAR
    # Recuperar inercias desde c3,c4,c7,c9 usados por la planta.
    d=1/(PAR[9]*PAR[15]-PAR[10]**2)
    return dict(masa_kg=float(PAR[0]),gravedad_m_s2=float(PAR[1]),peso_N=float(PAR[0]*PAR[1]),
      superficie_m2=float(PAR[2]),cuerda_m=float(PAR[3]),envergadura_m=float(PAR[4]),
      cg_referencia_fraccion=float(PAR[5]),cg_fraccion=float(PAR[6]),
      Ix_kg_m2=round(float(PAR[15]*d),6),Iy_kg_m2=round(float(1/PAR[13]),6),
      Iz_kg_m2=round(float(PAR[9]*d),6),Ixz_kg_m2=round(float(PAR[10]*d),6),
      momento_motor_kg_m2_s=float(PAR[16]),longitud_real_m=None,altura_real_m=None,
      fuente='f16py.dynamics.parameters; valores del modelo académico',
      geometria='Geometría docente; longitud visual 14.8 m, no dimensión real verificada')

def validate(profile,cfg):
    baseline=defaults(profile)
    if not isinstance(cfg['original'],bool):raise ValueError('Modo original debe ser booleano')
    for key in ('duracion','paso','VT','altitud','tramo','anticipacion_m','radio_captura_m'):
        v=cfg[key]
        if isinstance(v,bool) or not isinstance(v,(float,int)) or not math.isfinite(v):raise ValueError('Valor numérico inválido: '+key)
    if not (0<cfg['paso']<=.02 and cfg['duracion']>0 and 100<=cfg['VT']<=200 and 0<=cfg['altitud']<=10000):raise ValueError('Tiempo/velocidad/altitud fuera de límites')
    n=round(cfg['duracion']/cfg['paso'])
    if n<1 or abs(n*cfg['paso']-cfg['duracion'])>1e-9:raise ValueError('Duración debe ser múltiplo del paso')
    if n>500000:raise ValueError('Más de 500 000 pasos: reduce duración o aumenta paso')
    if min(cfg['tramo'],cfg['anticipacion_m'],cfg['radio_captura_m'])<=0:raise ValueError('Tramo, anticipación y radio deben ser positivos')
    seed=cfg['semilla']
    if isinstance(seed,bool) or not isinstance(seed,int) or not 0<=seed<=2**32-1:raise ValueError('Semilla inválida')
    if cfg['original']:
        for key in cfg:
            if key not in ('duracion','paso','original') and cfg[key]!=baseline[key]:
                raise ValueError('Para editar '+key+' desactiva «Configuración original README»')
        if profile=='dryden_original' and (cfg['paso']!=.002 or cfg['duracion']>30):raise ValueError('Dryden original requiere paso .002 y duración <=30 s')
        if profile=='trayectoria_original' and cfg['duracion']>180:raise ValueError('Trayectoria original limitada a 180 s')
    from ..simulation import SCENARIOS
    if cfg['escenario'] not in (*SCENARIOS,'comparacion','manual'):raise ValueError('Escenario desconocido')
    if profile!='generico' and cfg['escenario']!=baseline['escenario']:raise ValueError('El escenario corresponde al perfil seleccionado; usa el perfil genérico para elegir otro')
    for group in ('initial','pid','weights','reference','turbulence','manual'):
        if not isinstance(cfg[group],dict) or set(cfg[group])!=set(baseline[group]):raise ValueError('Grupo de opciones inválido: '+group)
        for key,v in cfg[group].items():
            if isinstance(v,bool) or not isinstance(v,(float,int)) or not math.isfinite(v):raise ValueError('Valor inválido: '+group+'.'+key)
    if any(v<=0 for v in cfg['weights'].values()):raise ValueError('Factores Q/R deben ser positivos')
    if any(cfg['pid'][k]<0 for k in ('kp','ki','kq')) or not 0<=cfg['pid']['throttle']<=1:raise ValueError('Ganancias PID o throttle inválidos')
    if any(cfg['turbulence'][k]<0 for k in ('sigma_u','sigma_v','sigma_w')) or any(cfg['turbulence'][k]<=0 for k in ('length_u','length_v','length_w')):raise ValueError('Dryden requiere sigma >=0 y escalas >0')
    if any(cfg['reference'][k]<=0 for k in ('h_rate_m_s','v_rate_m_s2','psi_rate_deg_s')) or cfg['reference']['time_s']<0:raise ValueError('Límites de referencia inválidos')
    manual=cfg['manual']
    if not (-25<=manual['elevador_deg']<=25 and -21.5<=manual['aleron_deg']<=21.5 and -30<=manual['timon_deg']<=30 and 0<=manual['throttle']<=1 and manual['time_s']>=0):raise ValueError('Mandos manuales fuera de límites')
    if cfg['reference']['trayectoria_h_m']<0 or cfg['reference']['trayectoria_rumbo_deg']<0:raise ValueError('Amplitudes de trayectoria deben ser no negativas')
    if not cfg['original']:
        s=cfg['escenario']
        allowed=applicable_fields(s)
        for group,value in cfg.items():
            if isinstance(value,dict):
                for key,v in value.items():
                    if group+'.'+key not in allowed and v!=baseline[group][key]:raise ValueError(f'{group}.{key} no se aplica al escenario {s}')
            elif group not in allowed and value!=baseline[group]:raise ValueError(f'{group} no se aplica al escenario {s}')
    if cfg['escenario']=='waypoints':
        w=np.asarray(cfg['waypoints'],float)
        if w.ndim!=2 or w.shape[1]!=3 or len(w)<2 or not np.isfinite(w).all() or np.any(np.linalg.norm(np.diff(w[:,:2],axis=0),axis=1)<=1):raise ValueError('Ruta inválida: mínimo dos puntos y tramos horizontales >1 m')
        pos=w[0] if cfg['posicion_inicial'] is None else np.asarray(cfg['posicion_inicial'],float)
        if pos.shape!=(3,) or not np.isfinite(pos).all() or abs(pos[2]-cfg['altitud'])>1e-9:raise ValueError('Altitud de posición inicial debe coincidir con trim')
    return cfg

def run_experiment(profile,options=None):
    cfg=validate(profile,merge(defaults(profile),options))
    from ..demonstrations import pid_demo,longitudinal_demo,comparison_demo,dryden_pair
    from ..simulation import simulate
    if cfg['original']:
        duration,step=cfg['duracion'],cfg['paso']
        if profile=='pid':records=(pid_demo(duration,step),)
        elif profile=='lqr_longitudinal':records=(longitudinal_demo(duration,step),)
        elif profile=='comparacion':records=(comparison_demo(duration,step),)
        elif profile=='dryden_original':records=dryden_pair(duration,step)
        elif profile=='trayectoria_original':
            from ..execution import trajectory
            records=(trajectory(duration,step),)
        else:records=(simulate(escenario=cfg['escenario'],duracion=duration,paso=step),)
    else:
        duration,step=cfg['duracion'],cfg['paso']
        scenario=cfg['escenario']
        if scenario in ('pid_alfa','longitudinal_lqr','comparacion'):
            fun={'pid_alfa':pid_demo,'longitudinal_lqr':longitudinal_demo,'comparacion':comparison_demo}[scenario]
            if scenario=='comparacion' and any(cfg['initial'][k]!=0 for k in cfg['initial'] if k!='alpha_deg'):
                raise ValueError('Comparación original extendida admite únicamente perturbación alfa')
            records=(fun(duration,step,laboratory=cfg),)
        else:
            kwargs={k:cfg[k] for k in ('duracion','paso','VT','altitud','semilla','tramo','anticipacion_m','radio_captura_m')}
            if scenario=='waypoints':
                w=np.asarray(cfg['waypoints'],float).copy();w[:,2]*=-1;kwargs['waypoints_ned']=w
                if cfg['posicion_inicial'] is not None:
                    pos=np.asarray(cfg['posicion_inicial'],float).copy();pos[2]*=-1;kwargs['posicion_inicial_ned']=pos
            if profile=='dryden_original':
                records=tuple(simulate(escenario=s,laboratory=cfg,**kwargs) for s in ('dryden_abierto','dryden_lqr'))
            else:records=(simulate(escenario='nivelado' if scenario=='manual' else scenario,laboratory=cfg,**kwargs),)
            if scenario=='manual':records[0]['config']['escenario']='manual'
    source=Path(__file__).resolve().parents[1]
    hashes={str(p.relative_to(source)):hashlib.sha256(p.read_bytes()).hexdigest() for p in source.rglob('*.py')}
    if cfg['original'] and profile in ('dryden_original','trayectoria_original'):
        fixture=source.parent/'references'/('dryden_original.mat' if profile=='dryden_original' else 'trayectoria.mat')
        hashes['references/'+fixture.name]=hashlib.sha256(fixture.read_bytes()).hexdigest()
    for r in records:
        r['laboratorio']=dict(perfil=profile,original=cfg['original'],opciones=cfg,
           implementacion='Python',contrato=1,fuentes_sha256=hashes)
    return records

def validate_record(r):
    """Validar antes de sustituir un registro válido de la interfaz."""
    try:
        t=np.asarray(r['t']);X=np.asarray(r['X']);n=len(t)
        if t.ndim!=1 or n<1 or X.ndim!=2 or X.shape not in ((n,15),(n,18)) or not np.isfinite(t).all() or not np.isfinite(X).all() or np.any(np.diff(t)<=0):raise ValueError('Estado/tiempo incompatibles')
        if np.any(np.linalg.norm(X[:,8:12],axis=1)<1e-12):raise ValueError('Cuaternión nulo')
        vector=['altitud_m','Mach','empuje_N','qbar_Pa','an_g','LEF_deg']
        for key in vector:
            v=np.asarray(r[key])
            if v.shape!=(n,) or not np.isfinite(v).all():raise ValueError('Salida inválida: '+key)
        if 'referencia_alfa_deg' in r:
            v=np.asarray(r['referencia_alfa_deg'])
            if v.shape!=(n,) or not np.isfinite(v).all():raise ValueError('Referencia alfa incompatible')
        for key,cols in [('angulos_rad',3),('U_real',4),('rafaga_m_s',3),('referencia',3),('fuerzas_N',3),('momentos_Nm',3)]:
            v=np.asarray(r[key])
            if v.shape!=(n,cols) or not np.isfinite(v).all():raise ValueError('Salida incompatible: '+key)
        if 'ruta_nominal_ned' in r:
            route=np.asarray(r['ruta_nominal_ned'])
            if route.shape!=(n,3) or not np.isfinite(route).all():raise ValueError('Ruta nominal incompatible')
        if 'navegacion' in r:
            wp=np.asarray(r['navegacion']['waypoints_ned'])
            if wp.ndim!=2 or wp.shape[1]!=3 or len(wp)<2 or not np.isfinite(wp).all():raise ValueError('Waypoints del registro inválidos')
        if 'laboratorio' in r and not isinstance(r['laboratorio'],dict):raise ValueError('Metadatos inválidos')
        if r['config']['escenario']=='comparacion':
            for key,cols in [('He',4),('Xl',6),('Xp',6),('Xk',6),('uk',2)]:
                v=np.asarray(r[key])
                if v.shape!=(n,cols) or not np.isfinite(v).all():raise ValueError('Comparación incompleta: '+key)
            if np.asarray(r['up']).shape!=(n,) or np.asarray(r['Xtrim']).shape!=(15,) or np.asarray(r['Utrim']).shape!=(4,):raise ValueError('Datos de control incompletos')
        for key in ('VT','altitud'):
            v=r['config'][key]
            if isinstance(v,bool) or not isinstance(v,Real) or not math.isfinite(v):raise ValueError('Condición inválida')
        if not isinstance(r['config']['escenario'],str):raise ValueError('Escenario inválido')
        for key in ('rms_altitud_m','rms_velocidad_m_s','rms_rumbo_deg'):
            v=r['metricas'][key]
            if isinstance(v,bool) or not isinstance(v,Real) or not math.isfinite(v):raise ValueError('Métrica inválida')
    except (KeyError,TypeError,IndexError) as exc:raise ValueError('Registro incompleto o inválido') from exc
    return r
