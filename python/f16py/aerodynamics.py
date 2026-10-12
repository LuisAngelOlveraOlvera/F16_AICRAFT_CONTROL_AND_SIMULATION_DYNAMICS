"""Cargas de hu.m y C*t.m; angulos rad, mandos y LEF grados, salida X,Y,Z,N,L,M."""
from math import pi
import numpy as np
from . import fits as f

def coefficients(V,a,b,p,q,r,de,da,dr,lef,cbar=3.45,span=9.144,cgr=.35,cg=.30):
    if V==0: return np.zeros(6)
    a=a*180/pi;b=b*180/pi;le=1-lef/25
    qh=q*cbar/(2*V);ph=p*span/(2*V);rh=r*span/(2*V)
    cx=f.Cx(a,b,de)+f.dCxlef(a,b)*le+qh*(f.Cxq(a)+f.dCxqlef(a)*le)
    cz=f.Cz(a,b,de)+f.dCzlef(a,b)*le+qh*(f.Czq(a)+f.dCzqlef(a)*le)
    cy=f.Cy(a,b)-f.Cy(a,0)+(f.dCylef(a,b)-f.dCylef(a,0))*le
    cy+=(f.dCyda(a,b)+f.dCydalef(a,b)*le)*da/21.5+f.dCydr(a,b)*dr/30
    cy+=rh*(f.Cyr(a)+f.dCyrlef(a)*le)+ph*(f.Cyp(a)+f.dCyplef(a)*le)
    cl=f.Cl(a,b,de)-f.Cl(a,0,de)+(f.dCllef(a,b)-f.dCllef(a,0))*le
    cl+=(f.dClda(a,b)+f.dCldalef(a,b)*le)*da/21.5+f.dCldr(a,b)*dr/30
    cl+=rh*(f.Clr(a)+f.dClrlef(a)*le)+ph*(f.Clp(a)+f.dClplef(a)*le)+f.dClb(a)*b
    cm=f.Cm(a,b,de)+cz*(cgr-cg)+f.dCmlef(a,b)*le
    cm+=qh*(f.Cmq(a)+f.dCmqlef(a)*le)+f.dCm(a)+f.dCmds(a,de)
    cn=f.Cn(a,b,de)-f.Cn(a,0,de)+(f.dCnlef(a,b)-f.dCnlef(a,0))*le
    cn-=cy*(cgr-cg)*cbar/span
    cn+=(f.dCnda(a,b)+f.dCndalef(a,b)*le)*da/21.5+f.dCndr(a,b)*dr/30
    cn+=rh*(f.Cnr(a)+f.dCnrlef(a)*le)+ph*(f.Cnp(a)+f.dCnplef(a)*le)+f.dCnb(a)*b
    return np.array([cx,cy,cz,cn,cl,cm])

def loads(x,u,par):
    # x=[V,a,b,p,q,r], u=[de,da,dr,qbar,lef]
    c=coefficients(*x,*u[:3],u[4],cbar=par[3],span=par[4],cgr=par[5],cg=par[6])
    return c*u[3]*par[2]*np.array([1,1,1,par[4],par[4],par[3]])
