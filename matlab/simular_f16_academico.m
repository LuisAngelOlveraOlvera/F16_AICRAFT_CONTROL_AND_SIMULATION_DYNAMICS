function r = simular_f16_academico(opciones)
% SIMULAR_F16_ACADEMICO  Control -> 6DOF original -> registro sincronizado.
% r=simular_f16_academico(struct('escenario','trayectoria','duracion',90));
% No escribe archivos, modifica workspace ni usa el RNG global.
% Filas=muestras. X conserva los 15/18 estados originales. Referencia y
% objetivo: [h_m,VT_m_s,psi_rad]. U: [de_deg,da_deg,dr_deg,dth].
if nargin<1,opciones=struct;end
cfg=struct('escenario','trayectoria','duracion',90,'paso',.002, ...
    'VT',170,'altitud',3000,'semilla',11,'tramo',15, ...
    'waypoints_ned',[],'posicion_inicial_ned',[], ...
    'anticipacion_m',2000,'radio_captura_m',250);
assert(isstruct(opciones)&&isscalar(opciones),'f16:Config','Configuracion escalar requerida.');
fields=fieldnames(opciones);
for k=1:numel(fields)
    assert(isfield(cfg,fields{k}),'f16:Config','Opcion desconocida: %s.',fields{k});
    cfg.(fields{k})=opciones.(fields{k});
end
cfg.escenario=char(cfg.escenario);
names={'nivelado','lateral_abierto','longitudinal_abierto','lateral_lqr', ...
    'viraje','ascenso','autopiloto','trayectoria','dryden_abierto','dryden_lqr','waypoints'};
assert(any(strcmp(cfg.escenario,names)),'f16:Escenario','Escenario desconocido.');
validateattributes(cfg.paso,{'numeric'},{'scalar','real','finite','positive','<=',.02});
validateattributes(cfg.duracion,{'numeric'},{'scalar','real','finite','positive'});
validateattributes(cfg.VT,{'numeric'},{'scalar','real','finite','>=',100,'<=',200});
validateattributes(cfg.altitud,{'numeric'},{'scalar','real','finite','>=',0,'<=',10000});
validateattributes(cfg.semilla,{'numeric'},{'scalar','integer','>=',0,'<=',2^32-1});
validateattributes(cfg.tramo,{'numeric'},{'scalar','real','finite','positive'});
N=round(cfg.duracion/cfg.paso);
assert(N>=1 && abs(N*cfg.paso-cfg.duracion)<1e-9, ...
    'f16:Tiempo','Duracion debe ser multiplo entero del paso.');
base=validar_lewis(struct('mostrar',false)); par=base.theta;
gamma=0;psidot=0;
if strcmp(cfg.escenario,'viraje'),psidot=3;end
if strcmp(cfg.escenario,'ascenso'),gamma=5;end
[xt,ut,trim]=trim_vuelo(cfg.VT,cfg.altitud,gamma,psidot,par);
assert(trim.converge,'f16:Trim','Trim no convergido: %.4g.',trim.residuo);
ang0=angulos(xt(9:12));
nav=strcmp(cfg.escenario,'waypoints');
closed=any(strcmp(cfg.escenario,{'lateral_lqr','dryden_lqr','autopiloto','trayectoria','waypoints'}));
act=any(strcmp(cfg.escenario,{'autopiloto','trayectoria','waypoints'}));
wind=startsWith(cfg.escenario,'dryden');
c=diseno(xt,ut,par,closed,act);
x=xt;
if any(strcmp(cfg.escenario,{'lateral_abierto','lateral_lqr'}))
    x(5)=2*pi/180; x(9:12)=quat(10*pi/180,ang0(2),0);
elseif strcmp(cfg.escenario,'longitudinal_abierto')
    x(4)=x(4)+3*pi/180;
end
if act,x=[x;ut(1:3)];end
if nav
    if isempty(cfg.waypoints_ned)
        cfg.waypoints_ned=[0 0 -cfg.altitud;8000 0 -cfg.altitud-100; ...
            16000 3000 -cfg.altitud-200;24000 3000 -cfg.altitud-100];
    end
    validateattributes(cfg.anticipacion_m,{'numeric'},{'scalar','finite','positive'});
    validateattributes(cfg.radio_captura_m,{'numeric'},{'scalar','finite','positive'});
    w=cfg.waypoints_ned;w(:,3)=-w(:,3);
    x(13:15)=cfg.waypoints_ned(1,:).';
    if ~isempty(cfg.posicion_inicial_ned)
        validateattributes(cfg.posicion_inicial_ned,{'numeric'},{'numel',3,'finite','real'});
        x(13:15)=cfg.posicion_inicial_ned(:);
    end
    assert(abs(x(15)+cfg.altitud)<1e-9,'f16:Trim','Altitud inicial debe coincidir con trim.');
    segment=1;
end
t=(0:N)'*cfg.paso; nx=numel(x);
X=zeros(N+1,nx); Uraw=zeros(N+1,4); Ub=Uraw; Ur=Uraw;
G=zeros(N+1,3); refs=zeros(N+1,3); objectives=refs;
navlog=zeros(N+1,5);
stream=RandStream('mt19937ar','Seed',cfg.semilla);
targets=repmat([cfg.altitud cfg.VT 0],max(1,ceil(cfg.duracion/cfg.tramo)),1);
if strcmp(cfg.escenario,'trayectoria')
    targets(2:end,1)=cfg.altitud+250*(2*rand(stream,size(targets,1)-1,1)-1);
    targets(2:end,3)=cumsum(80*pi/180*(2*rand(stream,size(targets,1)-1,1)-1));
end
ref=[cfg.altitud cfg.VT 0]; integ=zeros(3,1); gust=zeros(3,1);
for k=1:N+1
    now=t(k);
    target=[cfg.altitud cfg.VT 0];
    if nav
        [target,ng]=guiar_waypoints_f16(x(13:15),w,segment,cfg.VT,cfg.anticipacion_m,cfg.radio_captura_m);
        segment=ng.tramo;
        navlog(k,:)=[segment ng.error_transversal_m ng.error_espacial_m ng.distancia_final_m ng.finalizado];
    elseif strcmp(cfg.escenario,'trayectoria')
        target=targets(min(floor(now/cfg.tramo)+1,size(targets,1)),:);
    elseif strcmp(cfg.escenario,'autopiloto') && now>=5
        target=[cfg.altitud+100 cfg.VT 20*pi/180];
    elseif strcmp(cfg.escenario,'viraje')
        target(3)=psidot*pi/180*now;
    elseif strcmp(cfg.escenario,'ascenso')
        target(1)=cfg.altitud+cfg.VT*sin(gamma*pi/180)*now;
    end
    % Referencia en la muestra actual; no registrar t+dt bajo etiqueta t.
    a=angulos(x(9:12)); h=-x(15);
    raw=ut;
    if closed
        lon=[x(3)-xt(3);x(4)-xt(4);x(7);a(2)-ang0(2); ...
            x(1)-xt(1);x(2)-xt(2)];
        lat=[x(5);x(6);x(8);a(1)];
        if act
            lon=[lon;h-ref(1);integ(1:2)];
            lat=[lat;wrap(a(3)-ref(3));integ(3)];
        end
        ul=ut([1 4])-c.Klon*lon; ua=ut([2 3])-c.Klat*lat;
        raw=[ul(1);ua;ul(2)];
    end
    bound=min(max(raw,[-25;-21.5;-30;0]),[25;21.5;30;1]);
    real=bound;
    if act,real(1:3)=x(16:18);end
    X(k,:)=x.';Uraw(k,:)=raw.';Ub(k,:)=bound.';Ur(k,:)=real.';
    G(k,:)=gust.';refs(k,:)=ref;objectives(k,:)=target;
    if k>N || (nav && ng.finalizado),break;end
    % Mando y rafaga ZOH, la muestra k registra lo usado en [t(k),t(k+1)).
    if act
        [~,~,x]=rkfv03(@funciones_act,now,cfg.paso,x,bound,par);
        integ=integ+cfg.paso*[h-ref(1);X(k,3)-ref(2);wrap(a(3)-ref(3))];
    elseif wind
        [~,~,x]=rkfv03(@funciones_viento,now,cfg.paso,x,[bound;gust],par);
    else
        [~,~,x]=rkfv03(@funciones,now,cfg.paso,x,bound,par);
    end
    if act
        ref(1)=ref(1)+cfg.paso*max(-10,min(10,(target(1)-ref(1))/2));
        ref(3)=ref(3)+cfg.paso*max(-3*pi/180,min(3*pi/180,wrap(target(3)-ref(3))/2));
    else
        ref=target;
        if strcmp(cfg.escenario,'viraje'),ref(3)=psidot*pi/180*t(k+1);end
        if strcmp(cfg.escenario,'ascenso'),ref(1)=cfg.altitud+cfg.VT*sin(gamma*pi/180)*t(k+1);end
    end
    if wind
        [gust,~]=dryden_paso(gust,cfg.paso,x(3),[533;533;533],[3;3;3],randn(stream,3,1));
    end
    assert(all(isfinite(x)) && isreal(x) && x(3)>1, ...
        'f16:Divergencia','Estado invalido en t=%.5g s.',t(k+1));
end
t=t(1:k);X=X(1:k,:);Uraw=Uraw(1:k,:);Ub=Ub(1:k,:);Ur=Ur(1:k,:);
G=G(1:k,:);refs=refs(1:k,:);objectives=objectives(1:k,:);
r=struct('config',cfg,'theta',par,'trim',trim,'Xtrim',xt,'Utrim',ut, ...
    't',t,'X',X,'U_comando',Uraw,'U_acotado',Ub,'U_real',Ur, ...
    'rafaga_m_s',G,'referencia',refs,'objetivo',objectives,'control',c);
r=observaciones(r,act,wind);
if nav
    r.navegacion=struct('waypoints_ned',cfg.waypoints_ned,'tramo',navlog(1:k,1), ...
        'error_transversal_m',navlog(1:k,2),'error_espacial_m',navlog(1:k,3), ...
        'distancia_final_m',navlog(1:k,4),'finalizado',logical(navlog(k,5)));
    r.metricas.rms_error_espacial_m=sqrt(mean(navlog(1:k,3).^2));
    r.metricas.max_error_espacial_m=max(navlog(1:k,3));
    r.metricas.distancia_final_m=navlog(k,4);
    r.metricas.ruta_completada=logical(navlog(k,5));
    arc=[0;cumsum(vecnorm(diff(cfg.waypoints_ned(:,1:2)),2,2))];
    r.ruta_nominal_ned=interp1(arc,cfg.waypoints_ned,linspace(0,arc(end),k)');
    r.etiqueta_ruta='Ruta 3D por waypoints; guia de posicion con anticipacion';
end
end

function c=diseno(x,u,par,closed,act)
a=angulos(x(9:12));e=[x(1:8);a;x(13:15)];
A=jacobiano_fd(@(z) funciones_euler(0,z,u,par),e);
B=jacobiano_fd(@(v) funciones_euler(0,e,v,par),u);
il=[3 4 7 10 1 2];ia=[5 6 8 9];
Al=A(il,il);Bl=B(il,[1 4]);At=A(ia,ia);Bt=B(ia,[2 3]);
c=struct('A14',A,'B14',B,'Alon',Al,'Alat',At,'polos_lon',eig(Al), ...
    'polos_lat',eig(At),'Klon',[],'Klat',[], ...
    'etiqueta','Jacobiano local; giros/ascensos son puntos de trayectoria');
if ~closed,return;end
if act
    Aa=zeros(9);Ba=zeros(9,2);Aa(1:6,1:6)=Al;Ba(1:6,:)=Bl;
    Aa(7,2)=-x(3);Aa(7,4)=x(3);Aa(8,7)=1;Aa(9,1)=1;
    c.Klon=lqr_gain(Aa,Ba,diag([1,1/(2*pi/180)^2,1/(10*pi/180)^2, ...
        1/(5*pi/180)^2,1e-6,1e-6,1/5^2,1/50^2,1/30^2]),diag([1/5^2,1/.3^2]));
    Aa=zeros(6);Ba=zeros(6,2);Aa(1:4,1:4)=At;Ba(1:4,:)=Bt;
    Aa(5,3)=1/cos(a(2));Aa(6,5)=1;
    c.Klat=lqr_gain(Aa,Ba,diag([1/(pi/180)^2,1/(20*pi/180)^2, ...
        1/(10*pi/180)^2,1/(15*pi/180)^2,1/(5*pi/180)^2,1/(40*pi/180)^2]),diag([1/15^2,1/15^2]));
else
    c.Klon=lqr_gain(Al,Bl,diag([1/2^2,1/(pi/180)^2,1/(5*pi/180)^2, ...
        1/(2*pi/180)^2,1e-6,1e-6]),diag([1/5^2,1/.2^2]));
    c.Klat=lqr_gain(At,Bt,diag([1/(.5*pi/180)^2,1/(10*pi/180)^2, ...
        1/(5*pi/180)^2,1/(5*pi/180)^2]),diag([1/10^2,1/10^2]));
end
end

function r=observaciones(r,act,wind)
X=r.X; n=size(X,1);par=r.theta;
r.angulos_rad=zeros(n,3);r.altitud_m=-X(:,15);
r.norma_cuaternion=sqrt(sum(X(:,9:12).^2,2));
r.Mach=zeros(n,1);r.qbar_Pa=r.Mach;r.LEF_deg=r.Mach;r.empuje_N=r.Mach;
r.fuerzas_N=zeros(n,3);r.momentos_Nm=zeros(n,3);
r.especifica_cuerpo_m_s2=zeros(n,3);r.aceleracion_inercial_m_s2=zeros(n,3);
r.derivadas=zeros(size(X));
for k=1:n
    x=X(k,:).';u=r.U_real(k,:).';g=r.rafaga_m_s(k,:).';
    r.angulos_rad(k,:)=angulos(x(9:12)).';
    [~,ps,rho,sound]=atmosfera(-x(15));va=x(3);a=x(4);b=x(5);
    if wind,va=va-g(1);a=a+g(3)/x(3);b=b+g(2)/x(3);end
    qb=.5*rho*va^2;lef=hlef(0,x(2),[a qb ps],par);
    f=hu(0,[va;a;b;x(6:8)],[u(1:3);qb;lef],par);
    th=FT(x(1),x(3)/sound,x(15));
    specific=(f(1:3)+[th;0;0])/par(1);
    T=pose_f16_enu(x(9:12),[0 0 0]);P=[0 1 0;1 0 0;0 0 -1];R=P'*T(1:3,1:3);
    r.especifica_cuerpo_m_s2(k,:)=specific.';
    r.aceleracion_inercial_m_s2(k,:)=(R*specific+[0;0;par(2)]).';
    r.Mach(k)=x(3)/sound;r.qbar_Pa(k)=qb;r.LEF_deg(k)=lef;r.empuje_N(k)=th;
    r.fuerzas_N(k,:)=f(1:3).';r.momentos_Nm(k,:)=f([5 6 4]).';
    if act,d=funciones_act(r.t(k),x,r.U_acotado(k,:).',par);
    elseif wind,d=funciones_viento(r.t(k),x,[u;g],par);
    else,d=funciones(r.t(k),x,u,par);end
    r.derivadas(k,:)=d.';
end
r.an_g=-r.fuerzas_N(:,3)/(par(1)*par(2));
r.saturacion_comando=abs(r.U_comando-r.U_acotado)>1e-10;
r.saturacion_razon=false(n,3);
if act,r.saturacion_razon=abs(r.derivadas(:,16:18))>=[60 80 120]-1e-9;end
err=[r.altitud_m-r.referencia(:,1),X(:,3)-r.referencia(:,2), ...
    wrap(r.angulos_rad(:,3)-r.referencia(:,3))];
r.metricas=struct('rms_altitud_m',sqrt(mean(err(:,1).^2)), ...
    'rms_velocidad_m_s',sqrt(mean(err(:,2).^2)), ...
    'rms_rumbo_deg',sqrt(mean(err(:,3).^2))*180/pi, ...
    'max_error_norma_quat',max(abs(r.norma_cuaternion-1)), ...
    'fraccion_saturacion',mean(r.saturacion_comando,1));
% Ruta cinemática orientativa de consignas, NO seguimiento de posicion x/y.
dh=gradient(r.referencia(:,1),r.config.paso);
vh=sqrt(max(0,r.referencia(:,2).^2-dh.^2));
r.ruta_nominal_ned=[cumtrapz(r.t,vh.*cos(r.referencia(:,3))), ...
    cumtrapz(r.t,vh.*sin(r.referencia(:,3))),-r.referencia(:,1)];
r.etiqueta_ruta='Ruta cinematica orientativa; el control sigue h,VT,psi, no x/y';
r.unidades=struct('X','15/18 estados originales; SI/rad; alfaf grados', ...
    'U','de,da,dr [deg],dth [0..1]','referencia','h [m],VT [m/s],psi [rad]', ...
    'aceleracion_inercial','NED, con gravedad [m/s^2]', ...
    'an','fuerza normal especifica CG/g, sin gravedad');
end

function a=angulos(q)
q=q(:)/norm(q);a=[atan2(2*(q(1)*q(2)+q(3)*q(4)),q(1)^2-q(2)^2-q(3)^2+q(4)^2); ...
    asin(max(-1,min(1,2*(q(1)*q(3)-q(2)*q(4))))); ...
    atan2(2*(q(2)*q(3)+q(1)*q(4)),q(1)^2+q(2)^2-q(3)^2-q(4)^2)];
end
function q=quat(phi,theta,psi)
c=cos([phi theta psi]/2);s=sin([phi theta psi]/2);
q=[c(1)*c(2)*c(3)+s(1)*s(2)*s(3);s(1)*c(2)*c(3)-c(1)*s(2)*s(3); ...
    c(1)*s(2)*c(3)+s(1)*c(2)*s(3);c(1)*c(2)*s(3)-s(1)*s(2)*c(3)];
end
function a=wrap(a)
a=atan2(sin(a),cos(a));
end
