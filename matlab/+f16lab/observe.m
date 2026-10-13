function r=observe(r,act,wind)
% Magnitudes físicas derivadas de las funciones originales, sin otra planta.
X=r.X;n=size(X,1);p=r.theta;
r.angulos_rad=zeros(n,3);r.altitud_m=-X(:,15);r.norma_cuaternion=vecnorm(X(:,9:12),2,2);
r.Mach=zeros(n,1);r.qbar_Pa=r.Mach;r.LEF_deg=r.Mach;r.empuje_N=r.Mach;
r.fuerzas_N=zeros(n,3);r.momentos_Nm=zeros(n,3);r.derivadas=zeros(size(X));
for k=1:n
    x=X(k,:)';u=r.U_real(k,:)';g=r.rafaga_m_s(k,:)';a=x(4);b=x(5);v=x(3);
    r.angulos_rad(k,:)=f16lab.angles(x(9:12))';[~,ps,rho,sound]=atmosfera(-x(15));
    if wind,v=v-g(1);a=a+g(3)/x(3);b=b+g(2)/x(3);end
    qb=.5*rho*v^2;lef=hlef(0,x(2),[a qb ps],p);f=hu(0,[v;a;b;x(6:8)],[u(1:3);qb;lef],p);th=FT(x(1),x(3)/sound,x(15));
    r.Mach(k)=x(3)/sound;r.qbar_Pa(k)=qb;r.LEF_deg(k)=lef;r.empuje_N(k)=th;
    r.fuerzas_N(k,:)=f(1:3)';r.momentos_Nm(k,:)=f([5 6 4])';
    if act,dx=funciones_act(r.t(k),x,r.U_acotado(k,:)',p);
    elseif wind,dx=funciones_viento(r.t(k),x,[u;g],p);
    else,dx=funciones(r.t(k),x,u,p);end
    r.derivadas(k,:)=dx';
end
r.an_g=-r.fuerzas_N(:,3)/(p(1)*p(2));r.saturacion_comando=abs(r.U_comando-r.U_acotado)>1e-10;
err=[r.altitud_m-r.referencia(:,1),X(:,3)-r.referencia(:,2),atan2(sin(r.angulos_rad(:,3)-r.referencia(:,3)),cos(r.angulos_rad(:,3)-r.referencia(:,3)))];
r.metricas=struct('rms_altitud_m',sqrt(mean(err(:,1).^2)),'rms_velocidad_m_s',sqrt(mean(err(:,2).^2)), ...
 'rms_rumbo_deg',sqrt(mean(err(:,3).^2))*180/pi,'max_error_norma_quat',max(abs(r.norma_cuaternion-1)),'fraccion_saturacion',mean(r.saturacion_comando,1));
if ~isfield(r,'ruta_nominal_ned')
    dh=zeros(n,1);if n>1,dh=gradient(r.referencia(:,1),r.config.paso);end
    if n==1,r.ruta_nominal_ned=[0 0 -r.referencia(1,1)];
    else,vh=sqrt(max(0,r.referencia(:,2).^2-dh.^2));r.ruta_nominal_ned=[cumtrapz(r.t,vh.*cos(r.referencia(:,3))),cumtrapz(r.t,vh.*sin(r.referencia(:,3))),-r.referencia(:,1)];end
end
r.etiqueta_ruta='Referencia cinemática; usar waypoints para seguimiento espacial';
r.unidades=struct('X','15/18 estados; SI/rad; alfaf grados','U','de/da/dr grados; throttle [0,1]','posicion','NED metros');
end
