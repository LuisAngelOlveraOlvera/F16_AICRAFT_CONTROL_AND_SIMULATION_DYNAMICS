"""Control -> 6DOF -> registro. Filas muestras; once escenarios del MATLAB."""
import numpy as np
from scipy.integrate import cumulative_trapezoid
from .dynamics import PAR,rhs,rkf_step,angles,quaternion,rotation,environment
from .control import trim,design
from .guidance import guide,wrap

SCENARIOS=('nivelado','lateral_abierto','longitudinal_abierto','lateral_lqr','viraje',
    'ascenso','autopiloto','trayectoria','dryden_abierto','dryden_lqr','waypoints',
    'pid_alfa','longitudinal_lqr')

def simulate(*,escenario='waypoints',duracion=180,paso=.002,VT=170,altitud=3000,
             semilla=11,tramo=15,waypoints_ned=None,posicion_inicial_ned=None,
             anticipacion_m=2000,radio_captura_m=250,targets=None,gust_series=None,noise_series=None):
    if escenario not in SCENARIOS:raise ValueError(f'Escenario desconocido: {escenario}')
    if escenario in ('pid_alfa','longitudinal_lqr'):
        if VT!=170 or altitud!=3000 or targets is not None or gust_series is not None or waypoints_ned is not None or posicion_inicial_ned is not None:
            raise ValueError('Demostraciones originales requieren 170 m/s, 3000 m y configuracion original')
        from .demonstrations import pid_demo,longitudinal_demo
        return (pid_demo if escenario=='pid_alfa' else longitudinal_demo)(duracion,paso)
    vals=[duracion,paso,VT,altitud,tramo,anticipacion_m,radio_captura_m]
    if not np.isfinite(vals).all() or duracion<=0 or not 0<paso<=.02 or not 100<=VT<=200 or not 0<=altitud<=10000 or min(tramo,anticipacion_m,radio_captura_m)<=0:
        raise ValueError('Configuracion fuera de dominio')
    if not isinstance(semilla,(int,np.integer)) or not 0<=semilla<=2**32-1:raise ValueError('Semilla invalida')
    N=round(duracion/paso)
    if N<1 or abs(N*paso-duracion)>1e-9:raise ValueError('Duracion debe ser multiplo del paso')
    nav=escenario=='waypoints';act=escenario in ('autopiloto','trayectoria','waypoints')
    closed=act or escenario in ('lateral_lqr','dryden_lqr');wind=escenario.startswith('dryden')
    gamma=5 if escenario=='ascenso' else 0;psidot=3 if escenario=='viraje' else 0
    xt,ut,info=trim(VT,altitud,gamma,psidot);a0=angles(xt[8:12]);c=design(xt,ut,closed,act)
    x=xt.copy()
    if escenario in ('lateral_abierto','lateral_lqr'):x[4]=np.radians(2);x[8:12]=quaternion(np.radians(10),a0[1],0)
    elif escenario=='longitudinal_abierto':x[3]+=np.radians(3)
    if act:x=np.r_[x,ut[:3]]
    if nav:
        if waypoints_ned is None:waypoints_ned=[[0,0,-altitud],[8000,0,-altitud-100],[16000,3000,-altitud-200],[24000,3000,-altitud-100]]
        wn=np.asarray(waypoints_ned,float)
        if wn.ndim!=2 or wn.shape[1]!=3 or len(wn)<2 or not np.isfinite(wn).all() or np.any(np.linalg.norm(np.diff(wn[:,:2],axis=0),axis=1)<=1):raise ValueError('Waypoints invalidos')
        w=wn.copy();w[:,2]*=-1;x[12:15]=wn[0]
        if posicion_inicial_ned is not None:
            pos=np.asarray(posicion_inicial_ned,float)
            if pos.shape!=(3,) or not np.isfinite(pos).all():raise ValueError('Posicion inicial invalida')
            x[12:15]=pos
        if abs(x[14]+altitud)>1e-9:raise ValueError('Altitud inicial distinta del trim')
        segment=0
    # Uniformes compatibles con MATLAB rng(...,'twister'); rng(0) usa 5489.
    # Los normales nativos usan otro transformador: la paridad usa noise_series.
    rng=np.random.RandomState(5489 if semilla==0 else semilla);nt=max(1,int(np.ceil(duracion/tramo)))
    if targets is None:
        targets=np.tile([altitud,VT,0.],(nt,1))
        if escenario=='trayectoria':
            targets[1:,0]=altitud+250*(2*rng.random(nt-1)-1)
            targets[1:,2]=np.cumsum(np.radians(80)*(2*rng.random(nt-1)-1))
    else:
        targets=np.asarray(targets,float)
        if targets.shape!=(nt,3) or not np.isfinite(targets).all():raise ValueError('Targets deben tener ceil(duracion/tramo) filas y tres columnas')
        if not np.all(targets[:,1]==VT):raise ValueError('La velocidad de targets debe coincidir con VT constante')
    if gust_series is not None:
        gust_series=np.asarray(gust_series,float)
        if gust_series.shape!=(N+1,3) or not np.isfinite(gust_series).all():raise ValueError('Rafagas incompatibles con tiempo')
    if noise_series is not None:
        noise_series=np.asarray(noise_series,float)
        if not wind or gust_series is not None or noise_series.shape!=(N,3) or not np.isfinite(noise_series).all():
            raise ValueError('Ruido requiere escenario Dryden, N filas y sin gust_series')
    t=np.arange(N+1)*paso;X=np.empty((N+1,len(x)));rawlog=np.empty((N+1,4));boundlog=rawlog.copy();reallog=rawlog.copy()
    G=np.zeros((N+1,3));refs=np.zeros((N+1,3));obj=refs.copy();navlog=[]
    ref=np.array([altitud,VT,0.]);integ=np.zeros(3);gust=np.zeros(3)
    for k,now in enumerate(t):
        target=np.array([altitud,VT,0.])
        if nav:
            target,ng=guide(x[12:15],w,segment,VT,anticipacion_m,radio_captura_m);segment=ng['tramo'];navlog.append(ng)
        elif escenario=='trayectoria':target=targets[min(int(np.floor(now/tramo)),len(targets)-1)]
        elif escenario=='autopiloto' and now>=5:target=np.array([altitud+100,VT,np.radians(20)])
        elif escenario=='viraje':target[2]=np.radians(psidot)*now
        elif escenario=='ascenso':target[0]=altitud+VT*np.sin(np.radians(gamma))*now
        if wind and gust_series is not None:gust=gust_series[k]
        a=angles(x[8:12]);h=-x[14];raw=ut.copy()
        if closed:
            lon=np.array([x[2]-xt[2],x[3]-xt[3],x[6],a[1]-a0[1],x[0]-xt[0],x[1]-xt[1]])
            lat=np.array([x[4],x[5],x[7],a[0]])
            if act:lon=np.r_[lon,h-ref[0],integ[:2]];lat=np.r_[lat,wrap(a[2]-ref[2]),integ[2]]
            ul=ut[[0,3]]-c['Klon']@lon;ua=ut[[1,2]]-c['Klat']@lat
            raw=np.r_[ul[0],ua,ul[1]]
        bound=np.clip(raw,[-25,-21.5,-30,0],[25,21.5,30,1]);real=bound.copy()
        if act:real[:3]=x[15:18]
        X[k]=x;rawlog[k]=raw;boundlog[k]=bound;reallog[k]=real;G[k]=gust;refs[k]=ref;obj[k]=target
        if k==N or (nav and ng['finalizado']):break
        fun=(lambda time,state,cmd,par:rhs(time,state,cmd,par,gust)) if wind else rhs
        x=rkf_step(fun,now,paso,x,bound)
        if act:
            integ+=paso*np.array([h-ref[0],X[k,2]-ref[1],wrap(a[2]-ref[2])])
            ref[0]+=paso*np.clip((target[0]-ref[0])/2,-10,10)
            ref[2]+=paso*np.clip(wrap(target[2]-ref[2])/2,-np.radians(3),np.radians(3))
        else:
            ref=target.copy()
            if escenario=='viraje':ref[2]=np.radians(psidot)*t[k+1]
            if escenario=='ascenso':ref[0]=altitud+VT*np.sin(np.radians(gamma))*t[k+1]
        if wind and gust_series is None:
            aa=x[2]/533;w=noise_series[k] if noise_series is not None else rng.standard_normal(3)
            gust=gust-paso*aa*gust+3*np.sqrt(2*aa*paso)*w
        if not np.isfinite(x).all() or x[2]<=1:raise RuntimeError(f'Divergencia en t={t[k+1]}')
    n=k+1;config=dict(escenario=escenario,duracion=duracion,paso=paso,VT=VT,altitud=altitud,semilla=semilla,tramo=tramo,
        anticipacion_m=anticipacion_m,radio_captura_m=radio_captura_m)
    r={'config':config,'theta':PAR.copy(),'trim':info,'Xtrim':xt,'Utrim':ut,'control':c,
        't':t[:n],'X':X[:n],'U_comando':rawlog[:n],'U_acotado':boundlog[:n],'U_real':reallog[:n],
        'rafaga_m_s':G[:n],'referencia':refs[:n],'objetivo':obj[:n]}
    observe(r,act,wind)
    if nav:
        r['config']['waypoints_ned']=wn.tolist()
        r['navegacion']={key:np.array([g[key] for g in navlog]) for key in navlog[0]}
        r['navegacion']['waypoints_ned']=wn
        err=r['navegacion']['error_espacial_m']
        r['metricas'].update(rms_error_espacial_m=float(np.sqrt(np.mean(err**2))),max_error_espacial_m=float(max(err)),
            distancia_final_m=float(ng['distancia_final_m']),ruta_completada=bool(ng['finalizado']))
        arc=np.r_[0,np.cumsum(np.linalg.norm(np.diff(wn[:,:2],axis=0),axis=1))];sigma=np.linspace(0,arc[-1],n)
        r['ruta_nominal_ned']=np.column_stack([np.interp(sigma,arc,wn[:,j]) for j in range(3)])
        r['etiqueta_ruta']='Ruta 3D deseada por waypoints'
    return r

def observe(r,act,wind):
    X=r['X'];n=len(X);ang=np.array([angles(x[8:12]) for x in X]);r['angulos_rad']=ang;r['altitud_m']=-X[:,14]
    r['norma_cuaternion']=np.linalg.norm(X[:,8:12],axis=1)
    F=np.empty((n,6));T=np.empty(n);LEF=T.copy();qb=T.copy();Mach=T.copy();specific=np.empty((n,3));inertial=specific.copy();dx=np.empty_like(X)
    for k,x in enumerate(X):
        g=r['rafaga_m_s'][k] if wind else None
        f,th,lef,q,sound,_=environment(x,r['U_real'][k],PAR,g)
        F[k]=f;T[k]=th;LEF[k]=lef;qb[k]=q;Mach[k]=x[2]/sound
        specific[k]=(f[:3]+[th,0,0])/PAR[0]
        inertial[k]=rotation(x[8:12]/np.linalg.norm(x[8:12]))@specific[k]+[0,0,PAR[1]]
        dx[k]=rhs(r['t'][k],x,r['U_acotado'][k] if act else r['U_real'][k],PAR,g)
    r.update(Mach=Mach,qbar_Pa=qb,LEF_deg=LEF,empuje_N=T,fuerzas_N=F[:,:3],momentos_Nm=F[:,[4,5,3]],
        especifica_cuerpo_m_s2=specific,aceleracion_inercial_m_s2=inertial,derivadas=dx,an_g=-F[:,2]/(PAR[0]*PAR[1]))
    sat=abs(r['U_comando']-r['U_acotado'])>1e-10;r['saturacion_comando']=sat
    r['saturacion_razon']=abs(dx[:,15:18])>=np.array([60,80,120])-1e-9 if act else np.zeros((n,3),bool)
    err=np.column_stack([r['altitud_m']-r['referencia'][:,0],X[:,2]-r['referencia'][:,1],wrap(ang[:,2]-r['referencia'][:,2])])
    rms=np.sqrt(np.mean(err**2,axis=0));r['metricas']={'rms_altitud_m':float(rms[0]),'rms_velocidad_m_s':float(rms[1]),
        'rms_rumbo_deg':float(np.degrees(rms[2])),'max_error_norma_quat':float(max(abs(r['norma_cuaternion']-1))),
        'fraccion_saturacion':np.mean(sat,axis=0).tolist()}
    dh=np.gradient(r['referencia'][:,0],r['config']['paso']) if n>1 else np.zeros(n)
    vh=np.sqrt(np.maximum(0,r['referencia'][:,1]**2-dh**2))
    r['ruta_nominal_ned']=np.column_stack([cumulative_trapezoid(vh*np.cos(r['referencia'][:,2]),r['t'],initial=0),
        cumulative_trapezoid(vh*np.sin(r['referencia'][:,2]),r['t'],initial=0),-r['referencia'][:,0]])
    r['etiqueta_ruta']='Ruta cinematica orientativa: h,VT,rumbo'
    r['unidades']={'X':'15/18 originales; SI/rad; alfaf y superficies grados','U':'de/da/dr grados; throttle [0,1]',
        'posicion':'NED metros','visual':'ENU kilometros global; metros local'}
