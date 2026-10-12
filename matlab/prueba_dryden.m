% PRUEBA_DRYDEN  Vuelo de crucero en turbulencia de Dryden (moderada).
%   Compara el rechazo de perturbaciones estocasticas del avion:
%       (a) SIN control (controles congelados en trim)
%       (b) CON regulador LQR longitudinal + lateral
%   Ambos sobre el modelo no lineal con viento (funciones_viento) usando la
%   MISMA realizacion de turbulencia (misma semilla).
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

%% Trim, linealizacion y reguladores (mismo diseno que prueba_lqr_lat)
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
Klon = lqr_gain(Alon,Blon, diag([1/2^2,1/(1*pi/180)^2,1/(5*pi/180)^2,1/(2*pi/180)^2,1e-6,1e-6]), diag([1/5^2,1/0.2^2]));
Klat = lqr_gain(Alat,Blat, diag([1/(0.5*pi/180)^2,1/(10*pi/180)^2,1/(5*pi/180)^2,1/(5*pi/180)^2]), diag([1/10^2,1/10^2]));

%% Turbulencia: Dryden moderada a 3000 m
L     = [533 533 533];        % longitudes de escala [m]
sigma = [3 3 3];              % intensidad moderada [m/s]
rng(7);                       % misma realizacion para ambos casos
ho=0.002; Tf=30; N=round(Tf/ho);
W = randn(3,N);               % ruido comun

xlon_ref=[VT0;Xtrim(4);0;teta_tr;Xtrim(1);Xtrim(2)]; ulon_tr=[Utrim(1);Utrim(4)];
casos = {'Sin control','Con LQR'};
R = cell(1,2);                % resultados: [alfa;beta;fi;VT;gustw]
for c=1:2
    Xo=Xtrim; to=0; Xg=zeros(3,1);
    H=zeros(5,N+1); H(:,1)=[Xo(4);Xo(5);0;Xo(3);0];
    for k=1:N
        [gust,Xg]=dryden_paso(Xg,ho,Xo(3),L,sigma,W(:,k));
        if c==1
            U=[Utrim(1);Utrim(2);Utrim(3);Utrim(4);gust];
        else
            q0k=Xo(9); q1k=Xo(10); q2k=Xo(11); q3k=Xo(12);
            teta_k=asin(max(-1,min(1,2*(q0k*q2k-q1k*q3k))));
            fi_k=atan2(2*(q0k*q1k+q2k*q3k),q0k^2-q1k^2-q2k^2+q3k^2);
            xlon=[Xo(3);Xo(4);Xo(7);teta_k;Xo(1);Xo(2)];
            xlat=[Xo(5);Xo(6);Xo(8);fi_k];
            ul = ulon_tr - Klon*(xlon-xlon_ref);
            ua = -Klat*xlat;
            U=[min(max(ul(1),-25),25); min(max(ua(1),-21.5),21.5); ...
               min(max(ua(2),-30),30); min(max(ul(2),0),1); gust];
        end
        [tn,hn,Xn]=rkfv03(@funciones_viento,to,ho,Xo,U,theta);
        to=tn; Xo=Xn;
        fi_k=atan2(2*(Xo(9)*Xo(10)+Xo(11)*Xo(12)),Xo(9)^2-Xo(10)^2-Xo(11)^2+Xo(12)^2);
        H(:,k+1)=[Xo(4);Xo(5);fi_k;Xo(3);gust(3)];
    end
    R{c}=H;
    fprintf('%-12s: std(alfa)=%.3f deg  std(beta)=%.3f deg  std(fi)=%.2f deg  std(VT)=%.2f m/s\n',...
        casos{c}, std(R{c}(1,:))*180/pi, std(R{c}(2,:))*180/pi, ...
        std(R{c}(3,:))*180/pi, std(R{c}(4,:)));
end

%% Graficas
t=(0:N)*ho;
figure('Name','Turbulencia Dryden: sin control vs LQR','NumberTitle','off');
subplot(2,2,1);
plot(t,R{1}(1,:)*180/pi,'Color',[.6 .6 .6]); hold on;
plot(t,R{2}(1,:)*180/pi,'r','LineWidth',1.0); grid on;
xlabel('t [s]'); ylabel('\alpha [deg]'); legend('Sin control','Con LQR');
title('Angulo de ataque en turbulencia moderada');
subplot(2,2,2);
plot(t,R{1}(2,:)*180/pi,'Color',[.6 .6 .6]); hold on;
plot(t,R{2}(2,:)*180/pi,'r','LineWidth',1.0); grid on;
xlabel('t [s]'); ylabel('\beta [deg]'); title('Derrape');
subplot(2,2,3);
plot(t,R{1}(3,:)*180/pi,'Color',[.6 .6 .6]); hold on;
plot(t,R{2}(3,:)*180/pi,'r','LineWidth',1.0); grid on;
xlabel('t [s]'); ylabel('\phi [deg]'); title('Alabeo');
subplot(2,2,4);
plot(t,R{2}(5,:),'b','LineWidth',0.8); grid on;
xlabel('t [s]'); ylabel('w_g [m/s]'); title('Rafaga vertical (Dryden \sigma=3 m/s)');
