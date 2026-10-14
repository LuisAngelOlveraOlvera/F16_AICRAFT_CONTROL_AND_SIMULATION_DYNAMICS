function r=solve(c)
% Ejecutor personalizado. Aerodinámica, ecuaciones y RKF son los originales.
p=f16lab.parameters;s=c.escenario;dt=c.paso;N=round(c.duracion/dt);t=(0:N)'*dt;
gamma=0;turn=0;if strcmp(s,'ascenso'),gamma=c.reference.gamma_deg;end;if strcmp(s,'viraje'),turn=c.reference.turn_deg_s;end
[xt,ut,info]=trim_vuelo(c.VT,c.altitud,gamma,turn,p);assert(info.converge,'lab:Trim','Trim no convergió.');
act=any(strcmp(s,{'autopiloto','trayectoria','waypoints'}));closed=act||any(strcmp(s,{'lateral_lqr','dryden_lqr'}));wind=startsWith(s,'dryden');nav=strcmp(s,'waypoints');
control=f16lab.design(xt,ut,c.weights,act,false);a0=f16lab.angles(xt(9:12));x=f16lab.perturb(xt,c.initial);if act,x=[x;ut(1:3)];end
if nav
    w=c.waypoints;pos=w(1,:);if ~isempty(c.posicion_inicial),pos=c.posicion_inicial;end;x(13:15)=[pos(1);pos(2);-pos(3)];segment=1;
end
X=zeros(N+1,numel(x));U=zeros(N+1,4);G=zeros(N+1,3);refs=zeros(N+1,3);obj=refs;navlog=zeros(N+1,5);
stream=RandStream('mt19937ar','Seed',c.semilla);nt=max(1,ceil(c.duracion/c.tramo));targets=repmat([c.altitud c.VT 0],nt,1);
if strcmp(s,'trayectoria')
    targets(2:end,1)=c.altitud+c.reference.trayectoria_h_m*(2*rand(stream,nt-1,1)-1);
    targets(2:end,3)=cumsum(c.reference.trayectoria_rumbo_deg*pi/180*(2*rand(stream,nt-1,1)-1));
end
ref=[c.altitud c.VT 0];integral=zeros(3,1);gust=zeros(3,1);wrap=@(a)atan2(sin(a),cos(a));
for k=1:N+1
    target=[c.altitud c.VT 0];
    if nav
        [target,ng]=guiar_waypoints_f16(x(13:15),w,segment,c.VT,c.anticipacion_m,c.radio_captura_m);segment=ng.tramo;
        navlog(k,:)=[segment ng.error_transversal_m ng.error_espacial_m ng.distancia_final_m ng.finalizado];
    elseif strcmp(s,'trayectoria'),target=targets(min(floor(t(k)/c.tramo)+1,nt),:);
    elseif strcmp(s,'autopiloto')&&t(k)>=c.reference.time_s,target=[c.altitud+c.reference.delta_h_m c.VT+c.reference.delta_v_m_s c.reference.delta_psi_deg*pi/180];
    elseif strcmp(s,'viraje'),target(3)=turn*pi/180*t(k);
    elseif strcmp(s,'ascenso'),target(1)=c.altitud+c.VT*sin(gamma*pi/180)*t(k);end
    a=f16lab.angles(x(9:12));raw=ut;
    if closed
        lon=[x(3)-xt(3);x(4)-xt(4);x(7);a(2)-a0(2);x(1)-xt(1);x(2)-xt(2)];lat=[x(5);x(6);x(8);a(1)];
        if act,lon=[lon;-x(15)-ref(1);integral(1:2)];lat=[lat;wrap(a(3)-ref(3));integral(3)];end
        ul=ut([1 4])-control.Klon*lon;ua=ut([2 3])-control.Klat*lat;raw=[ul(1);ua;ul(2)];
    end
    if strcmp(s,'manual')&&t(k)>=c.manual.time_s,z=c.manual;raw=[z.elevador_deg;z.aleron_deg;z.timon_deg;z.throttle];end
    bound=min(max(raw,[-25;-21.5;-30;0]),[25;21.5;30;1]);X(k,:)=x';U(k,:)=raw';G(k,:)=gust';refs(k,:)=ref;obj(k,:)=target;
    if k>N||(nav&&ng.finalizado),break;end
    if act
        [~,~,x]=rkfv03(@funciones_act,t(k),dt,x,bound,p);integral=integral+dt*[-X(k,15)-ref(1);X(k,3)-ref(2);wrap(a(3)-ref(3))];
        z=c.reference;ref(1)=ref(1)+dt*max(-z.h_rate_m_s,min(z.h_rate_m_s,(target(1)-ref(1))/2));
        ref(2)=ref(2)+dt*max(-z.v_rate_m_s2,min(z.v_rate_m_s2,(target(2)-ref(2))/2));
        limit=z.psi_rate_deg_s*pi/180;ref(3)=ref(3)+dt*max(-limit,min(limit,wrap(target(3)-ref(3))/2));
    elseif wind,[~,~,x]=rkfv03(@funciones_viento,t(k),dt,x,[bound;gust],p);
    else,[~,~,x]=rkfv03(@funciones,t(k),dt,x,bound,p);end
    if ~act
        ref=target;
        if strcmp(s,'viraje'),ref(3)=turn*pi/180*t(k+1);end
        if strcmp(s,'ascenso'),ref(1)=c.altitud+c.VT*sin(gamma*pi/180)*t(k+1);end
    end
    if wind,z=c.turbulence;[gust,~]=dryden_paso(gust,dt,x(3),[z.length_u z.length_v z.length_w],[z.sigma_u z.sigma_v z.sigma_w],randn(stream,3,1));end
    assert(all(isfinite(x))&&isreal(x)&&x(3)>1,'lab:Divergencia','Estado inválido t=%g.',t(k+1));
end
r=f16lab.record(c,t(1:k),X(1:k,:),U(1:k,:),xt,ut,info,control,refs(1:k,:),G(1:k,:));r.objetivo=obj(1:k,:);
% El modelo sin actuadores aplica mandos limitados, no comandos brutos.
if ~act,r.U_real=r.U_acotado;r=f16lab.observe(r,act,wind);end
if nav
    r.navegacion=struct('waypoints_ned',[w(:,1:2),-w(:,3)],'tramo',navlog(1:k,1), ...
     'error_transversal_m',navlog(1:k,2),'error_espacial_m',navlog(1:k,3),'distancia_final_m',navlog(1:k,4),'finalizado',logical(navlog(k,5)));
    arc=[0;cumsum(vecnorm(diff(w(:,1:2)),2,2))];r.ruta_nominal_ned=interp1(arc,[w(:,1:2),-w(:,3)],linspace(0,arc(end),k)');
    r.metricas.rms_error_espacial_m=sqrt(mean(navlog(1:k,3).^2));r.metricas.max_error_espacial_m=max(navlog(1:k,3));r.metricas.distancia_final_m=navlog(k,4);r.metricas.ruta_completada=logical(navlog(k,5));
end
end
