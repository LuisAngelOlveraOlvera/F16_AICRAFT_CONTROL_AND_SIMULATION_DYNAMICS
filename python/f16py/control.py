"""Equilibrio, Jacobiano centrado y LQR/LQI equivalentes al ejecutor MATLAB."""
from functools import lru_cache
import numpy as np
from scipy.optimize import least_squares
from scipy.linalg import solve_continuous_are
from .dynamics import PAR,rhs,rhs_euler,quaternion,quat_to_euler,power_command,euler_to_quat,environment

def alpha_reference(V,D):return 3 if V>83 and D<-100 else 8

def pid_alpha(reference_deg,alpha,q,integral,step,throttle):
    """ctrl_PID.m: error grados, integral deg*s, anti-windup original."""
    error=reference_deg-np.degrees(alpha)
    de=-5*error-1.5*integral+.8*np.degrees(q)
    if abs(de)<25:
        integral+=error*step;de=-5*error-1.5*integral+.8*np.degrees(q)
    return np.array([np.clip(de,-25,25),0,0,throttle]),integral

def linearize(x,u,model='quaternion',step=1e-6,order=2):
    """A/B/C/D; salidas [an_g,q_rad_s,alpha_deg]; no mezclar coordenadas."""
    x=np.asarray(x,float);u=np.asarray(u,float)
    if model=='euler':fun=rhs_euler;as_quat=euler_to_quat
    elif model=='quaternion':fun=rhs;as_quat=lambda z:z
    else:raise ValueError('model debe ser quaternion o euler')
    def output(z,v):
        q=as_quat(z);real=np.r_[q[15:18],v[3]] if len(q)==18 else v
        F,*_=environment(q,real)
        return np.array([-F[2]/(PAR[0]*PAR[1]),q[6],np.degrees(q[3])])
    return (jacobian(lambda z:fun(0,z,u),x,step,order),jacobian(lambda v:fun(0,x,v),u,step,order),
        jacobian(lambda z:output(z,u),x,step,order),jacobian(lambda v:output(x,v),u,step,order))

def jacobian(fun,x,step=1e-6,order=2):
    x=np.asarray(x,float);J=np.empty((len(fun(x)),len(x)))
    for j in range(len(x)):
        h=step*max(1,abs(x[j]));d=np.zeros(len(x));d[j]=h
        if order==2:J[:,j]=(fun(x+d)-fun(x-d))/(2*h)
        elif order==4:J[:,j]=(8*(fun(x+d)-fun(x-d))-(fun(x+2*d)-fun(x-2*d)))/(12*h)
        else:raise ValueError('Orden centrado debe ser 2 o 4')
    return J

@lru_cache(maxsize=32)
def _trim(V,h,gamma,psidot):
    gam=np.radians(gamma);ps=np.radians(psidot)
    def state(z):
        a,de,da,dr,th,fi=z;aa=np.cos(a);bb=np.cos(fi)*np.sin(a);sg=np.sin(gam)
        pitch=np.arctan((aa*bb+sg*np.sqrt(aa*aa-sg*sg+bb*bb))/(aa*aa-sg*sg))
        omega=ps*np.array([-np.sin(pitch),np.sin(fi)*np.cos(pitch),np.cos(fi)*np.cos(pitch)])
        x=np.r_[power_command(th),1.38*np.degrees(a),V,a,0,omega,quaternion(fi,pitch,0),0,0,-h]
        return x,np.array([de,da,dr,th])
    def residual(z):
        x,u=state(z);d=rhs(0,x,u)
        return d[2:8]*np.array([1,100,100,100,100,100])
    z0=[np.radians(2),-2,0,0,.3,np.arctan2(ps*V,PAR[1])]
    sol=least_squares(residual,z0,bounds=([-1,-25,-21.5,-30,0,-1.5],[1,25,21.5,30,1,1.5]),
        xtol=1e-13,ftol=1e-13,gtol=1e-13,max_nfev=4000)
    x,u=state(sol.x);res=float(np.linalg.norm(residual(sol.x)))
    return x,u,{'residuo':res,'converge':res<1e-6,'alfa_deg':float(np.degrees(x[3])),
        'de_deg':float(u[0]),'dth':float(u[3]),'fi_deg':float(np.degrees(sol.x[5])),
        'gamma_deg':gamma,'psidot_dps':psidot,'solver':'SciPy least_squares; mismo residuo fisico'}

def trim(V=170,h=3000,gamma=0,psidot=0):
    x,u,info=_trim(float(V),float(h),float(gamma),float(psidot))
    if not info['converge']:raise RuntimeError(f'Trim no convergido: {info}')
    return x.copy(),u.copy(),info.copy()

def lqr(A,B,Q,R):
    P=solve_continuous_are(A,B,Q,R);return np.linalg.solve(R,B.T@P)

def design(x,u,closed=False,act=False):
    e=quat_to_euler(x);A=jacobian(lambda z:rhs_euler(0,z,u),e);B=jacobian(lambda v:rhs_euler(0,e,v),u)
    il=[2,3,6,9,0,1];ia=[4,5,7,8];Al=A[np.ix_(il,il)];Bl=B[np.ix_(il,[0,3])]
    At=A[np.ix_(ia,ia)];Bt=B[np.ix_(ia,[1,2])];rad=np.pi/180
    c={'A14':A,'B14':B,'Alon':Al,'Alat':At,'polos_lon':np.linalg.eigvals(Al),
        'polos_lat':np.linalg.eigvals(At),'Klon':None,'Klat':None}
    if not closed:return c
    if act:
        Aa=np.zeros((9,9));Ba=np.zeros((9,2));Aa[:6,:6]=Al;Ba[:6]=Bl
        Aa[6,1]=-x[2];Aa[6,3]=x[2];Aa[7,6]=1;Aa[8,0]=1
        Q=np.diag([1,1/(2*rad)**2,1/(10*rad)**2,1/(5*rad)**2,1e-6,1e-6,1/5**2,1/50**2,1/30**2])
        c['Klon']=lqr(Aa,Ba,Q,np.diag([1/5**2,1/.3**2]))
        Aa=np.zeros((6,6));Ba=np.zeros((6,2));Aa[:4,:4]=At;Ba[:4]=Bt
        Aa[4,2]=1/np.cos(e[9]);Aa[5,4]=1
        Q=np.diag([1/rad**2,1/(20*rad)**2,1/(10*rad)**2,1/(15*rad)**2,1/(5*rad)**2,1/(40*rad)**2])
        c['Klat']=lqr(Aa,Ba,Q,np.diag([1/15**2,1/15**2]))
    else:
        c['Klon']=lqr(Al,Bl,np.diag([1/2**2,1/rad**2,1/(5*rad)**2,1/(2*rad)**2,1e-6,1e-6]),np.diag([1/5**2,1/.2**2]))
        c['Klat']=lqr(At,Bt,np.diag([1/(.5*rad)**2,1/(10*rad)**2,1/(5*rad)**2,1/(5*rad)**2]),np.diag([1/10**2,1/10**2]))
    return c

LEWIS_LATERAL=np.array([[-.322,.064032,.038904,-.99156],[0,0,1,.039385],
    [-30.919,0,-3.673,.67425],[9.4724,0,-.026358,-.49849]])
LEWIS_LONGITUDINAL=np.array([[-.020244,7.8761,-32.169,-.65020],
    [-.00025373,-1.0189,0,.90484],[0,0,0,1],[7.9472e-11,-2.4982,0,-1.3861]])

def compare_lewis():
    x,u,info=trim(153.0096,0);e=quat_to_euler(x);A=jacobian(lambda z:rhs_euler(0,z,u),e)
    S=np.diag([1/.3048,1,1,1]);il=[2,3,9,6];ia=[4,8,5,7]
    lon=S@A[np.ix_(il,il)]@np.linalg.inv(S);lat=A[np.ix_(ia,ia)]
    def comparison(a,ref):
        d=a-ref;rel=np.full_like(d,np.nan);np.divide(abs(d),abs(ref),out=rel,where=ref!=0)
        return {'A':a,'reference':ref,'difference':d,'absolute_error':abs(d),'relative_error':rel,
            'relative_frobenius':float(np.linalg.norm(d)/np.linalg.norm(ref)),
            'poles':np.linalg.eigvals(a),'reference_poles':np.linalg.eigvals(ref)}
    return {'source':'Stevens, Lewis, Johnson 2015; comparacion provisional de modelos distintos',
        'trim':info,'dynamic_residual':rhs(0,x,u)[:8],
        'lateral':comparison(lat,LEWIS_LATERAL),'longitudinal':comparison(lon,LEWIS_LONGITUDINAL)}
