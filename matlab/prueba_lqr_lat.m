% PRUEBA_LQR_LAT  LQR lateral-direccional + longitudinal sobre el modelo
%   NO lineal completo de 6 GDL.
%
%   Lateral:      x_lat = [beta, p, r, fi]      u_lat = [da, dr]
%   Longitudinal: x_lon = [VT, alfa, q, theta, P3, alfaf]   u_lon = [de, dth]
%   Ambas ganancias se disenan sobre la linealizacion en el trim y se
%   aplican simultaneamente al modelo no lineal:
%       u = u_trim - K*(x - x_trim)
%   Prueba: perturbacion inicial de beta=+2 deg y fi=+10 deg.
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

%% 1) Trim y linealizacion
VT0 = 170; h0 = 3000; t0 = 0;
[Xtrim,Utrim,info] = trim_crucero(VT0,h0,theta);
fprintf('TRIM: alfa=%.3f deg, de=%.3f deg, dth=%.4f (residuo %.2e)\n',...
        info.alfa_deg, info.de_deg, info.dth, info.residuo);
[A15,B15] = linmod_fd(t0,Xtrim,Utrim,theta);
teta_tr = 2*asin(Xtrim(11));

%% 2) Subsistema LONGITUDINAL  x=[VT alfa q theta P3 alfaf], u=[de dth]
dq_dteta = [-0.5*sin(teta_tr/2); 0; 0.5*cos(teta_tr/2); 0];
colTeta  = A15(:,9:12)*dq_dteta;
mapLon = [3 4 7 0 1 2];                 % 0 = theta
Alon = zeros(6,6); Blon = zeros(6,2);
for i=1:6
    fr = mapLon(i);
    if fr==0
        Alon(i,:) = [0 0 1 0 0 0];      % theta_dot = q (alas a nivel)
    else
        for j=1:6
            fj = mapLon(j);
            if fj==0, Alon(i,j)=colTeta(fr); else, Alon(i,j)=A15(fr,fj); end
        end
        Blon(i,:) = B15(fr,[1 4]);
    end
end

%% 3) Subsistema LATERAL-DIRECCIONAL  x=[beta p r fi], u=[da dr]
% Columna d(f)/d(fi) via cuaterniones (fi=0, psi=0, theta=teta_tr):
dq_dfi = [0; 0.5*cos(teta_tr/2); 0; -0.5*sin(teta_tr/2)];
colFi  = A15(:,9:12)*dq_dfi;
mapLat = [5 6 8 0];                     % beta, p, r; 0 = fi
Alat = zeros(4,4); Blat = zeros(4,2);
for i=1:4
    fr = mapLat(i);
    if fr==0
        % fi_dot = p + tan(theta)*(q*sin(fi)+r*cos(fi)) -> [0 1 tan(teta_tr) 0]
        Alat(i,:) = [0 1 tan(teta_tr) 0];
    else
        for j=1:4
            fj = mapLat(j);
            if fj==0, Alat(i,j)=colFi(fr); else, Alat(i,j)=A15(fr,fj); end
        end
        Blat(i,:) = B15(fr,[2 3]);      % columnas da, dr
    end
end

fprintf('\nAutovalores lazo abierto lateral (dutch roll / rollido / espiral):\n');
disp(sort(eig(Alat)));

%% 4) Disenos LQR
Qlon = diag([1/2^2, 1/(1*pi/180)^2, 1/(5*pi/180)^2, 1/(2*pi/180)^2, 1e-6, 1e-6]);
Rlon = diag([1/5^2, 1/0.2^2]);
Klon = lqr_gain(Alon,Blon,Qlon,Rlon);

% Bryson lateral: beta~0.5 deg, p~10 deg/s, r~5 deg/s, fi~5 deg;
% controles da~10 deg, dr~10 deg
Qlat = diag([1/(0.5*pi/180)^2, 1/(10*pi/180)^2, 1/(5*pi/180)^2, 1/(5*pi/180)^2]);
Rlat = diag([1/10^2, 1/10^2]);
Klat = lqr_gain(Alat,Blat,Qlat,Rlat);
fprintf('Autovalores lazo cerrado lateral:\n');
disp(sort(eig(Alat-Blat*Klat)));

%% 5) Simulacion NO lineal 6-DOF con ambos lazos
% Perturbacion lateral: beta=+2 deg, fi=+10 deg
beta0 = 2*pi/180; fi0 = 10*pi/180;
q0=cos(0.5*fi0)*cos(0.5*teta_tr); q1=sin(0.5*fi0)*cos(0.5*teta_tr);
q2=cos(0.5*fi0)*sin(0.5*teta_tr); q3=-sin(0.5*fi0)*sin(0.5*teta_tr);
Xo = Xtrim; Xo(5)=beta0; Xo(9)=q0; Xo(10)=q1; Xo(11)=q2; Xo(12)=q3;

xlon_ref = [VT0; Xtrim(4); 0; teta_tr; Xtrim(1); Xtrim(2)];
xlat_ref = [0; 0; 0; 0];
ulon_tr  = [Utrim(1); Utrim(4)];

ho=0.002; to=0; Tf=15; N=round(Tf/ho);
time=zeros(N+1,1); X=zeros(15,N+1); X(:,1)=Xo;
u_hist=zeros(4,N+1);        % [de; da; dr; dth]
for k=1:N
    q0k=Xo(9); q1k=Xo(10); q2k=Xo(11); q3k=Xo(12);
    teta_k = asin(max(-1,min(1,2*(q0k*q2k-q1k*q3k))));
    fi_k   = atan2(2*(q0k*q1k+q2k*q3k), q0k^2-q1k^2-q2k^2+q3k^2);
    xlon = [Xo(3); Xo(4); Xo(7); teta_k; Xo(1); Xo(2)];
    xlat = [Xo(5); Xo(6); Xo(8); fi_k];
    ulon = ulon_tr - Klon*(xlon - xlon_ref);
    ulat =         - Klat*(xlat - xlat_ref);
    de = min(max(ulon(1),-25),25);
    dth= min(max(ulon(2),0),1);
    da = min(max(ulat(1),-21.5),21.5);
    dr = min(max(ulat(2),-30),30);
    U  = [de,da,dr,dth]';
    u_hist(:,k)=[de;da;dr;dth];
    [tn,hn,Xn] = rkfv03(@funciones,to,ho,Xo,U,theta);
    [to,time(k+1),ho,X(:,k+1),Xo] = act_edo(tn,hn,Xn);
end
u_hist(:,N+1)=u_hist(:,N);

%% 6) Graficacion
t=time;
fi_hist   = atan2(2*(X(9,:).*X(10,:)+X(11,:).*X(12,:)), ...
                  X(9,:).^2-X(10,:).^2-X(11,:).^2+X(12,:).^2);
figure('Name','LQR lateral+longitudinal sobre F-16 no lineal 6-DOF','NumberTitle','off');

subplot(3,2,1);
plot(t,X(5,:)*180/pi,'LineWidth',1.2); grid on;
xlabel('t [s]'); ylabel('\beta [deg]'); title('Derrape (perturbado +2\circ)');

subplot(3,2,2);
plot(t,fi_hist*180/pi,'LineWidth',1.2); grid on;
xlabel('t [s]'); ylabel('\phi [deg]'); title('Alabeo (perturbado +10\circ)');

subplot(3,2,3);
plot(t,X(6,:)*180/pi,'r',t,X(8,:)*180/pi,'b','LineWidth',1.0); grid on;
xlabel('t [s]'); ylabel('[deg/s]'); legend('p','r'); title('Velocidades angulares laterales');

subplot(3,2,4);
plot(t,u_hist(2,:),'r',t,u_hist(3,:),'b','LineWidth',1.0); grid on;
xlabel('t [s]'); ylabel('[deg]'); legend('\delta_a','\delta_r'); title('Controles laterales (LQR)');

subplot(3,2,5);
plot(t,X(3,:),'b',[0 Tf],[VT0 VT0],'k--','LineWidth',1.2); grid on;
xlabel('t [s]'); ylabel('V_T [m/s]'); title('Velocidad total (lazo longitudinal)');

subplot(3,2,6);
plot(t,X(4,:)*180/pi,'b',[0 Tf],[1 1]*info.alfa_deg,'k--','LineWidth',1.2); grid on;
xlabel('t [s]'); ylabel('\alpha [deg]'); title('Alfa (lazo longitudinal)');
