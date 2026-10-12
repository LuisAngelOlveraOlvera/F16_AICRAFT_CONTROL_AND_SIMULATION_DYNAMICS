% PRUEBA_TRAYECTORIA  Seguimiento de una TRAYECTORIA ALEATORIA con el
%   autopiloto (altitud + velocidad + rumbo) sobre el 6-DOF no lineal
%   CON actuadores. Es la prueba mas exigente del repo: comandos que
%   cambian aleatoriamente cada tramo y el control debe seguirlos.
%
%   - Cada DT_SEG segundos se sortea un nuevo objetivo de altitud y rumbo.
%   - Referencias pasan por prefiltros (escalones suavizados).
%   - El error de rumbo se envuelve a [-pi,pi] para permitir giros grandes.
%   - Salidas: trayectoria 3D coloreada por tiempo + seguimiento vs comando.
clc; clear; close all;

%% Parametros (identicos a pruebarkf)
g=9.80665; m=9295.44; S=27.87; b=9.144; cbar=3.45;
Xcgr=0.35; Xcg=0.30;
Ix=12874.8; Iy=75673.6; Iz=85552.1; Ixz=1331.4;
gama=Ix*Iz-Ixz^2;
c1=((Iy-Iz)*Iz-Ixz^2)/gama; c2=((Ix-Iy+Iz)*Ixz)/gama; c3=Iz/gama;
c4=Ixz/gama; c5=(Iz-Ix)/Iy; c6=Ixz/Iy; c7=1/Iy;
c8=(Ix*(Ix-Iy)+Ixz^2)/gama; c9=Ix/gama; Heng=216.9;
theta=[m,g,S,cbar,b,Xcgr,Xcg,c1,c2,c3,c4,c5,c6,c7,c8,c9,Heng,0,0]';

%% Trim, linealizacion y ganancias (mismo diseno que prueba_autopiloto)
VT0=170; h0=3000; t0=0;
[Xtrim,Utrim,info] = trim_vuelo(VT0,h0,0,0,theta);
[A15,B15] = linmod_fd(t0,Xtrim,Utrim,theta);
teta_tr = 2*asin(Xtrim(11));
dq_dteta=[-0.5*sin(teta_tr/2);0;0.5*cos(teta_tr/2);0]; colTeta=A15(:,9:12)*dq_dteta;
mapLon=[3 4 7 0 1 2]; Alon=zeros(6,6); Blon=zeros(6,2);
for i=1:6
    fr=mapLon(i);
    if fr==0, Alon(i,:)=[0 0 1 0 0 0];
    else
        for j=1:6, fj=mapLon(j);
            if fj==0, Alon(i,j)=colTeta(fr); else, Alon(i,j)=A15(fr,fj); end
        end
        Blon(i,:)=B15(fr,[1 4]);
    end
end
dq_dfi=[0;0.5*cos(teta_tr/2);0;-0.5*sin(teta_tr/2)]; colFi=A15(:,9:12)*dq_dfi;
mapLat=[5 6 8 0]; Alat=zeros(4,4); Blat=zeros(4,2);
for i=1:4
    fr=mapLat(i);
    if fr==0, Alat(i,:)=[0 1 tan(teta_tr) 0];
    else
        for j=1:4, fj=mapLat(j);
            if fj==0, Alat(i,j)=colFi(fr); else, Alat(i,j)=A15(fr,fj); end
        end
        Blat(i,:)=B15(fr,[2 3]);
    end
end
% LQI longitudinal (altitud+velocidad) y lateral (rumbo)
Aa=zeros(9,9); Ba=zeros(9,2);
Aa(1:6,1:6)=Alon; Ba(1:6,:)=Blon;
Aa(7,:)=[0 -VT0 0 VT0 0 0 0 0 0]; Aa(8,7)=1; Aa(9,1)=1;
Klon = lqr_gain(Aa,Ba, diag([1,1/(2*pi/180)^2,1/(10*pi/180)^2,1/(5*pi/180)^2,1e-6,1e-6,1/5^2,1/50^2,1/30^2]), diag([1/5^2,1/0.3^2]));
Al=zeros(6,6); Bl=zeros(6,2);
Al(1:4,1:4)=Alat; Bl(1:4,:)=Blat;
Al(5,3)=1/cos(teta_tr); Al(6,5)=1;
Klat = lqr_gain(Al,Bl, diag([1/(1*pi/180)^2,1/(20*pi/180)^2,1/(10*pi/180)^2,1/(15*pi/180)^2,1/(5*pi/180)^2,1/(40*pi/180)^2]), diag([1/15^2,1/15^2]));

%% Trayectoria aleatoria: cada DT_SEG s, nuevo objetivo de altitud y rumbo
rng(11);                       % semilla reproducible: cambiala para otra ruta
Tf     = 180;                  % duracion total [s]
DT_SEG = 30;                   % duracion de cada tramo [s]
nseg   = ceil(Tf/DT_SEG);
h_obj   = h0 + [0, 250*(2*rand(1,nseg-1)-1)];          % 3000 +-250 m
psi_obj = [0, cumsum(80*pi/180*(2*rand(1,nseg-1)-1))]; % pasos de hasta +-80 deg
fprintf('Tramos (h [m] / psi [deg]):\n');
for s=1:nseg, fprintf('  t=%3.0f s:  h=%6.1f   psi=%7.1f\n',(s-1)*DT_SEG,h_obj(s),psi_obj(s)*180/pi); end

%% Simulacion no lineal con actuadores
wrap = @(a) atan2(sin(a),cos(a));
Xo=[Xtrim; Utrim(1); 0; 0];
ho=0.002; to=0; N=round(Tf/ho);
time=zeros(N+1,1); X=zeros(18,N+1); X(:,1)=Xo;
ref_hist=zeros(2,N+1);         % [h_ref_filtrada; psi_ref_filtrada]
ieh=0; ieV=0; iepsi=0;
% Referencias con LIMITE DE RAZON (como un autopiloto real):
% ascenso/descenso max 10 m/s; razon de viraje max 3 deg/s (viraje estandar)
hdot_max   = 10;            % [m/s]
psidot_max = 3*pi/180;      % [rad/s]
href_f=h0; psiref_f=0;
for k=1:N
    tk = (k-1)*ho;
    s  = min(floor(tk/DT_SEG)+1, nseg);
    href_f   = href_f   + ho*min(max((h_obj(s)-href_f)/2,   -hdot_max),  hdot_max);
    psiref_f = psiref_f + ho*min(max(wrap(psi_obj(s)-psiref_f)/2,-psidot_max),psidot_max);
    q0k=Xo(9); q1k=Xo(10); q2k=Xo(11); q3k=Xo(12);
    teta_k=asin(max(-1,min(1,2*(q0k*q2k-q1k*q3k))));
    fi_k  =atan2(2*(q0k*q1k+q2k*q3k),q0k^2-q1k^2-q2k^2+q3k^2);
    psi_k =atan2(2*(q1k*q2k+q0k*q3k),q0k^2+q1k^2-q2k^2-q3k^2);
    hk = -Xo(15);
    % lazo longitudinal (LQI altitud + velocidad)
    xa=[Xo(3)-VT0; Xo(4)-Xtrim(4); Xo(7); teta_k-teta_tr; ...
        Xo(1)-Xtrim(1); Xo(2)-Xtrim(2); hk-h0; ieh; ieV];
    ul=[Utrim(1);Utrim(4)] - Klon*(xa-[zeros(6,1);href_f-h0;0;0]);
    ieh=ieh+((hk-h0)-(href_f-h0))*ho;  ieV=ieV+(Xo(3)-VT0)*ho;
    % lazo lateral (LQI rumbo con error envuelto)
    e_psi = wrap(psi_k-psiref_f);
    xl=[Xo(5); Xo(6); Xo(8); fi_k; e_psi; iepsi];
    ull=-Klat*xl;
    iepsi=iepsi+e_psi*ho;
    U=[ul(1); ull(1); ull(2); min(max(ul(2),0),1)];
    [tn,hn,Xn]=rkfv03(@funciones_act,to,ho,Xo,U,theta);
    to=tn; time(k+1)=tn; X(:,k+1)=Xn; Xo=Xn;
    ref_hist(:,k+1)=[href_f; psiref_f];
end
ref_hist(:,1)=[h0;0];

%% Graficas
t=time;
psi_hist=atan2(2*(X(10,:).*X(11,:)+X(9,:).*X(12,:)), ...
               X(9,:).^2+X(10,:).^2-X(11,:).^2-X(12,:).^2);
fi_hist =atan2(2*(X(9,:).*X(10,:)+X(11,:).*X(12,:)), ...
               X(9,:).^2-X(10,:).^2-X(11,:).^2+X(12,:).^2);

figure('Name','Trayectoria 3D: ruta aleatoria con autopiloto','NumberTitle','off');
plot_trayectoria3d(X(13,:),X(14,:),X(15,:), ...
    sprintf('Ruta aleatoria de %d tramos seguida por el autopiloto (semilla rng=11)',nseg));

figure('Name','Seguimiento de la trayectoria aleatoria','NumberTitle','off');
subplot(3,2,1);
plot(t,-X(15,:),'b',t,ref_hist(1,:),'k--','LineWidth',1.2); grid on;
xlabel('t [s]'); ylabel('h [m]'); legend('real','comando'); title('Altitud');
subplot(3,2,2);
plot(t,unwrap(psi_hist)*180/pi,'b',t,unwrap(ref_hist(2,:))*180/pi,'k--','LineWidth',1.2); grid on;
xlabel('t [s]'); ylabel('\psi [deg]'); title('Rumbo');
subplot(3,2,3);
plot(t,X(3,:),'b',[0 Tf],[VT0 VT0],'k--','LineWidth',1.2); grid on;
xlabel('t [s]'); ylabel('V_T [m/s]'); title('Velocidad (hold)');
subplot(3,2,4);
plot(t,fi_hist*180/pi,'r',t,X(5,:)*180/pi,'b','LineWidth',1.0); grid on;
xlabel('t [s]'); ylabel('[deg]'); legend('\phi','\beta'); title('Alabeo y derrape');
subplot(3,2,5);
plot(t,X(16,:),'b',t,X(17,:),'r',t,X(18,:),'g','LineWidth',0.9); grid on;
xlabel('t [s]'); ylabel('[deg]'); legend('\delta_e','\delta_a','\delta_r');
title('Superficies (con actuador)');
subplot(3,2,6);
plot(t,X(4,:)*180/pi,'LineWidth',1.0); grid on;
xlabel('t [s]'); ylabel('\alpha [deg]'); title('Angulo de ataque');

%% Metricas de seguimiento
eh   = (-X(15,:))-ref_hist(1,:);
epsi = atan2(sin(psi_hist-ref_hist(2,:)),cos(psi_hist-ref_hist(2,:)));
fprintf('Seguimiento: rms(e_h)=%.2f m  rms(e_psi)=%.2f deg  rms(e_V)=%.3f m/s\n',...
        rms(eh), rms(epsi)*180/pi, rms(X(3,:)-VT0));
