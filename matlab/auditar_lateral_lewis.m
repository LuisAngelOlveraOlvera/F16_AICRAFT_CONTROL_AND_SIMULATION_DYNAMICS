function audit = auditar_lateral_lewis(outdir)
% AUDITAR_LATERAL_LEWIS  Auditoria reproducible, sin editar el modelo.
%   audit = auditar_lateral_lewis; % solo calcula y devuelve evidencia
%   audit = auditar_lateral_lewis('carpeta_nueva'); % JSON/MAT nuevos
% Fuente: libro local 2015, tabla 3.6-3, ejemplo 3.8-2, apendice A.
% La referencia original de validar_lewis se conserva y se audita aparte.
% Los escenarios son diagnosticos, no ganancias/coefs ajustados para encajar.
if nargin<1, outdir=''; end
if ~isempty(outdir)
    assert(~exist(outdir,'file') && ~exist(outdir,'dir'), ...
        'audit_lewis:Exists','La carpeta de salida debe ser nueva.');
end
r=validar_lewis(struct('mostrar',false));
x=r.Xtrim; u=r.Utrim; theta=r.theta; xe=euler_de(x);
ref=r.lateral.A_referencia;
ref(4,4)=-0.49849; % correccion SOLO en esta auditoria, no en validar_lewis
audit.matlab=version;
audit.source='Stevens, Lewis, Johnson 2015: PDF p209/p221; impresas 195/207';
audit.original_reference=r.lateral.A_referencia;
audit.verified_reference=ref;
audit.original=r;
audit.Xe=xe;
audit.residual=funciones(0,x,u,theta);
audit.trim_general=struct;
[xg,ug,ig]=trim_vuelo(x(3),0,0,0,theta);
audit.trim_general.X=xg; audit.trim_general.U=ug; audit.trim_general.info=ig;
audit.trim_general.max_state_difference=max(abs(xg-x));
audit.book_point=struct('V_ft_s',502,'h_m',0,'alpha_rad',0.03936, ...
    'theta_rad',0.03936,'beta_rad',4.1e-9,'throttle',0.1485, ...
    'de_deg',-1.931,'da_deg',-7.0e-8,'dr_deg',8.3e-7,'cg',0.30);
bp=audit.book_point;
xb=x; xb(4)=bp.alpha_rad; xb(5)=bp.beta_rad;
xb(9:12)=quat_zyx(0,bp.theta_rad,0);
ub=[bp.de_deg;bp.da_deg;bp.dr_deg;bp.throttle];
xb(1)=Calc_P1(ub(4)); xb(2)=1.38*xb(4)*180/pi;
audit.book_point_in_local_model.X=xb;
audit.book_point_in_local_model.U=ub;
audit.book_point_in_local_model.residual=funciones(0,xb,ub,theta);
Ab=fd(@(z) lateral_euler(z,euler_de(xb),ub,theta), ...
    [xb(5);0;xb(6);xb(8)],1e-5,4);
audit.book_point_in_local_model.A=Ab;
audit.book_point_in_local_model.poles=eig(Ab);
A=r.lateral.A_modelo;
audit.condition_component=A-Ab;
audit.remaining_model_component=Ab-ref;
assert(max(abs((A-ref)-audit.condition_component-audit.remaining_model_component),[],'all')<1e-12);
audit.comparison=struct('A',A,'reference',ref,'signed_error',A-ref, ...
    'absolute_error',abs(A-ref),'relative_percent',100*abs(A-ref)./abs(ref), ...
    'model_poles',eig(A),'reference_matrix_poles',eig(ref), ...
    'printed_poles',r.lateral.polos.referencia);
audit.comparison.relative_percent(ref==0)=NaN;
audit.decomposition=decompose(x,u,theta);
audit.manual_A=assemble(audit.decomposition,xe,theta,audit.residual(3));
audit.manual_vs_fd_max=max(abs(audit.manual_A-A),[],'all');
assert(audit.manual_vs_fd_max<1e-7,'audit_lewis:Assembly','Descomposicion no coincide con FD.');
steps=10.^(-2:-1:-10); z0=[x(5);xe(9);x(6);x(8)];
for k=1:numel(steps)
    s.h=steps(k);
    s.A2=fd(@(z) lateral_euler(z,xe,u,theta),z0,s.h,2);
    s.A4=fd(@(z) lateral_euler(z,xe,u,theta),z0,s.h,4);
    s.max_error2=max(abs(s.A2-audit.manual_A),[],'all');
    s.max_error4=max(abs(s.A4-audit.manual_A),[],'all');
    s.spiral2=spiral(s.A2); s.spiral4=spiral(s.A4);
    s.euler_quaternion_max=max(abs(s.A4-fd(@(z) lateral_quat(z,x,u,theta),z0,s.h,4)),[],'all');
    s.euler_body_max=max(abs(s.A4-fd(@(z) lateral_body(z,x,u,theta),z0,s.h,4)),[],'all');
    audit.sensitivity(k)=s; %#ok<AGROW>
end
[Aq,~]=linmod_fd(0,x,u,theta);
pitch=xe(10);
bad=[0;0.5*cos(pitch/2);0;0.5*sin(pitch/2)];
good=[0;0.5*cos(pitch/2);0;-0.5*sin(pitch/2)];
maps=[5 0 6 8];
audit.extraction.A_bad=extract_quat(Aq,maps,bad,pitch);
audit.extraction.A_good=extract_quat(Aq,maps,good,pitch);
audit.extraction.bad_vs_euler=max(abs(audit.extraction.A_bad-A),[],'all');
audit.extraction.good_vs_euler=max(abs(audit.extraction.A_good-A),[],'all');
audit.extraction.spiral_bad=spiral(audit.extraction.A_bad);
audit.extraction.spiral_good=spiral(audit.extraction.A_good);
audit.extraction.dq_bad=bad; audit.extraction.dq_good=good;
assert(audit.extraction.good_vs_euler<1e-7);
[Ass,~,~,~,iss]=modelo_ss('lateral',x(3),0,theta);
audit.extraction.modelo_ss_reordered=Ass([1 4 2 3],[1 4 2 3]);
audit.extraction.modelo_ss_trim=iss.trim;
audit.extraction.modelo_ss_vs_bad=max(abs(audit.extraction.modelo_ss_reordered-audit.extraction.A_bad),[],'all');
% Vector de perturbacion de prueba: comprueba transformaciones fuera de cero.
ztest=[0.02;0.1;0.03;-0.02];
audit.formulations.quat_vs_euler=max(abs(lateral_quat(ztest,x,u,theta)-lateral_euler(ztest,xe,u,theta)));
audit.formulations.body_vs_euler=max(abs(lateral_body(ztest,x,u,theta)-lateral_euler(ztest,xe,u,theta)));
assert(audit.formulations.quat_vs_euler<1e-9 && audit.formulations.body_vs_euler<1e-9);
% Modos del bloque de 10 estados dinamicos: motor, LEF, VT,alfa,beta,p,q,r,phi,theta.
audit.full_dynamic_poles=eig(r.A_euler(1:10,1:10));
audit.full_dynamic_nearest_spiral=nearest(audit.full_dynamic_poles,spiral(A));
theta0=theta; theta0(17)=0; % diagnostico giroscopico, no modifica parametros
A0=fd(@(xx) funciones_euler(0,xx,u,theta0),xe,1e-5,4);
audit.no_engine_gyro_poles=eig(A0(1:10,1:10));
audit.no_engine_gyro_spiral=nearest(audit.no_engine_gyro_poles,spiral(A));
audit.spiral_local=spiral_evidence(A);
audit.spiral_reference=spiral_evidence(ref);
% reconstruccion INDEPENDIENTE con tablas reducidas del libro (no fits del repo)
audit.reduced_book_at_book_alpha=book_lateral(bp.alpha_rad,20500,9496);
audit.reduced_book_at_local_alpha=book_lateral(x(4),20500,9496);
audit.reduced_book_appendix_Ix=book_lateral(bp.alpha_rad,20500,9456);
audit.reduced_book_figure_weight=book_lateral(bp.alpha_rad,25000,9496);
audit.book_reconstruction_max=max(abs(audit.reduced_book_at_book_alpha.A-ref),[],'all');
audit.parameters_comparison=struct('repo_mass_slug',theta(1)/14.5939029372, ...
    'repo_inertia_slugft2',[12874.8 75673.6 85552.1 1331.4]/1.3558179483, ...
    'repo_geometry_imperial',[theta(3)/0.3048^2 theta(5)/0.3048 theta(4)/0.3048], ...
    'book_g_SI',32.17*0.3048,'repo_g',theta(2), ...
    'book_rho_SI',0.002377*14.5939029372/0.3048^3);
% Mandos: signos locales, no inferidos de nombres.
B=fd(@(uu) funciones_euler(0,xe,uu,theta),u,1e-5,4);
audit.control_derivatives=B([7 6 8],[1 2 3]);
audit.control_order='rows qdot,pdot,rdot; cols de,da,dr [deg]';
alts=[0 1000 3000];
for k=1:numel(alts)
    rr=validar_lewis(struct('mostrar',false,'altitud_m',alts(k)));
    audit.altitude_sweep(k)=struct('altitude_m',alts(k),'alpha_deg',rr.trim.alfa_deg, ...
        'de_deg',rr.trim.de_deg,'throttle',rr.Utrim(4), ...
        'spiral',spiral(rr.lateral.A_modelo)); %#ok<AGROW>
end
for k=1:3
    gammas=[-5 0 5]; gamma_deg=gammas(k);
    [xc,uc,ic]=trim_vuelo(x(3),0,gamma_deg,0,theta);
    xec=euler_de(xc); Ac=fd(@(z) lateral_euler(z,xec,uc,theta), ...
        [xc(5);xec(9);xc(6);xc(8)],1e-5,4);
    audit.gamma_sweep(k)=struct('gamma_deg',gamma_deg,'converge',ic.converge, ...
        'alpha_deg',ic.alfa_deg,'pitch_deg',ic.teta_deg,'spiral',spiral(Ac)); %#ok<AGROW>
end
fprintf('Auditoria: error descomposicion/FD %.3e; Euler/quat %.3e; Euler/cuerpo %.3e\n', ...
    audit.manual_vs_fd_max,audit.formulations.quat_vs_euler,audit.formulations.body_vs_euler);
fprintf('Espiral: Euler %.10g, extraccion mala %.10g, buena %.10g, modelo completo %.10g\n', ...
    spiral(A),audit.extraction.spiral_bad,audit.extraction.spiral_good,real(audit.full_dynamic_nearest_spiral));
fprintf('Reconstruccion con tablas del libro: max|A-ref| %.6g\n',audit.book_reconstruction_max);
if ~isempty(outdir)
    mkdir(outdir);
    save(fullfile(outdir,'evidencia_auditoria.mat'),'audit');
    f=fopen(fullfile(outdir,'evidencia_auditoria.json'),'w');
    assert(f~=-1,'audit_lewis:IO','No se pudo crear JSON nuevo.');
    cleaner=onCleanup(@() fclose(f)); %#ok<NASGU>
    fwrite(f,jsonencode(real_imag(audit),'PrettyPrint',true),'char');
end
end

function y=lateral_euler(z,xe,u,theta)
xe([5 9 6 8])=z;
d=funciones_euler(0,xe,u,theta); y=d([5 9 6 8]);
end

function y=lateral_quat(z,x,u,theta)
pitch=euler_de(x); pitch=pitch(10);
x([5 6 8])=z([1 3 4]); x(9:12)=quat_zyx(z(2),pitch,0);
d=funciones(0,x,u,theta);
y=[d(5);phi_dot(x(9:12),d(9:12));d(6);d(8)];
end

function y=lateral_body(z,x,u,theta)
e=euler_de(x); a=x(4); V=x(3); beta=z(1);
% modelo_cuerpo omite empuje; a beta=0 eso altera la derivada lateral.
% Se agrega SOLO el empuje axial original para reconstruir la misma fisica.
vel=V*[cos(a)*cos(beta);sin(beta);sin(a)*cos(beta)];
xb=[vel;z(3);x(7);z(4);quat_zyx(z(2),e(10),0);x(13:15)];
d=modelo_cuerpo(0,xb,u,theta,x(2));
[~,~,~,sound]=atmosfera(-x(15)); thrust=FT(x(1),V/sound,x(15));
d(1)=d(1)+thrust/theta(1);
vdot=(vel.'*d(1:3))/V;
bdot=(d(2)-sin(beta)*vdot)/(V*cos(beta));
y=[bdot;phi_dot(xb(7:10),d(7:10));d(4);d(6)];
end

function v=phi_dot(q,dq)
n=2*(q(1)*q(2)+q(3)*q(4)); b=q(1)^2-q(2)^2-q(3)^2+q(4)^2;
dn=2*(dq(1)*q(2)+q(1)*dq(2)+dq(3)*q(4)+q(3)*dq(4));
db=2*(q(1)*dq(1)-q(2)*dq(2)-q(3)*dq(3)+q(4)*dq(4));
v=(b*dn-n*db)/(n*n+b*b);
end

function q=quat_zyx(phi,theta,psi)
c=cos([phi theta psi]/2); s=sin([phi theta psi]/2);
q=[c(1)*c(2)*c(3)+s(1)*s(2)*s(3);s(1)*c(2)*c(3)-c(1)*s(2)*s(3); ...
   c(1)*s(2)*c(3)+s(1)*c(2)*s(3);c(1)*c(2)*s(3)-s(1)*s(2)*c(3)];
end

function e=euler_de(x)
q=x(9:12);
phi=atan2(2*(q(1)*q(2)+q(3)*q(4)),q(1)^2-q(2)^2-q(3)^2+q(4)^2);
theta=asin(max(-1,min(1,2*(q(1)*q(3)-q(2)*q(4)))));
psi=atan2(2*(q(2)*q(3)+q(1)*q(4)),q(1)^2+q(2)^2-q(3)^2-q(4)^2);
e=[x(1:8);phi;theta;psi;x(13:15)];
end

function J=fd(fun,x,h,order)
x=x(:); J=zeros(numel(fun(x)),numel(x));
for j=1:numel(x)
    delta=zeros(size(x)); delta(j)=h*max(1,abs(x(j)));
    if order==2
        J(:,j)=(fun(x+delta)-fun(x-delta))/(2*delta(j));
    else
        J(:,j)=(8*(fun(x+delta)-fun(x-delta))-(fun(x+2*delta)-fun(x-2*delta)))/(12*delta(j));
    end
end
end

function d=decompose(x,u,theta)
[~,ps,rho,~]=atmosfera(-x(15)); V=x(3); a=x(4); ad=a*180/pi;
d.qbar=0.5*rho*V^2; d.LEF=hlef(0,x(2),[a d.qbar ps],theta);
k=1-d.LEF/25; r2d=180/pi; h=1e-20;
db=@(f) imag(f(ad,1i*h))/h;
d.Cy_beta_parts=r2d*[db(@Cy),k*db(@dCylef)];
d.Cl_beta_parts=r2d*[db(@(aa,bb) Cl(aa,bb,u(1))),k*db(@dCllef),dClB(ad)];
cg=(theta(6)-theta(7))*theta(4)/theta(5);
d.Cn_beta_parts=[r2d*db(@(aa,bb) Cn(aa,bb,u(1))),r2d*k*db(@dCnlef), ...
    r2d*dCnB(ad),-cg*sum(d.Cy_beta_parts)];
d.Cl_p_parts=[Clp(ad),k*dClplef(ad)];
d.Cl_r_parts=[Clr(ad),k*dClrlef(ad)];
d.Cy_p_parts=[Cyp(ad),k*dCyplef(ad)];
d.Cy_r_parts=[Cyr(ad),k*dCyrlef(ad)];
d.Cn_p_parts=[Cnp(ad),k*dCnplef(ad),-cg*sum(d.Cy_p_parts)];
d.Cn_r_parts=[Cnr(ad),k*dCnrlef(ad),-cg*sum(d.Cy_r_parts)];
d.Cl=[sum(d.Cl_beta_parts) sum(d.Cl_p_parts) sum(d.Cl_r_parts)];
d.Cn=[sum(d.Cn_beta_parts) sum(d.Cn_p_parts) sum(d.Cn_r_parts)];
d.Cy=[sum(d.Cy_beta_parts) sum(d.Cy_p_parts) sum(d.Cy_r_parts)];
qsb=d.qbar*theta(3)*theta(5); b2v=theta(5)/(2*V);
d.moment_derivatives=qsb*[d.Cl;d.Cn]*diag([1 b2v b2v]);
% rows L,N; cols beta,p,r. beta/radian; p,r physical rad/s.
c3=theta(10); c4=theta(11); c9=theta(16);
d.inertia_mix=[c3 c4;c4 c9];
d.rotational=d.inertia_mix*d.moment_derivatives;
d.roll_from_L=c3*d.moment_derivatives(1,:);
d.roll_from_N=c4*d.moment_derivatives(2,:);
d.yaw_from_L=c4*d.moment_derivatives(1,:);
d.yaw_from_N=c9*d.moment_derivatives(2,:);
d.sideforce_derivatives=d.qbar*theta(3)*d.Cy*diag([1 b2v b2v]);
d.beta_component_order='base, LEF, extra_beta, cg (where applicable)';
d.rate_component_order='base, LEF, cg (where applicable)';
end

function A=assemble(d,xe,theta,dV)
V=xe(3); a=xe(4); pitch=xe(10); m=theta(1); g=theta(2);
A=zeros(4); A(1,:)=[d.sideforce_derivatives(1)/(m*V)-dV/V, ...
    g*cos(pitch)/V,sin(a)+d.sideforce_derivatives(2)/(m*V), ...
    -cos(a)+d.sideforce_derivatives(3)/(m*V)];
A(2,:)=[0 0 1 tan(pitch)];
A([3 4],[1 3 4])=d.rotational;
end

function A=extract_quat(Aq,map,dq,pitch)
col=Aq(:,9:12)*dq; A=zeros(4);
for i=1:4
 if map(i)==0, A(i,:)=[0 0 1 tan(pitch)];
 else
  for j=1:4
   if map(j)==0,A(i,j)=col(map(i));else,A(i,j)=Aq(map(i),map(j));end
  end
 end
end
end

function l=spiral(A)
ev=eig(A); ev=ev(abs(imag(ev))<1e-8);
assert(~isempty(ev),'audit_lewis:Mode','No hay polo real para identificar espiral.');
[~,i]=min(abs(ev)); l=real(ev(i));
end

function x=nearest(v,target)
[~,i]=min(abs(v-target)); x=v(i);
end

function s=spiral_evidence(A)
s.lambda=spiral(A); t=A(2,4);
s.K=A(3,1)*(A(4,4)-t*A(4,3))-A(4,1)*(A(3,4)-t*A(3,3));
s.det=det(A); s.det_from_K=A(1,2)*s.K;
assert(abs(s.det-s.det_from_K)<1e-10);
[V,D,W]=eig(A); [~,i]=min(abs(diag(D)-s.lambda));
s.eigenvector=V(:,i)/V(2,i);
s.entry_sensitivity=real(conj(W(:,i))*V(:,i).'/(W(:,i)'*V(:,i)));
s.doubling_or_decay_s=log(2)/abs(s.lambda);
end

function b=book_lateral(alpha,weight,Ix)
% Datos reducidos de Appendix A: interpolacion entre alfa=0 y alfa=5 deg.
% No se reproduce el modelo completo; solo derivadas necesarias del A lateral.
a=alpha*180/pi; assert(a>=0 && a<=5);
r2d=57.29578; V=502; qbar=.5*.002377*V^2; area=300; span=30; chord=11.32;
g=32.17; mass=weight/g; Iz=63100; Ixz=982; delta=Ix*Iz-Ixz^2;
clbeta=r2d*((-.008)+(-.012+.008)*a/5)/5;
cnbeta=r2d*((.018)+(.019-.018)*a/5)/5;
cybeta=-.02*r2d;
clp=-.443+(-.420+.443)*a/5; clr=.063+(.113-.063)*a/5;
cnp=.052+(-.012-.052)*a/5; cnr=-.378+(-.386+.378)*a/5;
cyp=-.188+(.110+.188)*a/5; cyr=.876+(.958-.876)*a/5;
cg=.05*chord/span;
cnbeta=cnbeta-cg*cybeta; cnp=cnp-cg*cyp; cnr=cnr-cg*cyr;
mom=qbar*area*span*[clbeta clp clr;cnbeta cnp cnr]*diag([1 span/(2*V) span/(2*V)]);
rot=[Iz Ixz;Ixz Ix]/delta*mom;
A=zeros(4); A(1,:)=[qbar*area*cybeta/(mass*V),g*cos(alpha)/V, ...
    sin(alpha)+qbar*area*cyp*span/(2*mass*V^2), ...
    -cos(alpha)+qbar*area*cyr*span/(2*mass*V^2)];
A(2,:)=[0 0 1 tan(alpha)]; A([3 4],[1 3 4])=rot;
b=struct('alpha_deg',a,'weight_lb',weight,'Ix_slugft2',Ix,'A',A,'poles',eig(A), ...
    'Cl',[clbeta clp clr],'Cn',[cnbeta cnp cnr],'Cy',[cybeta cyp cyr]);
end

function s=real_imag(s)
if isnumeric(s) && ~isreal(s), s=struct('real',real(s),'imag',imag(s));
elseif isstruct(s)
 names=fieldnames(s);
 for i=1:numel(s),for k=1:numel(names),s(i).(names{k})=real_imag(s(i).(names{k}));end,end
elseif iscell(s)
 for i=1:numel(s),s{i}=real_imag(s{i});end
end
end
