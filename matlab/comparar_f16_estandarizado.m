function r = comparar_f16_estandarizado(outdir)
% COMPARAR_F16_ESTANDARIZADO  Contrato comun y verificacion fisica 6-DOF.
%   r = comparar_f16_estandarizado;                 % no escribe archivos
%   r = comparar_f16_estandarizado('carpeta_nueva');  % evidencia JSON/MAT
% Conserva aerodinamica, parametros, APIs y estados de los modelos originales.
% El cuerpo auxiliar omite empuje/motor/filtro: el adaptador local los agrega
% explicitamente SOLO para verificar la misma fisica, sin editar ese modelo.
% Los polos validos se etiquetan unicamente en trims dinamicos convergidos.
% Al nivel del mar FT tiene un limite de altitud: se informa que la columna
% de altura del Jacobiano central no tiene una derivada unica bilateral.
if nargin<1, outdir=''; end
if ~isempty(outdir) && (exist(outdir,'dir') || exist(outdir,'file'))
    error('comparar_f16:Exists','La carpeta de resultados debe ser nueva.');
end
lat=auditar_lateral_lewis; base=lat.original;
xq=base.Xtrim; u=base.Utrim; theta=base.theta; e=q_to_e(xq); xb=e_to_b(e);
r.contrato=struct('fuente','Lewis/Stevens/Johnson 2015, tabla 3.6-3 y ejemplo 3.8-2', ...
    'velocidad_m_s',153.0096,'altitud_m',0,'cg',0.30, ...
    'unidades','SI; angulos rad; tasas rad/s; mandos grados; throttle 0..1', ...
    'ejes','cuerpo x adelante,y derecha,z abajo; posicion NED h=-zE', ...
    'lateral',{{'beta','phi','p','r'}},'longitudinal',{{'VT','alfa','theta','q'}}, ...
    'estados15','P3,alfaf,VT,alfa,beta,p,q,r,q0,q1,q2,q3,xE,yE,zE', ...
    'estados14','P3,alfaf,VT,alfa,beta,p,q,r,phi,theta,psi,xE,yE,zE', ...
    'estados13','u,v,w,p,q,r,q0,q1,q2,q3,xE,yE,zE; sin empuje/motor; alfaf congelado', ...
    'estados18','estados15,de_real,da_real,dr_real', ...
    'salidas9',{{'an_g','q_rad_s','alfa_deg'}},'entradas9',{{'dth','de_deg','da_deg','dr_deg'}});
r.auditoria_lateral=lat;
r.propio_trim=equilibrio(e,u,theta);
r.propio_trim.X15=xq; r.propio_trim.U4=u;
be=q_to_e(lat.book_point_in_local_model.X); bu=lat.book_point_in_local_model.U;
r.punto_lewis_en_modelo_local=equilibrio(be,bu,theta);
r.punto_lewis_en_modelo_local.A14=fd(@(z) funciones_euler(0,z,bu,theta),be,1e-5,4);
r.punto_lewis_en_modelo_local.etiqueta='Jacobiano fuera de equilibrio: no son modos de vuelo sostenido';
Ae=fd(@(z) funciones_euler(0,z,u,theta),e,1e-5,4);
Aq=fd(@(z) funciones(0,z,u,theta),xq,1e-5,4);
Ab=fd(@(z) cuerpo_completo(z,u,theta),xb,1e-5,4);
Be=fd(@(uu) funciones_euler(0,e,uu,theta),u,1e-5,4);
Bq=fd(@(uu) funciones(0,xq,uu,theta),u,1e-5,4);
Bb=fd(@(uu) cuerpo_completo(xb,uu,theta),u,1e-5,4);
Gq=fd(@e_to_q,e,1e-5,4); Gb=fd(@e_to_b,e,1e-5,4);
v.covarianza_A_quat=max(abs(Aq*Gq-Gq*Ae),[],'all');
v.covarianza_A_cuerpo=max(abs(Ab*Gb-Gb*Ae),[],'all');
v.covarianza_B_quat=max(abs(Bq-Gq*Be),[],'all');
v.covarianza_B_cuerpo=max(abs(Bb-Gb*Be),[],'all');
% Tres fuerzas, tres momentos, gravedad, empuje y acoplamientos combinados.
v.max_identidad_no_lineal=0; v.max_newton_euler=0; v.max_rotacion=0;
for k=1:8
    ec=e; ec(3)=145+5*k; ec(4)=0.03+0.006*k; ec(5)=(-1)^k*0.008*k;
    ec(6:8)=[0.025*k;-0.013*k;0.019*k];
    ec(9:11)=[0.03*k;-0.02*k;0.04*k]; ec(14)=-500*k;
    ec(1)=10+2*k; ec(2)=1.38*ec(4)*180/pi-0.1*k;
    uc=[-2+0.15*k;0.3*k;-0.4*k;0.1+0.02*k];
    fq=funciones(0,e_to_q(ec),uc,theta); fe=funciones_euler(0,ec,uc,theta);
    fb=cuerpo_completo(e_to_b(ec),uc,theta);
    gq=fd(@e_to_q,ec,1e-5,4); gb=fd(@e_to_b,ec,1e-5,4);
    err=max([max(abs(fq-gq*fe)),max(abs(fb-gb*fe))]);
    qc=e_to_q(ec); R=rotation_quat(qc(9:12)); R_e=rotation_euler(ec(9:11));
    physics=newton_euler(ec,uc,theta);
    errne=max(abs([physics.acceleration-translacion_cuerpo(ec,fe); ...
        physics.angular_acceleration-fe(6:8)]));
    r.casos_combinados(k)=struct('Xe',ec,'U4',uc,'cargas',physics, ...
        'error_identidad',err,'error_newton_euler',errne, ...
        'error_rotacion',max(abs(R-R_e),[],'all')); %#ok<AGROW>
    v.max_identidad_no_lineal=max(v.max_identidad_no_lineal,err);
    v.max_newton_euler=max(v.max_newton_euler,errne);
    v.max_rotacion=max(v.max_rotacion,max(abs(R-R_e),[],'all'));
end
% Integracion de la misma perturbacion en las tres formulaciones completas.
ei=e; ei([4 5 6 7 8 9 10 11])=ei([4 5 6 7 8 9 10 11])+ ...
    [0.015;-0.01;0.025;-0.015;0.02;0.08;-0.03;0.11];
ei(14)=-1000; % integracion dentro del dominio de altitud, lejos del limite FT
qi=e_to_q(ei); bi=e_to_b(ei); time=0; h=.002; normerr=0;
for k=1:250
    [~,~,ei]=rkfv03(@funciones_euler,time,h,ei,u,theta);
    [~,~,qi]=rkfv03(@funciones,time,h,qi,u,theta);
    [~,~,bi]=rkfv03(@cuerpo_integrador,time,h,bi,u,theta);
    time=time+h; normerr=max(normerr,abs(norm(qi(9:12))-1));
end
v.integracion_quat_euler=max(abs(qi-e_to_q(ei)));
v.integracion_cuerpo_euler=max(abs(bi-e_to_b(ei)));
v.max_deriva_norma_quat=normerr;
% Actuadores: igualdad de planta con posiciones reales y estructura A/B.
x18=[xq;u(1:3)]; A18=fd(@(z) funciones_act(0,z,u,theta),x18,1e-5,4);
B18=fd(@(uu) funciones_act(0,x18,uu,theta),u,1e-5,4);
f18=funciones_act(0,x18,u,theta); f15=funciones(0,xq,u,theta);
v.error_actuadores=max([max(abs(f18(1:15)-f15));max(abs(f18(16:18))); ...
    max(abs(A18(1:15,1:15)-Aq),[],'all'); ...
    max(abs(A18(1:15,16:18)-Bq(:,1:3)),[],'all'); ...
    max(abs(A18(16:18,16:18)+20.2*eye(3)),[],'all'); ...
    max(abs(B18(16:18,1:3)-20.2*eye(3)),[],'all'); ...
    max(abs(B18(1:15,1:3)),[],'all')]);
lim=funciones_act(0,[xq;0;0;0],[100;100;100;u(4)],theta);
assert(max(abs(lim(16:18)-[60;80;120]))<1e-12,'comparar_f16:Actuador','Limites de razon incorrectos.');
G18=blkdiag(Gq,eye(3)); A17=G18\(A18*G18);
v.covarianza_actuadores=max(abs(A18*G18-G18*A17),[],'all');
r.matrices=struct('A14',Ae,'B14',Be,'A15',Aq,'B15',Bq, ...
    'A_cuerpo15',Ab,'B_cuerpo15',Bb,'A18',A18,'B18',B18, ...
    'A_actuadores_fisicos17',A17,'G_quat15_euler14',Gq,'G_cuerpo15_euler14',Gb);
r.matrices.A13_auxiliar=fd(@(z) modelo_cuerpo(0,z,u,theta,xq(2)),xb(1:13),1e-5,4);
[r.matrices.A9,r.matrices.B9,r.matrices.C9,r.matrices.D9]=matrices9(e,u,theta);
r.polos14=eig(Ae); r.polos17=eig(A17);
lambda=lat.spiral_local.lambda; [~,near]=min(abs(r.polos14-lambda));
r.polos_espiral=r.polos14(near);
% Diagnostico de frontera: derivadas una-sided de altitud h positiva/negativa.
dh=0.01; ep=e; em=e; ep(14)=-dh; em(14)=dh;
f0=funciones_euler(0,e,u,theta);
right=(funciones_euler(0,ep,u,theta)-f0)/dh; % derivada respecto a h, h>=0
left=(f0-funciones_euler(0,em,u,theta))/dh; % extension por debajo de cero
r.altitud_frontera=struct('derivada_h_positiva',right,'derivada_h_negativa',left, ...
    'max_diferencia',max(abs(right-left)), ...
    'no_diferenciable',max(abs(right-left))>1e-5, ...
    'causa','FT.m: max(0,-zE) en el limite h=0; el Jacobiano central promedia ramas');
% A alternativa de dominio h>=0, orden 2 adelante, sin alterar FT.
epp=e; epp(14)=-2*dh;
r.matrices.A14_altitud_positiva=Ae;
r.matrices.A14_altitud_positiva(:,14)=-(-3*f0+4*funciones_euler(0,ep,u,theta)- ...
    funciones_euler(0,epp,u,theta))/(2*dh);
r.polos14_altitud_positiva=eig(r.matrices.A14_altitud_positiva);
r.etiqueta_polos14='Jacobiano central en frontera h=0; contrastar con rama fisica h>=0, sin derivada bilateral unica';
% Viraje publicado: snapshot local, no asumir convergencia del modelo local.
et=e; et(4:11)=[.2485;.00048;-.01555;.2934;.06071;1.367;.05185;0];
ut=[-6.256;.09891;-.4218;.8499]; et(1)=Calc_P1(ut(4)); et(2)=1.38*et(4)*180/pi;
r.viraje_lewis_en_modelo_local=equilibrio(et,ut,theta);
[At,Bt,Ct,Dt]=matrices9(et,ut,theta);
r.viraje_lewis_en_modelo_local.A9=At; r.viraje_lewis_en_modelo_local.B9=Bt;
r.viraje_lewis_en_modelo_local.C9=Ct; r.viraje_lewis_en_modelo_local.D9=Dt;
r.viraje_lewis_en_modelo_local.error_A9=At-base.referencias.viraje_45g.A;
r.viraje_lewis_en_modelo_local.etiqueta='Snapshot en datos redondeados de Lewis; no modos de un trim local';
r.pull_up=struct('estado','NO_EVALUADO_MANDO_FUERA_DE_DOMINIO', ...
    'throttle_publicado',1.023,'dominio_local',[0 1], ...
    'razon','No saturar ni extrapolar mandos para forzar equivalencia; CG de columna tambien es ambiguo');
r.verificacion=v;
r.limites={'Validacion de ecuaciones y coordenadas comparte hu; no certifica datos NASA.'; ...
    'La fuente reducida de Lewis no es la misma realizacion que los ajustes hi-fi/LEF.'; ...
    'Los polos de cuaterniones sin proyectar incluyen una direccion radial no fisica.'; ...
    'A14 central a h=0 no representa una derivada bilateral unica en su columna de altura.'};
fprintf('ESTANDARIZADO: identidades 6DOF %.3e; Newton-Euler %.3e; covarianza A %.3e\n', ...
    v.max_identidad_no_lineal,v.max_newton_euler,max(v.covarianza_A_quat,v.covarianza_A_cuerpo));
fprintf('Integracion: quat/Euler %.3e; cuerpo/Euler %.3e; actuadores %.3e\n', ...
    v.integracion_quat_euler,v.integracion_cuerpo_euler,v.error_actuadores);
fprintf('Espiral completa %.10g; trim propio valido=%d; punto Lewis valido=%d\n', ...
    real(r.polos_espiral),r.propio_trim.valido,r.punto_lewis_en_modelo_local.valido);
fprintf('Altitud h=0: salto de derivada %.3e; frontera no diferenciable=%d\n', ...
    r.altitud_frontera.max_diferencia,r.altitud_frontera.no_diferenciable);
if ~isempty(outdir)
    mkdir(outdir); save(fullfile(outdir,'comparacion_estandarizada.mat'),'r');
    f=fopen(fullfile(outdir,'comparacion_estandarizada.json'),'w');
    assert(f~=-1); c=onCleanup(@() fclose(f)); %#ok<NASGU>
    fwrite(f,jsonencode(serializar(r),'PrettyPrint',true),'char');
end
end

function p=equilibrio(e,u,theta)
f=funciones_euler(0,e,u,theta);
p=struct('Xe',e,'U4',u,'residuo_completo',f,'residuo_dinamico',f(1:8), ...
    'max_residuo_dinamico',max(abs(f(1:8))), ...
    'valido',max(abs(f(1:8)))<1e-6,'tipo','equilibrio de estados dinamicos; posicion puede avanzar');
end

function [A,B,C,D]=matrices9(e,u,theta)
idx=[3 4 10 7 1 5 9 6 8]; S=diag([1/.3048 ones(1,8)]);
Ae=fd(@(z) funciones_euler(0,z,u,theta),e,1e-5,4);
Be=fd(@(uu) funciones_euler(0,e,uu,theta),u,1e-5,4);
Ce=fd(@(z) salidas(z,u,theta),e,1e-5,4);
De=fd(@(uu) salidas(e,uu,theta),u,1e-5,4);
A=S*Ae(idx,idx)/S; B=S*Be(idx,[4 1 2 3]);
C=Ce(:,idx)/S; D=De(:,[4 1 2 3]);
end

function y=salidas(e,u,theta)
p=newton_euler(e,u,theta);
y=[-p.fuerzas(3)/(theta(1)*theta(2));e(7);e(4)*180/pi];
end

function p=newton_euler(e,u,theta)
[~,ps,rho,sound]=atmosfera(-e(14)); V=e(3); a=e(4); b=e(5);
qb=.5*rho*V^2; lef=hlef(0,e(2),[a qb ps],theta);
loads=hu(0,e(3:8),[u(1:3).' qb lef],theta);
omega=e(6:8); vel=V*[cos(a)*cos(b);sin(b);sin(a)*cos(b)];
thrust=FT(e(1),V/sound,e(14));
gravity=rotation_euler(e(9:11)).'*[0;0;theta(2)];
I=[12874.8 0 -1331.4;0 75673.6 0;-1331.4 0 85552.1];
moment=loads([5 6 4]); gyro=-cross(omega,[theta(17);0;0]);
p=struct('fuerzas',loads(1:3),'momentos_LMN',moment,'empuje',thrust, ...
    'gravedad_cuerpo',gravity,'qbar',qb,'LEF',lef,'velocidad_cuerpo',vel, ...
    'acoplamiento_traslacional',-cross(omega,vel),'momento_giroscopico',gyro, ...
    'acceleration',(loads(1:3)+[thrust;0;0])/theta(1)+gravity-cross(omega,vel), ...
    'angular_acceleration',I\(moment-cross(omega,I*omega)+gyro));
end

function f=cuerpo_completo(b,u,theta)
vel=b(1:3); V=norm(vel); a=atan2(vel(3),vel(1));
[~,ps,rho,sound]=atmosfera(-b(13)); qb=.5*rho*V^2;
d=modelo_cuerpo(0,b(1:13),u,theta,b(15));
d(1)=d(1)+FT(b(14),V/sound,b(13))/theta(1);
f=[d;fm(0,b(14),[u(4);V/sound;b(13)],theta);flef(0,b(15),[a qb ps],theta)];
end

function f=cuerpo_integrador(~,b,u,theta)
f=cuerpo_completo(b,u,theta);
end

function v=translacion_cuerpo(e,fe)
V=e(3); a=e(4); b=e(5); dV=fe(3); da=fe(4); db=fe(5);
v=[cos(a)*cos(b)*dV-V*sin(a)*cos(b)*da-V*cos(a)*sin(b)*db; ...
    sin(b)*dV+V*cos(b)*db;sin(a)*cos(b)*dV+V*cos(a)*cos(b)*da-V*sin(a)*sin(b)*db];
end

function q=e_to_q(e)
angles=e(9:11)/2; c=cos(angles); s=sin(angles);
qq=[c(1)*c(2)*c(3)+s(1)*s(2)*s(3);s(1)*c(2)*c(3)-c(1)*s(2)*s(3); ...
    c(1)*s(2)*c(3)+s(1)*c(2)*s(3);c(1)*c(2)*s(3)-s(1)*s(2)*c(3)];
q=[e(1:8);qq;e(12:14)];
end

function b=e_to_b(e)
q=e_to_q(e); V=e(3); a=e(4); beta=e(5);
b=[V*cos(a)*cos(beta);V*sin(beta);V*sin(a)*cos(beta);e(6:8);q(9:12);e(12:14);e(1:2)];
end

function e=q_to_e(q)
a=q(9:12);
phi=atan2(2*(a(1)*a(2)+a(3)*a(4)),a(1)^2-a(2)^2-a(3)^2+a(4)^2);
pitch=asin(max(-1,min(1,2*(a(1)*a(3)-a(2)*a(4)))));
psi=atan2(2*(a(2)*a(3)+a(1)*a(4)),a(1)^2+a(2)^2-a(3)^2-a(4)^2);
e=[q(1:8);phi;pitch;psi;q(13:15)];
end

function R=rotation_euler(a)
c=cos(a);s=sin(a);
R=[c(3) -s(3) 0;s(3) c(3) 0;0 0 1]*[c(2) 0 s(2);0 1 0;-s(2) 0 c(2)]* ...
    [1 0 0;0 c(1) -s(1);0 s(1) c(1)];
end

function R=rotation_quat(q)
w=q(1);x=q(2);y=q(3);z=q(4);
R=[w*w+x*x-y*y-z*z 2*(x*y-w*z) 2*(x*z+w*y); ...
    2*(x*y+w*z) w*w-x*x+y*y-z*z 2*(y*z-w*x); ...
    2*(x*z-w*y) 2*(y*z+w*x) w*w-x*x-y*y+z*z];
end

function J=fd(f,x,h,order)
x=x(:); J=zeros(numel(f(x)),numel(x));
for j=1:numel(x)
    d=zeros(size(x));d(j)=h*max(1,abs(x(j)));
    if order==2,J(:,j)=(f(x+d)-f(x-d))/(2*d(j));
    else,J(:,j)=(8*(f(x+d)-f(x-d))-(f(x+2*d)-f(x-2*d)))/(12*d(j));end
end
end

function a=serializar(a)
if isnumeric(a) && ~isreal(a),a=struct('real',real(a),'imag',imag(a));
elseif isstruct(a)
    fields=fieldnames(a);
    for j=1:numel(a),for k=1:numel(fields),a(j).(fields{k})=serializar(a(j).(fields{k}));end,end
elseif iscell(a)
    for j=1:numel(a),a{j}=serializar(a{j});end
end
end
