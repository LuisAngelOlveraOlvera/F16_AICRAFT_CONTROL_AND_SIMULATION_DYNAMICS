"""Guia de posicion: [N,E,D] externo, [N,E,h] interno; waypoints de paso."""
import numpy as np

def wrap(a):return np.arctan2(np.sin(a),np.cos(a))

def guide(pos_ned,w,segment,V,lookahead=2000,radius=250):
    p=np.asarray(pos_ned,float).copy();p[2]*=-1;n=len(w);segment=min(n-2,max(0,segment))
    while segment<n-2:
        v=w[segment+1,:2]-w[segment,:2];s=np.dot(p[:2]-w[segment,:2],v)/np.dot(v,v)
        if s>=1 or np.linalg.norm(p[:2]-w[segment+1,:2])<radius:segment+=1
        else:break
    v=w[segment+1,:2]-w[segment,:2];s=np.clip(np.dot(p[:2]-w[segment,:2],v)/np.dot(v,v),0,1)
    q=w[segment]+s*(w[segment+1]-w[segment]);aim=q.copy();left=lookahead;j=segment
    while left>0 and j<n-1:
        d=np.linalg.norm(w[j+1,:2]-aim[:2])
        if d>=left:aim+=(left/d)*(w[j+1]-aim);left=0
        else:left-=d;aim=w[j+1].copy();j+=1
    delta=aim[:2]-p[:2]
    if np.linalg.norm(delta)<1:delta=v
    u=np.array([aim[2],V,np.arctan2(delta[1],delta[0])]);err=np.inf
    for i in range(n-1):
        dv=w[i+1]-w[i];s=np.clip(np.dot(p-w[i],dv)/np.dot(dv,dv),0,1)
        err=min(err,np.linalg.norm(p-w[i]-s*dv))
    dist=np.linalg.norm(p-w[-1])
    return u,{'tramo':segment,'error_transversal_m':np.linalg.norm(p[:2]-q[:2]),
        'error_espacial_m':err,'distancia_final_m':dist,'finalizado':segment==n-2 and dist<=radius}
