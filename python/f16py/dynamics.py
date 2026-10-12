"""Planta 15/18, Euler 14 y cuerpo auxiliar 13. SI, rad, NED; Q escalar primero."""
from math import sin,cos,tan,asin,atan2,sqrt,exp,pi
import numpy as np
from .aerodynamics import loads
from . import fits

def parameters():
    Ix,Iy,Iz,Ixz=12874.8,75673.6,85552.1,1331.4;d=Ix*Iz-Ixz**2
    return np.array([9295.44,9.80665,27.87,3.45,9.144,.35,.30,
        ((Iy-Iz)*Iz-Ixz**2)/d,(Ix-Iy+Iz)*Ixz/d,Iz/d,Ixz/d,
        (Iz-Ix)/Iy,Ixz/Iy,1/Iy,(Ix*(Ix-Iy)+Ixz**2)/d,Ix/d,216.9,0,0])
PAR=parameters()

def atmosphere(h):
    T=288.15-.0065*min(h,11000)
    pres=101325*(T/288.15)**(9.80665/(287.05*.0065))
    if h>11000:pres*=exp(-9.80665*(h-11000)/(287.05*T))
    return T,pres,pres/(287.05*T),sqrt(1.4*287.05*T)

def power_command(throttle):
    if not 0<=throttle<=1:raise ValueError('Throttle fuera de [0,1]')
    return 64.94*throttle if throttle<=.77 else 217.38*throttle-117.38

def engine_rate(P,throttle):
    p1=power_command(throttle)
    if p1<50:
        p2,rate=(p1,None) if P<50 else (40,5.)
    else:p2,rate=(60,None) if P<50 else (p1,5.)
    if rate is None:
        delta=p2-P;rate=1. if delta<25 else (1.9-.036*delta if delta<=50 else .1)
    return rate*(p2-P)

def thrust(P,mach,D):
    h=max(0,-D)*1e-4
    idle=fits.Funcion_Tidle(mach,h);mil=fits.Funcion_Tmil(mach,h);mx=fits.Funcion_Tmax(mach,h)
    return idle+(mil-idle)*P/50 if P<50 else mil+(mx-mil)*(P-50)/50

def quaternion(phi,pitch,psi):
    c=np.cos(np.array([phi,pitch,psi])/2);s=np.sin(np.array([phi,pitch,psi])/2)
    return np.array([c[0]*c[1]*c[2]+s[0]*s[1]*s[2],s[0]*c[1]*c[2]-c[0]*s[1]*s[2],
        c[0]*s[1]*c[2]+s[0]*c[1]*s[2],c[0]*c[1]*s[2]-s[0]*s[1]*c[2]])

def angles(Q,normalize=True):
    Q=np.asarray(Q);Q=Q/np.linalg.norm(Q) if normalize else Q
    w,x,y,z=Q
    return np.array([atan2(2*(w*x+y*z),w*w-x*x-y*y+z*z),
        asin(min(1,max(-1,2*(w*y-x*z)))),atan2(2*(x*y+w*z),w*w+x*x-y*y-z*z)])

def rotation(Q):
    w,x,y,z=Q
    return np.array([[w*w+x*x-y*y-z*z,2*(x*y-w*z),2*(x*z+w*y)],
        [2*(x*y+w*z),w*w-x*x+y*y-z*z,2*(y*z-w*x)],
        [2*(x*z-w*y),2*(y*z+w*x),w*w-x*x-y*y+z*z]])

def pose_enu(Q,pos):
    T=np.eye(4);P=np.array([[0,1,0],[1,0,0],[0,0,-1]])
    Q=np.asarray(Q)/np.linalg.norm(Q);T[:3,:3]=P@rotation(Q);T[:3,3]=P@pos
    return T

def qrate(Q,omega):
    w,x,y,z=Q;p,q,r=omega
    return .5*np.array([-p*x-q*y-r*z,p*w+r*y-q*z,q*w-r*x+p*z,r*w+q*x-p*y])

def angular_rate(omega,F,par):
    p,q,r=omega;N,L,M=F[3:];c1,c2,c3,c4,c5,c6,c7,c8,c9,H=par[7:17]
    return np.array([(c1*r+c2*p)*q+c3*L+c4*(N+q*H),
        c5*p*r-c6*(p*p-r*r)+c7*(M-r*H),(c8*p-c2*r)*q+c4*L+c9*(N+q*H)])

def environment(x,u,par=PAR,gust=None):
    _,ps,rho,sound=atmosphere(-x[14]);V,a,b=x[2:5]
    if gust is not None and V>1:V=V-gust[0];a+=gust[2]/x[2];b+=gust[1]/x[2]
    qb=.5*rho*V*V;lef=min(25,max(0,2.76*a*180/pi-x[1]-9.05*qb/ps+1.45))
    F=loads([V,a,b,*x[5:8]],[*u[:3],qb,lef],par)
    return F,thrust(x[0],x[2]/sound,x[14]),lef,qb,sound,a

def rhs(t,x,u,par=PAR,gust=None):
    x=np.asarray(x);u=np.asarray(u);act=len(x)==18
    ur=np.r_[x[15:18],u[3]] if act else u[:4]
    F,T,lef,qb,sound,aa=environment(x,ur,par,gust)
    V,a,b=x[2:5];p,q,r=x[5:8];fi,pitch,_=angles(x[8:12],normalize=False);m,g=par[:2]
    ca,sa,cb,sb=cos(a),sin(a),cos(b),sin(b);st,ct,sf,cf=sin(pitch),cos(pitch),sin(fi),cos(fi)
    X,Y,Z=F[:3];D=-X*ca*cb-Y*sb-Z*sa*cb;Yw=-X*ca*sb+Y*cb-Z*sa*sb;L=X*sa-Z*ca
    g1=g*(-ca*cb*st+sb*sf*ct+sa*cb*cf*ct)
    g2=g*(ca*sb*st+cb*sf*ct-sa*sb*cf*ct);g3=g*(sa*st+ca*cf*ct)
    d=np.zeros(len(x));d[0]=engine_rate(x[0],ur[3]);d[1]=-7.25*x[1]+10.005*aa*180/pi
    d[2]=(-D+T*ca*cb+m*g1)/m
    if V!=0:
        d[3]=q-(p*ca+r*sa)*tan(b)-(L+T*sa-m*g3)/(m*V*cb)
        d[4]=p*sa-r*ca+(Yw-T*ca*sb+m*g2)/(m*V)
    d[5:8]=angular_rate(x[5:8],F,par);d[8:12]=qrate(x[8:12],x[5:8])
    d[12:15]=rotation(x[8:12])@np.array([V*ca*cb,V*sb,V*sa*cb])
    if act:
        d[15:18]=np.clip(20.2*(np.clip(u[:3],[-25,-21.5,-30],[25,21.5,30])-x[15:18]),[-60,-80,-120],[60,80,120])
    return d

def euler_to_quat(e):return np.r_[e[:8],quaternion(*e[8:11]),e[11:14]]
def quat_to_euler(x):return np.r_[x[:8],angles(x[8:12]),x[12:15]]

def rhs_euler(t,e,u,par=PAR):
    d=rhs(t,euler_to_quat(e),u,par);fi,pitch,_=e[8:11];p,q,r=e[5:8]
    if abs(cos(pitch))<1e-10:raise ValueError('Singularidad de Euler')
    da=[p+tan(pitch)*(q*sin(fi)+r*cos(fi)),q*cos(fi)-r*sin(fi),(q*sin(fi)+r*cos(fi))/cos(pitch)]
    return np.r_[d[:8],da,d[12:15]]

def rhs_body(t,x,u,alfaf,par=PAR):
    """13 estados, sin empuje ni motor; alfaf congelado como modelo_cuerpo.m."""
    V=np.linalg.norm(x[:3]);a=atan2(x[2],x[0]);b=asin(x[1]/V)
    z=np.r_[0,alfaf,V,a,b,x[3:6],x[6:10],x[10:13]]
    F,_,_,_,_,_=environment(z,u,par)
    vel=F[:3]/par[0]+rotation(x[6:10]).T@np.array([0,0,par[1]])-np.cross(x[3:6],x[:3])
    return np.r_[vel,angular_rate(x[3:6],F,par),qrate(x[6:10],x[3:6]),rotation(x[6:10])@x[:3]]

def rkf_step(fun,t,h,x,u,par=PAR):
    k1=h*fun(t,x,u,par);k2=h*fun(t+h/4,x+k1/4,u,par)
    k3=h*fun(t+3*h/8,x+3*k1/32+9*k2/32,u,par)
    k4=h*fun(t+12*h/13,x+1932*k1/2197-7200*k2/2197+7296*k3/2197,u,par)
    k5=h*fun(t+h,x+439*k1/216-8*k2+3680*k3/513-845*k4/4104,u,par)
    # MATLAB computes k6 but advances with fourth-order weights (k6 unused).
    return x+25*k1/216+1408*k3/2565+2197*k4/4104-k5/5
