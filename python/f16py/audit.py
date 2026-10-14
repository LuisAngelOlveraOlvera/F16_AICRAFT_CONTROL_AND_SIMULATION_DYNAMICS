"""Auditorías nativas: Lewis, inercias, coordenadas y sensibilidad; sin ajuste."""
from pathlib import Path
import numpy as np
from scipy.linalg import eig
from . import fits as f
from .control import trim,jacobian,linearize,compare_lewis,LEWIS_LATERAL
from .dynamics import (PAR,rhs,rhs_euler,rhs_body,rkf_step,quat_to_euler,
    euler_to_quat,environment,quaternion,rotation,engine_rate,atmosphere,thrust)

def fd(fun,x,h=1e-5,order=4):return jacobian(fun,x,h,order)
def spiral(A):
    z=np.linalg.eigvals(A);z=z[abs(z.imag)<1e-8]
    if not len(z):raise ValueError('No hay modo real')
    return float(z[np.argmin(abs(z))].real)

def equilibrium(e,u):
    d=rhs_euler(0,e,u)
    return {'Xe':e.copy(),'U4':u.copy(),'residuo_completo':d,'residuo_dinamico':d[:8],
        'max_residuo_dinamico':float(max(abs(d[:8]))),'valido':bool(max(abs(d[:8]))<1e-6)}

def to_body(e):
    V,a,b=e[2:5]
    return np.r_[V*np.array([np.cos(a)*np.cos(b),np.sin(b),np.sin(a)*np.cos(b)]),
        e[5:8],quaternion(*e[8:11]),e[11:14],e[:2]]

def body_complete(t,b,u,par=PAR):
    d=rhs_body(t,b[:13],u,b[14],par);V=np.linalg.norm(b[:3]);a=np.arctan2(b[2],b[0])
    d[0]+=thrust(b[13],V/atmosphere(-b[12])[3],b[12])/par[0]
    return np.r_[d,engine_rate(b[13],u[3]),-7.25*b[14]+10.005*np.degrees(a)]

def phi_dot(q,d):
    w,x,y,z=q;dw,dx,dy,dz=d;n=2*(w*x+y*z);b=w*w-x*x-y*y+z*z
    dn=2*(dw*x+w*dx+dy*z+y*dz);db=2*(w*dw-x*dx-y*dy+z*dz)
    return (b*dn-n*db)/(n*n+b*b)

def lateral_euler(z,e,u):
    e=e.copy();e[[4,8,5,7]]=z;return rhs_euler(0,e,u)[[4,8,5,7]]
def lateral_quat(z,x,u):
    x=x.copy();pitch=quat_to_euler(x)[9];x[[4,5,7]]=z[[0,2,3]];x[8:12]=quaternion(z[1],pitch,0)
    d=rhs(0,x,u);return np.array([d[4],phi_dot(x[8:12],d[8:12]),d[5],d[7]])
def lateral_body(z,x,u):
    e=quat_to_euler(x);e[[4,8,5,7]]=z;b=to_body(e);d=body_complete(0,b,u)
    dv=b[:3]@d[:3]/x[2];db=(d[1]-np.sin(z[0])*dv)/(x[2]*np.cos(z[0]))
    return np.array([db,phi_dot(b[6:10],d[6:10]),d[3],d[5]])

def decompose(x,u):
    _,ps,rho,_=atmosphere(-x[14]);V=x[2];ad=np.degrees(x[3]);qb=.5*rho*V*V
    lef=environment(x,u)[2];k=1-lef/25;r2d=180/np.pi;cg=(PAR[5]-PAR[6])*PAR[3]/PAR[4]
    # Scalar fits enforce float inputs; symmetric FD in degrees replaces complex step.
    def db(fun):return (fun(ad,1e-4)-fun(ad,-1e-4))/(2e-4)
    cy=r2d*np.array([db(f.Cy),k*db(f.dCylef)])
    cl=r2d*np.array([db(lambda a,b:f.Cl(a,b,u[0])),k*db(f.dCllef),f.dClb(ad)])
    cn=np.array([r2d*db(lambda a,b:f.Cn(a,b,u[0])),r2d*k*db(f.dCnlef),r2d*f.dCnb(ad),-cg*sum(cy)])
    clp=np.array([f.Clp(ad),k*f.dClplef(ad)]);clr=np.array([f.Clr(ad),k*f.dClrlef(ad)])
    cyp=np.array([f.Cyp(ad),k*f.dCyplef(ad)]);cyr=np.array([f.Cyr(ad),k*f.dCyrlef(ad)])
    cnp=np.array([f.Cnp(ad),k*f.dCnplef(ad),-cg*sum(cyp)]);cnr=np.array([f.Cnr(ad),k*f.dCnrlef(ad),-cg*sum(cyr)])
    Cl=np.array([sum(cl),sum(clp),sum(clr)]);Cn=np.array([sum(cn),sum(cnp),sum(cnr)]);Cy=np.array([sum(cy),sum(cyp),sum(cyr)])
    mom=qb*PAR[2]*PAR[4]*np.array([Cl,Cn])@np.diag([1,PAR[4]/(2*V),PAR[4]/(2*V)])
    mix=np.array([[PAR[9],PAR[10]],[PAR[10],PAR[15]]])
    return dict(qbar=qb,LEF=lef,Cy_beta_parts=cy,Cl_beta_parts=cl,Cn_beta_parts=cn,
        Cl_p_parts=clp,Cl_r_parts=clr,Cy_p_parts=cyp,Cy_r_parts=cyr,Cn_p_parts=cnp,Cn_r_parts=cnr,
        Cl=Cl,Cn=Cn,Cy=Cy,moment_derivatives=mom,inertia_mix=mix,rotational=mix@mom,
        roll_from_L=PAR[9]*mom[0],roll_from_N=PAR[10]*mom[1],yaw_from_L=PAR[10]*mom[0],yaw_from_N=PAR[15]*mom[1],
        sideforce_derivatives=qb*PAR[2]*Cy@np.diag([1,PAR[4]/(2*V),PAR[4]/(2*V)]))

def assemble(d,e,dV):
    V,a=e[2:4];pitch=e[9];m,g=PAR[:2];Y=d['sideforce_derivatives'];A=np.zeros((4,4))
    A[0]=[Y[0]/(m*V)-dV/V,g*np.cos(pitch)/V,np.sin(a)+Y[1]/(m*V),-np.cos(a)+Y[2]/(m*V)]
    A[1]=[0,0,1,np.tan(pitch)];A[np.ix_([2,3],[0,2,3])]=d['rotational'];return A

def extract(Aq,dq,pitch):
    indices=[4,None,5,7];col=Aq[:,8:12]@dq;A=np.zeros((4,4))
    for i,fr in enumerate(indices):
        if fr is None:A[i]=[0,0,1,np.tan(pitch)]
        else:
            for j,fc in enumerate(indices):A[i,j]=col[fr] if fc is None else Aq[fr,fc]
    return A

def spiral_evidence(A):
    lam=spiral(A);t=A[1,3];K=A[2,0]*(A[3,3]-t*A[3,2])-A[3,0]*(A[2,3]-t*A[2,2])
    vals,left,right=eig(A,left=True,right=True);i=np.argmin(abs(vals-lam));v=right[:,i];w=left[:,i]
    return dict(lambda_=lam,K=K,det=np.linalg.det(A),det_from_K=A[0,1]*K,
        eigenvector=v/v[1],entry_sensitivity=np.real(np.outer(np.conj(w),v)/(np.conj(w)@v)),
        doubling_or_decay_s=np.log(2)/abs(lam))

def book_lateral(alpha,weight=20500,Ix=9496):
    a=np.degrees(alpha);V=502;qb=.5*.002377*V**2;S=300;b=30;g=32.17;mass=weight/g;Iz=63100;Ixz=982
    r2d=57.29578;cyb=-.02*r2d;clb=r2d*(-.008-.004*a/5)/5;cnb=r2d*(.018+.001*a/5)/5
    clp=-.443+.023*a/5;clr=.063+.050*a/5;cnp=.052-.064*a/5;cnr=-.378-.008*a/5
    cyp=-.188+.298*a/5;cyr=.876+.082*a/5;cg=.05*11.32/b
    Cl=np.array([clb,clp,clr]);Cy=np.array([cyb,cyp,cyr]);Cn=np.array([cnb,cnp,cnr])-cg*Cy
    mom=qb*S*b*np.array([Cl,Cn])@np.diag([1,b/(2*V),b/(2*V)])
    rot=np.array([[Iz,Ixz],[Ixz,Ix]])/(Ix*Iz-Ixz**2)@mom;A=np.zeros((4,4))
    A[0]=[qb*S*cyb/(mass*V),g*np.cos(alpha)/V,np.sin(alpha)+qb*S*cyp*b/(2*mass*V**2),-np.cos(alpha)+qb*S*cyr*b/(2*mass*V**2)]
    A[1]=[0,0,1,np.tan(alpha)];A[np.ix_([2,3],[0,2,3])]=rot
    return dict(A=A,poles=np.linalg.eigvals(A),alpha_deg=a,weight_lb=weight,Ix_slugft2=Ix,Cl=Cl,Cn=Cn,Cy=Cy)

def lateral_audit():
    x,u,info=trim(153.0096,0);e=quat_to_euler(x);z=e[[4,8,5,7]];A=fd(lambda v:lateral_euler(v,e,u),z)
    xb=x.copy();xb[3:5]=[.03936,4.1e-9];xb[8:12]=quaternion(0,.03936,0);ub=np.array([-1.931,-7e-8,8.3e-7,.1485])
    from .dynamics import power_command
    xb[0]=power_command(ub[3]);xb[1]=1.38*np.degrees(xb[3]);eb=quat_to_euler(xb)
    Ab=fd(lambda v:lateral_euler(v,eb,ub),eb[[4,8,5,7]])
    d=decompose(x,u);manual=assemble(d,e,rhs(0,x,u)[2]);Aq=fd(lambda v:rhs(0,v,u),x)
    good=np.array([0,.5*np.cos(e[9]/2),0,-.5*np.sin(e[9]/2)]);bad=good.copy();bad[3]*=-1
    Ag=extract(Aq,good,e[9]);Aw=extract(Aq,bad,e[9]);sensitivity=[]
    for h in 10.**np.arange(-2,-11,-1):
        A2=fd(lambda v:lateral_euler(v,e,u),z,h,2);A4=fd(lambda v:lateral_euler(v,e,u),z,h,4)
        sensitivity.append(dict(h=h,A2=A2,A4=A4,max_error2=np.max(abs(A2-manual)),max_error4=np.max(abs(A4-manual)),
            spiral2=spiral(A2),spiral4=spiral(A4),euler_quaternion_max=np.max(abs(A4-fd(lambda v:lateral_quat(v,x,u),z,h))),
            euler_body_max=np.max(abs(A4-fd(lambda v:lateral_body(v,x,u),z,h)))))
    ztest=np.array([.02,.1,.03,-.02]);ref=LEWIS_LATERAL;relative=np.full_like(ref,np.nan)
    np.divide(100*abs(A-ref),abs(ref),out=relative,where=ref!=0)
    Ae=fd(lambda v:rhs_euler(0,v,u),e);poles=np.linalg.eigvals(Ae[:10,:10]);no=PAR.copy();no[16]=0
    pn=np.linalg.eigvals(fd(lambda v:rhs_euler(0,v,u,no),e)[:10,:10]);book=book_lateral(.03936)
    alt=[];gam=[]
    for h in [0,1000,3000]:
        xc,uc,ic=trim(153.0096,h);ec=quat_to_euler(xc);ac=fd(lambda v:lateral_euler(v,ec,uc),ec[[4,8,5,7]])
        alt.append(dict(altitude_m=h,alpha_deg=ic['alfa_deg'],de_deg=uc[0],throttle=uc[3],spiral=spiral(ac)))
    for g in [-5,0,5]:
        from .control import _trim
        xc,uc,ic=_trim(153.0096,0,g,0);ec=quat_to_euler(xc);ac=fd(lambda v:lateral_euler(v,ec,uc),ec[[4,8,5,7]])
        gam.append(dict(gamma_deg=g,converge=ic['converge'],residuo=ic['residuo'],alpha_deg=ic['alfa_deg'],pitch_deg=np.degrees(ec[9]),
            spiral=spiral(ac),etiqueta='Modo de trim' if ic['converge'] else 'Snapshot fuera de equilibrio'))
    return dict(source='Stevens, Lewis, Johnson 2015: PDF p209/p221; impresas 195/207',X=x,U=u,Xe=e,trim=info,
        residual=rhs(0,x,u),verified_reference=ref,book_point_in_local_model=dict(X=xb,U=ub,residual=rhs(0,xb,ub),A=Ab,
            etiqueta='Snapshot fuera de equilibrio; polos no etiquetados como modos sostenidos'),
        condition_component=A-Ab,remaining_model_component=Ab-ref,
        comparison=dict(A=A,reference=ref,signed_error=A-ref,absolute_error=abs(A-ref),relative_percent=relative,
            model_poles=np.linalg.eigvals(A),reference_matrix_poles=np.linalg.eigvals(ref)),
        decomposition=d,manual_A=manual,manual_vs_fd_max=np.max(abs(manual-A)),sensitivity=sensitivity,
        extraction=dict(A_bad=Aw,A_good=Ag,bad_vs_euler=np.max(abs(Aw-A)),good_vs_euler=np.max(abs(Ag-A)),
            spiral_bad=spiral(Aw),spiral_good=spiral(Ag)),
        formulations=dict(quat_vs_euler=np.max(abs(lateral_quat(ztest,x,u)-lateral_euler(ztest,e,u))),
            body_vs_euler=np.max(abs(lateral_body(ztest,x,u)-lateral_euler(ztest,e,u)))),
        full_dynamic_poles=poles,full_dynamic_nearest_spiral=poles[np.argmin(abs(poles-spiral(A)))],
        no_engine_gyro_poles=pn,no_engine_gyro_spiral=pn[np.argmin(abs(pn-spiral(A)))],
        spiral_local=spiral_evidence(A),spiral_reference=spiral_evidence(ref),reduced_book_at_book_alpha=book,
        reduced_book_at_local_alpha=book_lateral(x[3]),reduced_book_appendix_Ix=book_lateral(.03936,20500,9456),
        reduced_book_figure_weight=book_lateral(.03936,25000,9496),book_reconstruction_max=np.max(abs(book['A']-ref)),
        parameters_comparison=dict(repo_mass_slug=PAR[0]/14.5939029372,
            repo_inertia_slugft2=np.array([12874.8,75673.6,85552.1,1331.4])/1.3558179483,
            repo_geometry_imperial=np.array([PAR[2]/.3048**2,PAR[4]/.3048,PAR[3]/.3048]),book_g_SI=32.17*.3048,repo_g=PAR[1]),
        control_derivatives=fd(lambda v:rhs_euler(0,e,v),u)[np.ix_([6,5,7],[0,1,2])],altitude_sweep=alt,gamma_sweep=gam)

def matrices9(e,u):
    A,B,C,D=linearize(e,u,'euler',1e-5,4);idx=[2,3,9,6,0,4,8,5,7];S=np.diag([1/.3048]+[1]*8);Si=np.linalg.inv(S)
    return dict(A9=S@A[np.ix_(idx,idx)]@Si,B9=S@B[np.ix_(idx,[3,0,1,2])],C9=C[:,idx]@Si,D9=D[:,[3,0,1,2]])

def standard_audit(lat=None):
    lat=lateral_audit() if lat is None else lat;x,u,e=lat['X'],lat['U'],lat['Xe'];b=to_body(e)
    Ae=fd(lambda z:rhs_euler(0,z,u),e);Aq=fd(lambda z:rhs(0,z,u),x);Ab=fd(lambda z:body_complete(0,z,u),b)
    Be=fd(lambda v:rhs_euler(0,e,v),u);Bq=fd(lambda v:rhs(0,x,v),u);Bb=fd(lambda v:body_complete(0,b,v),u)
    Gq=fd(euler_to_quat,e);Gb=fd(to_body,e);v=dict(covarianza_A_quat=np.max(abs(Aq@Gq-Gq@Ae)),
        covarianza_A_cuerpo=np.max(abs(Ab@Gb-Gb@Ae)),covarianza_B_quat=np.max(abs(Bq-Gq@Be)),covarianza_B_cuerpo=np.max(abs(Bb-Gb@Be)))
    errors=[];ne=[];cases=[];I=np.array([[12874.8,0,-1331.4],[0,75673.6,0],[-1331.4,0,85552.1]])
    for k in range(1,9):
        ec=e.copy();ec[2:5]=[145+5*k,.03+.006*k,(-1)**k*.008*k];ec[5:8]=[.025*k,-.013*k,.019*k]
        ec[8:11]=[.03*k,-.02*k,.04*k];ec[13]=-500*k;ec[0]=10+2*k;ec[1]=1.38*np.degrees(ec[3])-.1*k
        uc=np.array([-2+.15*k,.3*k,-.4*k,.1+.02*k]);q=euler_to_quat(ec);bc=to_body(ec);dq=rhs(0,q,uc);de=rhs_euler(0,ec,uc);db=body_complete(0,bc,uc)
        err=max(np.max(abs(dq-fd(euler_to_quat,ec)@de)),np.max(abs(db-fd(to_body,ec)@de)));errors.append(err)
        F,T,lef,qb,*_=environment(q,uc);omega=ec[5:8];R=rotation(q[8:12]);gyro=-np.cross(omega,[PAR[16],0,0])
        acceleration=(F[:3]+[T,0,0])/PAR[0]+R.T@np.array([0,0,PAR[1]])-np.cross(omega,bc[:3])
        angular=np.linalg.solve(I,F[[4,5,3]]-np.cross(omega,I@omega)+gyro)
        nv=max(np.max(abs(acceleration-db[:3])),np.max(abs(angular-de[5:8])));ne.append(nv)
        cases.append(dict(Xe=ec,U4=uc,error_identidad=err,error_newton_euler=nv,cargas=dict(fuerzas=F[:3],momentos_LMN=F[[4,5,3]],empuje=T,gravedad_cuerpo=R.T@[0,0,PAR[1]],qbar=qb,LEF=lef,acceleration=acceleration,angular_acceleration=angular)))
    ei=e.copy();ei[[3,4,5,6,7,8,9,10]]+=np.array([.015,-.01,.025,-.015,.02,.08,-.03,.11]);ei[13]=-1000
    qi=euler_to_quat(ei);bi=to_body(ei);normerr=0.
    for k in range(250):
        ei=rkf_step(rhs_euler,k*.002,.002,ei,u);qi=rkf_step(rhs,k*.002,.002,qi,u);bi=rkf_step(body_complete,k*.002,.002,bi,u)
        normerr=max(normerr,abs(np.linalg.norm(qi[8:12])-1))
    x18=np.r_[x,u[:3]];A18=fd(lambda z:rhs(0,z,u),x18);B18=fd(lambda z:rhs(0,x18,z),u)
    ae=max(np.max(abs(rhs(0,x18,u)[:15]-rhs(0,x,u))),np.max(abs(A18[:15,:15]-Aq)),np.max(abs(A18[:15,15:]-Bq[:,:3])),
        np.max(abs(A18[15:,15:]+20.2*np.eye(3))),np.max(abs(B18[15:,:3]-20.2*np.eye(3))),np.max(abs(B18[:15,:3])))
    G18=np.zeros((18,17));G18[:15,:14]=Gq;G18[15:,14:]=np.eye(3);A17=np.linalg.lstsq(G18,A18@G18,rcond=None)[0]
    v.update(max_identidad_no_lineal=max(errors),max_newton_euler=max(ne),integracion_quat_euler=np.max(abs(qi-euler_to_quat(ei))),
        integracion_cuerpo_euler=np.max(abs(bi-to_body(ei))),max_deriva_norma_quat=normerr,error_actuadores=ae,covarianza_actuadores=np.max(abs(A18@G18-G18@A17)))
    dh=.01;ep=e.copy();em=e.copy();ep[13]=-dh;em[13]=dh;f0=rhs_euler(0,e,u);right=(rhs_euler(0,ep,u)-f0)/dh;left=(f0-rhs_euler(0,em,u))/dh
    altA=Ae.copy();epp=ep.copy();epp[13]=-2*dh;altA[:,13]=-(-3*f0+4*rhs_euler(0,ep,u)-rhs_euler(0,epp,u))/(2*dh)
    et=e.copy();et[3:11]=[.2485,.00048,-.01555,.2934,.06071,1.367,.05185,0];ut=np.array([-6.256,.09891,-.4218,.8499])
    from .dynamics import power_command
    et[0]=power_command(ut[3]);et[1]=1.38*np.degrees(et[3]);turn=equilibrium(et,ut);turn.update(matrices9(et,ut))
    mats=dict(A14=Ae,B14=Be,A15=Aq,B15=Bq,A_cuerpo15=Ab,B_cuerpo15=Bb,A18=A18,B18=B18,A_actuadores_fisicos17=A17,
        G_quat15_euler14=Gq,G_cuerpo15_euler14=Gb,A13_auxiliar=fd(lambda z:rhs_body(0,z,u,x[1]),b[:13]),A14_altitud_positiva=altA)
    mats.update(matrices9(e,u));poles=np.linalg.eigvals(Ae)
    return dict(auditoria_lateral=lat,propio_trim=equilibrium(e,u),punto_lewis_en_modelo_local=equilibrium(quat_to_euler(lat['book_point_in_local_model']['X']),lat['book_point_in_local_model']['U']),
        verificacion=v,matrices=mats,casos_combinados=cases,polos14=poles,polos17=np.linalg.eigvals(A17),polos_espiral=poles[np.argmin(abs(poles-spiral(lat['comparison']['A'])))],
        altitud_frontera=dict(derivada_h_positiva=right,derivada_h_negativa=left,max_diferencia=np.max(abs(right-left)),no_diferenciable=bool(np.max(abs(right-left))>1e-5)),
        viraje_lewis_en_modelo_local=turn,pull_up=dict(estado='NO_EVALUADO_MANDO_FUERA_DE_DOMINIO',throttle_publicado=1.023,dominio_local=[0,1]))

def sensitivity_audit(r=None):
    r=standard_audit() if r is None else r;x=r['propio_trim']['Xe'].copy();x[13]=-1000;u=r['propio_trim']['U4'];fun=lambda z:rhs_euler(0,z,u)
    ref=fd(fun,x);steps=[]
    for h in 10.**np.arange(-2,-11,-1):
        a2=fd(fun,x,h,2);a4=fd(fun,x,h,4);steps.append(dict(h_relativo=h,A2=a2,A4=a4,max_diferencia2=np.max(abs(a2-ref)),max_diferencia4=np.max(abs(a4-ref))))
    return dict(Xe=x,U4=u,residuo=fun(x),referencia_numerica=ref,pasos=steps,etiqueta='Snapshot interior, no modos de vuelo sostenido')

def source_audit(path=None):
    from .xlsx_source import sheet_cells
    import hashlib
    path=Path(path) if path else Path(__file__).resolve().parents[1]/'references'/'Tablas 2.xlsx'
    if not path.is_file():path=Path(__file__).resolve().parents[1]/'datos_locales'/'Tablas 2.xlsx'
    if not path.is_file():raise FileNotFoundError('Auditoria opcional: falta datos_locales/Tablas 2.xlsx; ver ../docs/DATOS_Y_FUENTES.md')
    names=['Cmq','dCm','Cnr','dCnrlef','Cnp','dCnplef','Clp','dClplef','Cyr','dCyrlef','Cyp','dCyplef']
    at=trim(153.0096,0)[2]['alfa_deg'];items=[]
    for name in names:
        cells=sheet_cells(path,name);cols=[1,2] if name in ('Cmq','dCm') else [2,3];rows=[];xx=[];yy=[]
        for row in range(1,121):
            a=cells.get((row,cols[0]));b=cells.get((row,cols[1]))
            if isinstance(a,(int,float)) and isinstance(b,(int,float)) and np.isfinite([a,b]).all():rows.append(row);xx.append(a);yy.append(b)
        xx=np.array(xx);yy=np.array(yy);rows=np.array(rows);idx=np.argsort(xx);xx=xx[idx];yy=yy[idx];rows=rows[idx]
        if len(xx)<3 or len(np.unique(xx))!=len(xx):raise ValueError('Eje incompleto/duplicado: '+name)
        fun=getattr(f,name);pred=np.array([fun(z) for z in xx]);err=pred-yy;local=fun(at)
        def interp(a):return np.interp(a,xx,yy) if xx[0]<=a<=xx[-1] else np.nan
        source=interp(at);pct=np.full_like(yy,np.nan);np.divide(100*abs(err),abs(yy),out=pct,where=yy!=0)
        items.append(dict(hoja=name,filas=rows,columnas=cols,alfa_deg=xx,dato=yy,ajuste=pred,error=err,error_porcentaje=pct,
            rmse=np.sqrt(np.mean(err**2)),mae=np.mean(abs(err)),max_error_absoluto=max(abs(err)),valor_trim_ajuste=local,
            valor_trim_hoja_interpolado=source,diferencia_trim=local-source,pendiente_trim_ajuste_por_grado=(fun(at+1e-4)-fun(at-1e-4))/2e-4,
            pendiente_trim_hoja_por_grado=(interp(at+1e-4)-interp(at-1e-4))/2e-4,signo_distinto_trim=bool(np.sign(local)!=np.sign(source))))
    return dict(fuente=str(path),sha256=hashlib.sha256(path.read_bytes()).hexdigest(),estado_fidelidad='NO_VERIFICADA',alfa_trim_deg=at,hojas=items,
        supuestos='Cmq/dCm A/B; otras B/C; alfa grados; LEF/procedencia no verificados')
