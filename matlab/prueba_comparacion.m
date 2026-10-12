% PRUEBA_COMPARACION  Dos comparaciones clave del simulador:
%
%   FIGURA 1 - Formulaciones equivalentes del modelo NO lineal:
%       (a) cuaterniones + ejes viento   (funciones.m, la sim principal)
%       (b) angulos de Euler + ejes viento (funciones_euler.m)
%       Deben superponerse (misma fisica, distinta cinematica de actitud).
%
%   FIGURA 2 - Resultados graficos del control (respuesta a rafaga +3 deg en alfa):
%       (1) NO lineal en lazo abierto      (controles congelados en trim)
%       (2) LINEAL en lazo abierto         (x_dot = A x)
%       (3) LINEAL + PID                   (mismas ganancias de ctrl_PID)
%       (4) LINEAL + LQR                   (x_dot = (A-BK) x)
%       Aqui se ve: la linealizacion reproduce al no lineal cerca del trim,
%       y como cada controlador mejora la respuesta del avion sin control.
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
[Xtrim,Utrim,info] = trim_crucero(VT0,h0,theta);
teta_tr = 2*asin(Xtrim(11));
[A15,B15] = linmod_fd(t0,Xtrim,Utrim,theta);

% Subsistema longitudinal x=[VT alfa q theta P3 alfaf], u=[de dth]
dq_dteta = [-0.5*sin(teta_tr/2); 0; 0.5*cos(teta_tr/2); 0];
colTeta  = A15(:,9:12)*dq_dteta;
mapLon = [3 4 7 0 1 2];
Alon=zeros(6,6); Blon=zeros(6,2);
for i=1:6
    fr=mapLon(i);
    if fr==0
        Alon(i,:)=[0 0 1 0 0 0];
    else
        for j=1:6
            fj=mapLon(j);
            if fj==0, Alon(i,j)=colTeta(fr); else, Alon(i,j)=A15(fr,fj); end
        end
        Blon(i,:)=B15(fr,[1 4]);
    end
end

%% Condiciones de la prueba: rafaga de +3 deg en alfa
dalfa0 = 3*pi/180;
ho=0.002; Tf=15; N=round(Tf/ho); t=(0:N)'*ho;

%% ================= FIGURA 1: cuaterniones vs Euler =====================
% (a) cuaterniones (funciones.m), 15 estados
Xq = Xtrim; Xq(4)=Xq(4)+dalfa0;
% (b) Euler (funciones_euler.m), 14 estados: mismo punto fisico
Xe = [Xtrim(1); Xtrim(2); Xtrim(3); Xtrim(4)+dalfa0; 0; 0;0;0; ...
      0; teta_tr; 0; 0; 0; Xtrim(15)];

Hq=zeros(4,N+1); He=zeros(4,N+1);   % [alfa; teta; VT; q]
to=0; Xo=Xq;
for k=1:N+1
    tetaq = asin(max(-1,min(1,2*(Xo(9)*Xo(11)-Xo(10)*Xo(12)))));
    Hq(:,k)=[Xo(4); tetaq; Xo(3); Xo(7)];
    if k<=N, [to,~,Xo]=paso(@funciones,to,ho,Xo,Utrim,theta); end
end
to=0; Xo=Xe;
for k=1:N+1
    He(:,k)=[Xo(4); Xo(10); Xo(3); Xo(7)];
    if k<=N, [to,~,Xo]=paso(@funciones_euler,to,ho,Xo,Utrim,theta); end
end

figure('Name','Formulaciones: cuaterniones vs Euler','NumberTitle','off');
etiq={'\alpha [deg]','\theta [deg]','V_T [m/s]','q [deg/s]'};
esc =[180/pi,180/pi,1,180/pi];
for i=1:4
    subplot(2,2,i);
    plot(t,Hq(i,:)*esc(i),'b',t,He(i,:)*esc(i),'r--','LineWidth',1.2); grid on;
    xlabel('t [s]'); ylabel(etiq{i});
    if i==1, legend('Cuaterniones (funciones)','Euler (funciones\_euler)'); end
end
sgtitle('Modelo no lineal: misma fisica con dos cinematicas de actitud');
fprintf('Discrepancia max cuaterniones vs Euler: alfa %.2e deg, theta %.2e deg\n',...
    max(abs(Hq(1,:)-He(1,:)))*180/pi, max(abs(Hq(2,:)-He(2,:)))*180/pi);

%% ============ FIGURA 2: no lineal vs lineal vs PID vs LQR ==============
% Estado de desviacion longitudinal: dx = [dVT; dalfa; dq; dteta; dP3; dalfaf]
dx0 = [0; dalfa0; 0; 0; 0; 0];

% (1) NO lineal lazo abierto (ya calculado: Hq)
% (2) LINEAL lazo abierto: dx_dot = Alon*dx  (controles en trim)
% (3) LINEAL + PID (mismas ganancias que ctrl_PID, sobre la planta lineal)
% (4) LINEAL + LQR: dx_dot = (Alon - Blon*K)*dx
Qb = diag([1/2^2, 1/(1*pi/180)^2, 1/(5*pi/180)^2, 1/(2*pi/180)^2, 1e-6, 1e-6]);
Rb = diag([1/5^2, 1/0.2^2]);
K  = lqr_gain(Alon,Blon,Qb,Rb);

Kp=5.0; Ki=1.5; Kq=0.8;             % ganancias de ctrl_PID
Xl  = zeros(6,N+1); Xl(:,1)=dx0;    % lineal abierto
Xp  = zeros(6,N+1); Xp(:,1)=dx0;    % lineal + PID
Xk  = zeros(6,N+1); Xk(:,1)=dx0;    % lineal + LQR
up  = zeros(1,N+1); uk = zeros(2,N+1);
ie=0;
for k=1:N
    % lineal abierto
    Xl(:,k+1) = rk4lin(Alon,zeros(6,1),Xl(:,k),ho);
    % lineal + PID: de actua sobre el error de alfa (en grados), dth fijo
    e_deg  = -Xp(2,k)*180/pi;                % ref=trim => error = -dalfa
    q_deg  =  Xp(3,k)*180/pi;
    d_de   = -Kp*e_deg - Ki*ie + Kq*q_deg;   % desviacion de elevador [deg]
    if abs(d_de)<25, ie = ie + e_deg*ho; d_de = -Kp*e_deg - Ki*ie + Kq*q_deg; end
    d_de   = min(max(d_de,-25),25);
    up(k)  = d_de;
    Xp(:,k+1) = rk4lin(Alon,Blon*[d_de;0],Xp(:,k),ho);
    % lineal + LQR
    u2 = -K*Xk(:,k); uk(:,k)=u2;
    Xk(:,k+1) = rk4lin(Alon,Blon*u2,Xk(:,k),ho);
end
up(N+1)=up(N); uk(:,N+1)=uk(:,N);

% Series de alfa y q (desviaciones respecto al trim) para las 4 variantes
alfa_nl = (Hq(1,:)-Xtrim(4))*180/pi;
figure('Name','No lineal vs Lineal vs Lineal+PID vs Lineal+LQR','NumberTitle','off');

subplot(2,2,1);
plot(t,alfa_nl,'k',t,Xl(2,:)*180/pi,'b--',t,Xp(2,:)*180/pi,'g',t,Xk(2,:)*180/pi,'r','LineWidth',1.2);
grid on; xlabel('t [s]'); ylabel('\Delta\alpha [deg]');
legend('No lineal (abierto)','Lineal (abierto)','Lineal + PID','Lineal + LQR');
title('Angulo de ataque (desviacion del trim)');

subplot(2,2,2);
plot(t,(Hq(4,:))*180/pi,'k',t,Xl(3,:)*180/pi,'b--',t,Xp(3,:)*180/pi,'g',t,Xk(3,:)*180/pi,'r','LineWidth',1.2);
grid on; xlabel('t [s]'); ylabel('\Delta q [deg/s]'); title('Velocidad de cabeceo');

subplot(2,2,3);
plot(t,(Hq(3,:)-VT0),'k',t,Xl(1,:),'b--',t,Xp(1,:),'g',t,Xk(1,:),'r','LineWidth',1.2);
grid on; xlabel('t [s]'); ylabel('\DeltaV_T [m/s]'); title('Velocidad total');

subplot(2,2,4);
plot(t,up,'g',t,uk(1,:),'r','LineWidth',1.2); grid on;
xlabel('t [s]'); ylabel('\Delta\delta_e [deg]');
legend('PID','LQR'); title('Esfuerzo de control (elevador)');
sgtitle('Respuesta a rafaga de +3\circ en \alpha');

%% ---------------------------------------------------------------------
function [tn,hn,Xn]=paso(f,to,h,Xo,U,theta)
    [tn,hn,Xn]=rkfv03(f,to,h,Xo,U,theta);
end
function xn = rk4lin(A,bu,x,h)
    f=@(x) A*x+bu;
    k1=f(x); k2=f(x+0.5*h*k1); k3=f(x+0.5*h*k2); k4=f(x+h*k3);
    xn = x + h/6*(k1+2*k2+2*k3+k4);
end
