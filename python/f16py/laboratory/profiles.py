"""Perfiles originales del README y contrato para la futura interfaz MATLAB."""
from copy import deepcopy

PROFILES={
 'pid':('PID de alfa · pruebarkf',15,'pid_alfa'),
 'lqr_longitudinal':('LQR longitudinal · prueba_lqr',20,'longitudinal_lqr'),
 'lqr_lateral':('LQR lateral · prueba_lqr_lat',15,'lateral_lqr'),
 'comparacion':('Euler/cuat y PID/LQR · prueba_comparacion',15,'comparacion'),
 'autopiloto':('Autopiloto · prueba_autopiloto',40,'autopiloto'),
 'dryden_original':('Dryden original · prueba_dryden',30,'dryden_lqr'),
 'trayectoria_original':('Trayectoria original · prueba_trayectoria',180,'trayectoria'),
 'waypoints':('Waypoints · ejecutar_waypoints_f16',180,'waypoints'),
 'generico':('Escenarios del ejecutor académico',90,'trayectoria'),
}

def defaults(profile):
    if profile not in PROFILES:raise ValueError('Perfil desconocido')
    _,duration,scenario=PROFILES[profile]
    lateral=scenario in ('lateral_lqr','lateral_abierto')
    longitudinal=scenario in ('longitudinal_lqr','longitudinal_abierto','comparacion')
    return deepcopy(dict(original=profile!='generico',escenario=scenario,duracion=duration,
      paso=.002,VT=170.,altitud=3000.,semilla=7 if profile=='dryden_original' else 11,tramo=30. if profile=='trayectoria_original' else 15.,
      anticipacion_m=2000.,radio_captura_m=250.,
      waypoints=[[0.,0.,3000.],[8000.,0.,3100.],[16000.,3000.,3200.],[24000.,3000.,3100.]],
      posicion_inicial=None,
      initial=dict(alpha_deg=3. if longitudinal else 0.,beta_deg=2. if lateral else 0.,
        phi_deg=10. if lateral else 0.,theta_deg=0.,psi_deg=0.,p_deg_s=0.,q_deg_s=0.,r_deg_s=0.),
      pid=dict(kp=5.,ki=1.5,kq=.8,alpha_ref_deg=3.,throttle=.35,alpha_initial_deg=2.),
      weights=dict(q_lon=1.,r_lon=1.,q_lat=1.,r_lat=1.),
      manual=dict(elevador_deg=0.,aleron_deg=0.,timon_deg=0.,throttle=.35,time_s=0.),
      reference=dict(delta_h_m=100.,delta_v_m_s=0.,delta_psi_deg=20.,time_s=5.,
        h_rate_m_s=10.,v_rate_m_s2=1.,psi_rate_deg_s=3.,gamma_deg=5.,turn_deg_s=3.,
        trayectoria_h_m=250.,trayectoria_rumbo_deg=80.),
      turbulence=dict(sigma_u=3.,sigma_v=3.,sigma_w=3.,length_u=533.,length_v=533.,length_w=533.)))

def merge(base,updates):
    out=deepcopy(base)
    for key,value in (updates or {}).items():
        if key not in out:raise ValueError('Opción desconocida: '+key)
        out[key]=merge(out[key],value) if isinstance(out[key],dict) and isinstance(value,dict) else deepcopy(value)
    return out

def applicable_fields(scenario):
    """Mismos campos para validar configuración y habilitar la interfaz."""
    fields={'duracion','paso','VT','altitud','escenario','original'}
    if scenario in ('trayectoria','dryden_abierto','dryden_lqr'):fields.add('semilla')
    if scenario=='trayectoria':fields.add('tramo')
    if scenario=='waypoints':fields.update(('waypoints','posicion_inicial','anticipacion_m','radio_captura_m'))
    initial=defaults('generico')['initial']
    fields.update('initial.'+k for k in initial if scenario!='comparacion' or k=='alpha_deg')
    if scenario=='pid_alfa':fields.update('pid.'+k for k in defaults('pid')['pid'])
    if scenario=='comparacion':fields.update(('pid.kp','pid.ki','pid.kq'))
    if scenario in ('longitudinal_lqr','comparacion'):fields.update(('weights.q_lon','weights.r_lon'))
    elif scenario in ('lateral_lqr','autopiloto','trayectoria','waypoints','dryden_lqr'):
        fields.update('weights.'+k for k in defaults('generico')['weights'])
    if scenario in ('dryden_abierto','dryden_lqr'):fields.update('turbulence.'+k for k in defaults('generico')['turbulence'])
    if scenario=='manual':fields.update('manual.'+k for k in defaults('generico')['manual'])
    if scenario=='autopiloto':fields.update('reference.'+k for k in ('delta_h_m','delta_v_m_s','delta_psi_deg','time_s'))
    if scenario in ('autopiloto','trayectoria','waypoints'):fields.update('reference.'+k for k in ('h_rate_m_s','v_rate_m_s2','psi_rate_deg_s'))
    if scenario=='trayectoria':fields.update(('reference.trayectoria_h_m','reference.trayectoria_rumbo_deg'))
    if scenario=='ascenso':fields.add('reference.gamma_deg')
    if scenario=='viraje':fields.add('reference.turn_deg_s')
    return fields
