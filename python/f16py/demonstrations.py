"""Demostraciones originales MATLAB: mismas condiciones, ganancias y ZOH."""
import numpy as np
from .control import trim,design,pid_alpha,alpha_reference
from .dynamics import PAR,rhs,rhs_euler,rkf_step,quaternion,angles,quat_to_euler

def _time(duration,step):
    if not np.isfinite([duration,step]).all() or duration<=0 or not 0<step<=.02:
        raise ValueError('Duracion/paso invalidos')
    n=round(duration/step)
    if n<1 or abs(n*step-duration)>1e-9:raise ValueError('Duracion no multiplo del paso')
    return np.arange(n+1)*step

def _record(name,t,X,U,xt,ut,info,c,condition=None):
    from .simulation import observe
    r={'config':{'escenario':name,'duracion':float(t[-1]),'paso':float(t[1]-t[0]),
        'VT':170,'altitud':3000},'t':t,'X':X,'Xtrim':xt,'Utrim':ut,'trim':info,
        'theta':PAR.copy(),'control':c,'U_comando':U.copy(),'U_acotado':U.copy(),
        'U_real':U.copy(),'rafaga_m_s':np.zeros((len(t),3)),
        'referencia':np.tile([3000,170,0.],(len(t),1)),
        'objetivo':np.tile([3000,170,0.],(len(t),1))}
    if condition is not None:
        r['config'].update(VT=condition['VT'],altitud=condition['altitud'])
        r['referencia'][:,0]=condition['altitud'];r['referencia'][:,1]=condition['VT'];r['objetivo']=r['referencia'].copy()
    observe(r,False,False);return r

def pid_demo(duracion=15,paso=.002,*,laboratory=None):
    t=_time(duracion,paso);xt,ut,info=trim() if laboratory is None else trim(laboratory['VT'],laboratory['altitud']);c=design(xt,ut)
    x=np.r_[0,2.76,170,np.radians(2),0,0,0,0,quaternion(0,np.radians(2),0),0,0,-3000.]
    if laboratory is not None:
        from .laboratory.options import perturb
        alpha=laboratory['pid']['alpha_initial_deg'];x[1]=1.38*alpha;x[2]=laboratory['VT'];x[3]=np.radians(alpha);x[14]=-laboratory['altitud'];x[8:12]=quaternion(0,np.radians(alpha),0)
        x=perturb(x,laboratory['initial'])
    X=np.empty((len(t),15));U=np.empty((len(t),4));ref=np.empty(len(t));integral=0.
    X[0]=x
    for k,now in enumerate(t[:-1]):
        ref[k]=alpha_reference(x[2],x[14]) if laboratory is None else laboratory['pid']['alpha_ref_deg']
        gains=None if laboratory is None else tuple(laboratory['pid'][key] for key in ('kp','ki','kq'))
        throttle=.35 if laboratory is None else laboratory['pid']['throttle']
        U[k],integral=pid_alpha(ref[k],x[3],x[6],integral,paso,throttle,gains=gains)
        x=rkf_step(rhs,now,paso,x,U[k]);X[k+1]=x
    U[-1]=U[-2];ref[-1]=ref[-2]
    r=_record('pid_alfa',t,X,U,xt,ut,info,c,laboratory);r['referencia_alfa_deg']=ref
    return r

def longitudinal_demo(duracion=20,paso=.002,*,laboratory=None):
    t=_time(duracion,paso);xt,ut,info=trim() if laboratory is None else trim(laboratory['VT'],laboratory['altitud']);c=design(xt,ut,True,weights=None if laboratory is None else laboratory['weights'])
    x=xt.copy();x[3]+=np.radians(3);X=np.empty((len(t),15));U=np.empty((len(t),4));X[0]=x
    if laboratory is not None:
        from .laboratory.options import perturb
        x=perturb(xt,laboratory['initial']);X[0]=x
    pitch=angles(xt[8:12])[1]
    for k,now in enumerate(t[:-1]):
        lon=np.array([x[2]-xt[2],x[3]-xt[3],x[6],angles(x[8:12],False)[1]-pitch,x[0]-xt[0],x[1]-xt[1]])
        ul=ut[[0,3]]-c['Klon']@lon
        U[k]=[np.clip(ul[0],-25,25),0,0,np.clip(ul[1],0,1)]
        x=rkf_step(rhs,now,paso,x,U[k]);X[k+1]=x
    U[-1]=U[-2]
    return _record('longitudinal_lqr',t,X,U,xt,ut,info,c,laboratory)

def _rk4(A,b,x,h):
    k1=A@x+b;k2=A@(x+h*k1/2)+b;k3=A@(x+h*k2/2)+b;k4=A@(x+h*k3)+b
    return x+h*(k1+2*k2+2*k3+k4)/6

def comparison_demo(duracion=15,paso=.002,*,laboratory=None):
    t=_time(duracion,paso);xt,ut,info=trim() if laboratory is None else trim(laboratory['VT'],laboratory['altitud']);c=design(xt,ut,True,weights=None if laboratory is None else laboratory['weights'])
    A=c['Alon'];e=quat_to_euler(xt);il=[2,3,6,9,0,1]
    from .control import jacobian
    B=jacobian(lambda u:rhs_euler(0,e,u),ut)[np.ix_(il,[0,3])]
    delta=np.radians(3 if laboratory is None else laboratory['initial']['alpha_deg'])
    q=xt.copy();q[3]+=delta;e[3]+=delta
    Hq=np.empty((len(t),4));He=Hq.copy();Xq=np.empty((len(t),15))
    xl=np.zeros(6);xl[1]=delta;xp=xl.copy();xk=xl.copy()
    Xl=np.empty((len(t),6));Xp=Xl.copy();Xk=Xl.copy();up=np.zeros(len(t));uk=np.zeros((len(t),2));ie=0.
    for k,now in enumerate(t):
        Hq[k]=[q[3],angles(q[8:12],False)[1],q[2],q[6]];He[k]=e[[3,9,2,6]];Xq[k]=q
        Xl[k]=xl;Xp[k]=xp;Xk[k]=xk
        if k==len(t)-1:break
        q=rkf_step(rhs,now,paso,q,ut);e=rkf_step(rhs_euler,now,paso,e,ut)
        gains=None if laboratory is None else tuple(laboratory['pid'][key] for key in ('kp','ki','kq'))
        cmd,ie=pid_alpha(0,xp[1],xp[2],ie,paso,0,gains=gains);up[k]=cmd[0];uk[k]=-c['Klon']@xk
        xl=_rk4(A,np.zeros(6),xl,paso);xp=_rk4(A,B@cmd[[0,3]],xp,paso);xk=_rk4(A,B@uk[k],xk,paso)
    up[-1]=up[-2];uk[-1]=uk[-2]
    r=_record('comparacion',t,Xq,np.tile(ut,(len(t),1)),xt,ut,info,c,laboratory)
    r.update(Hq=Hq,He=He,Xl=Xl,Xp=Xp,Xk=Xk,up=up,uk=uk,Alon=A,Blon=B,K=c['Klon'])
    return r

def comparison_plots(r,folder=None):
    import matplotlib.pyplot as plt
    from pathlib import Path
    figures={};t=r['t'];scale=[180/np.pi,180/np.pi,1,180/np.pi]
    f,axes=plt.subplots(2,2,figsize=(11,7),layout='constrained');figures['formulaciones']=f
    for j,a in enumerate(axes.flat):
        a.plot(t,r['Hq'][:,j]*scale[j],label='Cuaterniones');a.plot(t,r['He'][:,j]*scale[j],'--',label='Euler')
        a.set(xlabel='t [s]',ylabel=['alpha [deg]','theta [deg]','VT [m/s]','q [deg/s]'][j]);a.grid();a.legend()
    f,axes=plt.subplots(2,2,figsize=(11,7),layout='constrained');figures['pid_lqr']=f
    for a,j,k,label,sc in zip(list(axes.flat)[:3],[0,3,2],[1,2,0],['Delta alpha [deg]','q [deg/s]','Delta VT [m/s]'],[180/np.pi,180/np.pi,1]):
        base=r['Xtrim'][3] if j==0 else (r['Xtrim'][2] if j==2 else 0)
        a.plot(t,(r['Hq'][:,j]-base)*sc,label='No lineal abierto')
        for key,name in [('Xl','Lineal abierto'),('Xp','Lineal + PID'),('Xk','Lineal + LQR')]:a.plot(t,r[key][:,k]*sc,label=name)
        a.set(xlabel='t [s]',ylabel=label);a.grid();a.legend()
    a=axes[1,1];a.plot(t,r['up'],label='PID');a.plot(t,r['uk'][:,0],label='LQR');a.set(xlabel='t [s]',ylabel='Delta elevador [deg]');a.grid();a.legend()
    if folder:
        for name,f in figures.items():f.savefig(Path(folder)/(name+'.png'),dpi=140)
    return figures

def dryden_pair(duracion=30,paso=.002):
    from pathlib import Path
    from scipy.io import loadmat
    t=_time(duracion,paso)
    if paso!=.002 or duracion>30:raise ValueError('Dryden original requiere paso .002 y horizonte <=30 s')
    W=loadmat(Path(__file__).resolve().parents[1]/'references'/'dryden_original.mat',simplify_cells=True)['d']['W'].T
    xt,ut,info=trim();c=design(xt,ut,True);pitch=angles(xt[8:12])[1];records=[]
    for closed in [False,True]:
        x=xt.copy();gust=np.zeros(3);X=np.empty((len(t),15));U=np.empty((len(t),4));G=np.empty((len(t),3));H=np.empty((len(t),5))
        H[0]=[x[3],x[4],0,x[2],0];X[0]=x
        for k,now in enumerate(t[:-1]):
            rate=x[2]/533;gust=gust-paso*rate*gust+3*np.sqrt(2*rate*paso)*W[k];cmd=ut.copy()
            if closed:
                a=angles(x[8:12],False);lon=np.array([x[2]-xt[2],x[3]-xt[3],x[6],a[1]-pitch,x[0]-xt[0],x[1]-xt[1]])
                lat=np.array([x[4],x[5],x[7],a[0]]);ul=ut[[0,3]]-c['Klon']@lon;ua=-c['Klat']@lat
                cmd=np.clip([ul[0],ua[0],ua[1],ul[1]],[-25,-21.5,-30,0],[25,21.5,30,1])
            U[k]=cmd;G[k]=gust
            x=rkf_step(lambda time,state,u,par:rhs(time,state,u,par,gust),now,paso,x,cmd);X[k+1]=x
            H[k+1]=[x[3],x[4],angles(x[8:12],False)[0],x[2],gust[2]]
        U[-1]=U[-2];G[-1]=G[-2]
        r=_record('dryden_lqr_original' if closed else 'dryden_abierto_original',t,X,U,xt,ut,info,c)
        r['rafaga_m_s']=G
        from .simulation import observe
        observe(r,False,True);r['H']=H;records.append(r)
    return tuple(records)
