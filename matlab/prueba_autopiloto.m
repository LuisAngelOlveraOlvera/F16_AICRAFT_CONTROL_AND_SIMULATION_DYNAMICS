% PRUEBA_AUTOPILOTO  Autopilotos de mision (Stevens & Lewis cap. 6) sobre el
%   modelo NO lineal 6-DOF CON dinamica de actuadores (funciones_act).
%
%   Longitudinal (LQR con integradores / LQI):
%       mantiene ALTITUD y VELOCIDAD:  u=[de,dth]
%       x_aug = [dVT dalfa dq dteta dP3 dalfaf dh  int_eh  int_eV]
%   Lateral (LQI de rumbo):
%       mantiene RUMBO coordinando alabeo: u=[da,dr]
%       x_aug = [beta p r fi psi  int_epsi]
%
%   Maniobra: escalon de +100 m de altitud y +20 deg de rumbo simultaneos.
%   El diseno usa la linealizacion; la simulacion es no lineal completa
%   con limites de posicion y razon en las superficies.
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

%% Trim y linealizacion
VT0=170; h0=3000; t0=0;
[Xtrim,Utrim,info] = trim_vuelo(VT0,h0,0,0,theta);
fprintf('TRIM: alfa=%.3f deg, de=%.3f deg, dth=%.4f\n',info.alfa_deg,info.de_deg,info.dth);
[A15,B15] = linmod_fd(t0,Xtrim,Utrim,theta);
teta_tr = 2*asin(Xtrim(11));

%% Subsistemas lineales (como en prueba_lqr / prueba_lqr_lat)
dq_dteta = [-0.5*sin(teta_tr/2); 0; 0.5*cos(teta_tr/2); 0];
colTeta  = A15(:,9:12)*dq_dteta;
mapLon = [3 4 7 0 1 2];
Alon=zeros(6,6); Blon=zeros(6,2);
for i=1:6
    fr=mapLon(i);
    if fr==0, Alon(i,:)=[0 0 1 0 0 0];
    else
        for j=1:6
            fj=mapLon(j);
            if fj==0, Alon(i,j)=colTeta(fr); else, Alon(i,j)=A15(fr,fj); end
        end
        Blon(i,:)=B15(fr,[1 4]);
    end
end
dq_dfi = [0; 0.5*cos(teta_tr/2); 0; -0.5*sin(teta_tr/2)];
colFi  = A15(:,9:12)*dq_dfi;
mapLat = [5 6 8 0];
Alat=zeros(4,4); Blat=zeros(4,2);
for i=1:4
    fr=mapLat(i);
    if fr==0, Alat(i,:)=[0 1 tan(teta_tr) 0];
    else
        for j=1:4
            fj=mapLat(j);
            if fj==0, Alat(i,j)=colFi(fr); else, Alat(i,j)=A15(fr,fj); end
        end
        Blat(i,:)=B15(fr,[2 3]);
    end
end

%% Autopiloto LONGITUDINAL (LQI de altitud + velocidad)
% dh_dot = VT0*(dteta - dalfa);  int_eh_dot = dh - href;  int_eV_dot = dVT
Aa = zeros(9,9); Ba = zeros(9,2);
Aa(1:6,1:6) = Alon;          Ba(1:6,:) = Blon;
Aa(7,:) = [0 -VT0 0 VT0 0 0 0 0 0];     % dh_dot
Aa(8,7) = 1;                            % int_eh_dot = dh (la ref entra aparte)
Aa(9,1) = 1;                            % int_eV_dot = dVT
% Pesos Bryson: VT~1 m/s, alfa~2deg, q~10dps, teta~5deg, h~5m, int moderados
Qa = diag([1, 1/(2*pi/180)^2, 1/(10*pi/180)^2, 1/(5*pi/180)^2, 1e-6, 1e-6, ...
           1/5^2, 1/50^2, 1/30^2]);
Ra = diag([1/5^2, 1/0.3^2]);
Klon = lqr_gain(Aa,Ba,Qa,Ra);

%% Autopiloto LATERAL (LQI de rumbo)
% psi_dot = r/cos(teta_tr);  int_epsi_dot = psi - psiref
Al = zeros(6,6); Bl = zeros(6,2);
Al(1:4,1:4) = Alat;          Bl(1:4,:) = Blat;
Al(5,3) = 1/cos(teta_tr);               % psi_dot
Al(6,5) = 1;                            % int_epsi_dot
Ql = diag([1/(1*pi/180)^2, 1/(20*pi/180)^2, 1/(10*pi/180)^2, ...
           1/(15*pi/180)^2, 1/(5*pi/180)^2, 1/(40*pi/180)^2]);
Rl = diag([1/15^2, 1/15^2]);
Klat = lqr_gain(Al,Bl,Ql,Rl);

%% Simulacion NO lineal con actuadores (18 estados)
href   = 100;                 % escalon de altitud [m]
psiref = 20*pi/180;           % escalon de rumbo [rad]
Xo = [Xtrim; Utrim(1); 0; 0]; % actuadores en su posicion de trim
ho=0.002; to=0; Tf=60; N=round(Tf/ho);
time=zeros(N+1,1); X=zeros(18,N+1); X(:,1)=Xo;
u_hist=zeros(4,N+1);
ieh=0; ieV=0; iepsi=0;
% Prefiltros de referencia (escalon suavizado, practica estandar para no
% golpear los integradores ni saturar actuadores)
tau_h = 4; tau_psi = 3;             % [s]
href_f = 0; psiref_f = 0;
for k=1:N
    href_f   = href_f   + ho*(href   - href_f)/tau_h;
    psiref_f = psiref_f + ho*(psiref - psiref_f)/tau_psi;
    q0k=Xo(9); q1k=Xo(10); q2k=Xo(11); q3k=Xo(12);
    teta_k = asin(max(-1,min(1,2*(q0k*q2k-q1k*q3k))));
    fi_k   = atan2(2*(q0k*q1k+q2k*q3k), q0k^2-q1k^2-q2k^2+q3k^2);
    psi_k  = atan2(2*(q1k*q2k+q0k*q3k), q0k^2+q1k^2-q2k^2-q3k^2);
    hk     = -Xo(15);
    % --- lazo longitudinal (LQI) ---
    xa = [Xo(3)-VT0; Xo(4)-Xtrim(4); Xo(7); teta_k-teta_tr; ...
          Xo(1)-Xtrim(1); Xo(2)-Xtrim(2); hk-h0; ieh; ieV];
    ul = [Utrim(1);Utrim(4)] - Klon*(xa - [zeros(6,1);href_f;0;0]);
    ieh = ieh + ((hk-h0)-href_f)*ho;
    ieV = ieV + (Xo(3)-VT0)*ho;
    % --- lazo lateral (LQI de rumbo) ---
    xl = [Xo(5); Xo(6); Xo(8); fi_k; psi_k; iepsi];
    ull = -Klat*(xl - [0;0;0;0;psiref_f;0]);
    iepsi = iepsi + (psi_k-psiref_f)*ho;
    % --- comandos (funciones_act aplica limites de actuador) ---
    de_c = ul(1); dth_c = min(max(ul(2),0),1);
    da_c = ull(1); dr_c = ull(2);
    U = [de_c,da_c,dr_c,dth_c]';
    u_hist(:,k)=[de_c;da_c;dr_c;dth_c];
    [tn,hn,Xn] = rkfv03(@funciones_act,to,ho,Xo,U,theta);
    to=tn; time(k+1)=tn; X(:,k+1)=Xn; Xo=Xn;
end
u_hist(:,N+1)=u_hist(:,N);

%% Graficas
t=time;
psi_hist = atan2(2*(X(10,:).*X(11,:)+X(9,:).*X(12,:)), ...
                 X(9,:).^2+X(10,:).^2-X(11,:).^2-X(12,:).^2);
fi_hist  = atan2(2*(X(9,:).*X(10,:)+X(11,:).*X(12,:)), ...
                 X(9,:).^2-X(10,:).^2-X(11,:).^2+X(12,:).^2);
figure('Name','Autopiloto: altitud + velocidad + rumbo (no lineal con actuadores)','NumberTitle','off');

subplot(3,2,1);
plot(t,-X(15,:),'b',[0 Tf],[h0+href h0+href],'k--','LineWidth',1.2); grid on;
xlabel('t [s]'); ylabel('h [m]'); title('Altitud (escalon +100 m)');

subplot(3,2,2);
plot(t,X(3,:),'b',[0 Tf],[VT0 VT0],'k--','LineWidth',1.2); grid on;
xlabel('t [s]'); ylabel('V_T [m/s]'); title('Velocidad (hold)');

subplot(3,2,3);
plot(t,psi_hist*180/pi,'b',[0 Tf],[1 1]*psiref*180/pi,'k--','LineWidth',1.2); grid on;
xlabel('t [s]'); ylabel('\psi [deg]'); title('Rumbo (escalon +20\circ)');

subplot(3,2,4);
plot(t,fi_hist*180/pi,'r',t,X(5,:)*180/pi,'b','LineWidth',1.0); grid on;
xlabel('t [s]'); ylabel('[deg]'); legend('\phi','\beta'); title('Alabeo y derrape');

subplot(3,2,5);
plot(t,X(16,:),'b',t,X(17,:),'r',t,X(18,:),'g','LineWidth',1.0); grid on;
xlabel('t [s]'); ylabel('[deg]'); legend('\delta_e','\delta_a','\delta_r');
title('Posiciones reales de superficies (con actuador)');

subplot(3,2,6);
plot(t,u_hist(4,:),'LineWidth',1.2); grid on;
xlabel('t [s]'); ylabel('\delta_{th}'); title('Mariposa');

figure('Name','Trayectoria 3D del autopiloto','NumberTitle','off');
plot_trayectoria3d(X(13,:),X(14,:),X(15,:), ...
    'Ascenso de +100 m con viraje de +20\circ (autopiloto)');
