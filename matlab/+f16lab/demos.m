function records=demos(profile,cfg)
% Adaptador de prácticas: originales verificados contra los scripts README.
p=f16lab.parameters;[xt,ut,info]=trim_crucero(cfg.VT,cfg.altitud,p);
act=any(strcmp(profile,{'autopiloto','trayectoria_original'}));c=f16lab.design(xt,ut,cfg.weights,act,true);
t=(0:round(cfg.duracion/cfg.paso))'*cfg.paso;N=numel(t);dt=cfg.paso;a0=f16lab.angles(xt(9:12));
if strcmp(profile,'dryden_original'),cases=2;else,cases=1;end
stream=RandStream('mt19937ar','Seed',cfg.semilla);W=randn(stream,3,N-1);
for caseid=1:cases
    x=xt;
    if strcmp(profile,'pid')
        aa=cfg.pid.alpha_initial_deg*pi/180;x=[0;1.38*cfg.pid.alpha_initial_deg;cfg.VT;aa;0;0;0;0;f16lab.quaternion(0,aa,0);0;0;-cfg.altitud];
    end
    x=f16lab.perturb(x,cfg.initial);if act,x=[x;ut(1);0;0];end
    X=zeros(N,numel(x));U=zeros(N,4);G=zeros(N,3);ref=repmat([cfg.altitud cfg.VT 0],N,1);obj=ref;native_ref=ref;
    integral=zeros(3,1);gust=zeros(3,1);alpha_ref=zeros(N,1);href=cfg.altitud;psi_ref=0;
    if strcmp(profile,'trayectoria_original')
        uniform=RandStream('mt19937ar','Seed',cfg.semilla);nt=max(1,ceil(cfg.duracion/cfg.tramo));if cfg.original,nt=6;end
        targets=[cfg.altitud+[0;cfg.reference.trayectoria_h_m*(2*rand(uniform,nt-1,1)-1)],repmat(cfg.VT,nt,1),[0;cumsum(cfg.reference.trayectoria_rumbo_deg*pi/180*(2*rand(uniform,nt-1,1)-1))]];
    end
    if strcmp(profile,'comparacion')
        e=[xt(1:8);a0;xt(13:15)];e(4)=e(4)+cfg.initial.alpha_deg*pi/180;
        Hq=zeros(N,4);He=Hq;xl=zeros(6,1);xl(2)=cfg.initial.alpha_deg*pi/180;xp=xl;xk=xl;
        Xl=zeros(N,6);Xp=Xl;Xk=Xl;up=zeros(N,1);uk=zeros(N,2);
    end
    for k=1:N
        a=f16lab.angles(x(9:12));raw=ut;
        if strcmp(profile,'comparacion')
            Hq(k,:)=[x(4),asin(max(-1,min(1,2*(x(9)*x(11)-x(10)*x(12))))),x(3),x(7)];He(k,:)=e([4 10 3 7])';Xl(k,:)=xl';Xp(k,:)=xp';Xk(k,:)=xk';
        end
        if k<N
            if strcmp(profile,'pid')
                ar=cfg.pid.alpha_ref_deg;if cfg.original,ar=ref_alfa(x(3),x(15));end
                [raw,integral(1),de_raw]=pid(ar,x(4),x(7),integral(1),dt,cfg.pid);raw(1)=de_raw;alpha_ref(k)=ar;
            elseif any(strcmp(profile,{'lqr_longitudinal','lqr_lateral'}))||(strcmp(profile,'dryden_original')&&caseid==2)
                lon=[x(3);x(4);x(7);asin(max(-1,min(1,2*(x(9)*x(11)-x(10)*x(12)))));x(1);x(2)];
                ul=ut([1 4])-c.Klon*(lon-[cfg.VT;xt(4);0;a0(2);xt(1);xt(2)]);
                ua=[0;0];if ~strcmp(profile,'lqr_longitudinal'),ua=-c.Klat*[x(5);x(6);x(8);a(1)];end
                raw=[ul(1);ua;ul(2)];
            elseif act
                if strcmp(profile,'autopiloto')
                    % Prefiltros originales MATLAB; no sustituir por perfil Python.
                    href=href+dt*(cfg.altitud+cfg.reference.delta_h_m-href)/4;
                    psi_ref=psi_ref+dt*(cfg.reference.delta_psi_deg*pi/180-psi_ref)/3;
                    target=[cfg.altitud+cfg.reference.delta_h_m,cfg.VT,cfg.reference.delta_psi_deg*pi/180];
                else
                    target=targets(min(floor(t(k)/cfg.tramo)+1,size(targets,1)),:);
                    href=href+dt*max(-cfg.reference.h_rate_m_s,min(cfg.reference.h_rate_m_s,(target(1)-href)/2));
                    dp=atan2(sin(target(3)-psi_ref),cos(target(3)-psi_ref));limit=cfg.reference.psi_rate_deg_s*pi/180;
                    psi_ref=psi_ref+dt*max(-limit,min(limit,dp/2));
                end
                ref(k,:)=[href cfg.VT psi_ref];obj(k,:)=target;
                lon=[x(3)-cfg.VT;x(4)-xt(4);x(7);asin(max(-1,min(1,2*(x(9)*x(11)-x(10)*x(12)))))-a0(2);x(1)-xt(1);x(2)-xt(2);-x(15)-href;integral(1:2)];
                ep=a(3)-psi_ref;if strcmp(profile,'trayectoria_original'),ep=atan2(sin(ep),cos(ep));end
                lat=[x(5);x(6);x(8);a(1);ep;integral(3)];ul=ut([1 4])-c.Klon*lon;ua=-c.Klat*lat;raw=[ul(1);ua;ul(2)];
                integral=integral+dt*[-x(15)-href;x(3)-cfg.VT;ep];
            end
            if strcmp(profile,'dryden_original')
                z=cfg.turbulence;L=[z.length_u z.length_v z.length_w];sigma=[z.sigma_u z.sigma_v z.sigma_w];
                [gust,~]=dryden_paso(gust,dt,x(3),L,sigma,W(:,k));
            end
        elseif N>1
            raw=U(k-1,:)';ref(k,:)=ref(k-1,:);obj(k,:)=obj(k-1,:);alpha_ref(k)=alpha_ref(k-1);
        end
        bound=min(max(raw,[-25;-21.5;-30;0]),[25;21.5;30;1]);X(k,:)=x';U(k,:)=raw';G(k,:)=gust';
        if act,U(k,:)=raw';U(k,4)=bound(4);end
        if k==N,break;end
        if act,[~,~,x]=rkfv03(@funciones_act,t(k),dt,x,U(k,:)',p);
        elseif strcmp(profile,'dryden_original'),[~,~,x]=rkfv03(@funciones_viento,t(k),dt,x,[bound;gust],p);
        else,[~,~,x]=rkfv03(@funciones,t(k),dt,x,bound,p);end
        if act,native_ref(k+1,:)=[href cfg.VT psi_ref];end
        if strcmp(profile,'comparacion')
            [~,~,e]=rkfv03(@funciones_euler,t(k),dt,e,ut,p);
            [cmd,integral(1)]=pid(0,xp(2),xp(3),integral(1),dt,cfg.pid);cmd(4)=0;
            up(k)=cmd(1);uk(k,:)=-c.Klon*xk;
            xl=rk4(c.Alon,zeros(6,1),xl,dt);xp=rk4(c.Alon,c.Blon*[cmd(1);0],xp,dt);xk=rk4(c.Alon,c.Blon*uk(k,:)',xk,dt);
        end
        assert(all(isfinite(x))&&isreal(x)&&x(3)>1,'lab:Divergencia','Estado inválido t=%g s.',t(k+1));
    end
    cc=cfg;if strcmp(profile,'dryden_original'),if caseid==1,cc.escenario='dryden_abierto';else,cc.escenario='dryden_lqr';end,end
    applied_ref=ref;if strcmp(profile,'trayectoria_original')&&cfg.original,ref=native_ref;end
    r=f16lab.record(cc,t,X,U,xt,ut,info,c,ref,G);r.objetivo=obj;r.referencia_aplicada=applied_ref;
    if strcmp(profile,'pid'),r.referencia_alfa_deg=alpha_ref;end
    if strcmp(profile,'comparacion')
        up(end)=up(end-1);uk(end,:)=uk(end-1,:);
        r.Hq=Hq;r.He=He;r.Xl=Xl;r.Xp=Xp;r.Xk=Xk;r.up=up;r.uk=uk;
    end
    if strcmp(profile,'dryden_original')
        % H del script guarda viento usado tras cada paso y cero inicial.
        r.H=[X(:,4:5),r.angulos_rad(:,1),X(:,3),[0;G(1:end-1,3)]];
    end
    records{caseid}=r; %#ok<AGROW>
end
end

function [u,i,raw]=pid(ref,alpha,q,i,h,z)
e=ref-alpha*180/pi;de=-z.kp*e-z.ki*i+z.kq*q*180/pi;
if abs(de)<25,i=i+e*h;de=-z.kp*e-z.ki*i+z.kq*q*180/pi;end
raw=de;u=[min(max(de,-25),25);0;0;z.throttle];
end
function x=rk4(A,b,x,h)
k1=A*x+b;k2=A*(x+h*k1/2)+b;k3=A*(x+h*k2/2)+b;k4=A*(x+h*k3)+b;x=x+h*(k1+2*k2+2*k3+k4)/6;
end
