% PRUEBA_LQR  Control LQR longitudinal disenado sobre la linealizacion y
%   aplicado al modelo NO lineal completo de 6 GDL (15 estados).
%
%   Flujo:  trim_crucero -> linmod_fd -> modelo longitudinal reducido ->
%           lqr_gain -> simulacion no lineal en lazo cerrado (rkfv03).
%
%   Estados longitudinales:  x = [VT, alfa, q, theta, P3, alfaf]
%   Controles:               u = [de, dth]
%   La ganancia se disena en el modelo LINEAL; el control se APLICA sobre
%   el modelo no lineal:  u = u_trim - K*(x - x_trim).
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

%% 1) Trim en crucero
VT0 = 170; h0 = 3000;
[Xtrim,Utrim,info] = trim_crucero(VT0,h0,theta);
fprintf('TRIM: alfa=%.3f deg, de=%.3f deg, dth=%.4f (residuo %.2e, converge=%d)\n',...
        info.alfa_deg, info.de_deg, info.dth, info.residuo, info.converge);

%% 2) Linealizacion completa y extraccion del subsistema longitudinal
t0 = 0;
[A15,B15] = linmod_fd(t0,Xtrim,Utrim,theta);

% Indices en el estado de 15: P3=1, alfaf=2, VT=3, alfa=4, q=7, q0..q3=9..12
teta_tr = 2*asin(Xtrim(11));        % theta de trim (q2=sin(theta/2), alas a nivel)
% Columna d(f)/d(theta) via cadena por los cuaterniones (fi=psi=0):
dq_dteta = [-0.5*sin(teta_tr/2); 0; 0.5*cos(teta_tr/2); 0];   % [q0;q1;q2;q3]
colTeta  = A15(:,9:12)*dq_dteta;

% x_lon = [VT, alfa, q, theta, P3, alfaf]
Alon = zeros(6,6);
map  = [3 4 7 0 1 2];               % 0 = theta (columna especial)
for i=1:6
    fi_row = map(i);
    if fi_row==0
        % fila de theta: theta_dot = q (alas a nivel)
        Alon(i,:) = [0 0 1 0 0 0];
    else
        for j=1:6
            fj = map(j);
            if fj==0
                Alon(i,j) = colTeta(fi_row);
            else
                Alon(i,j) = A15(fi_row,fj);
            end
        end
    end
end
Blon = zeros(6,2);                  % columnas: de, dth
for i=1:6
    fi_row = map(i);
    if fi_row>0
        Blon(i,:) = B15(fi_row,[1 4]);
    end
end

fprintf('\nAutovalores en lazo abierto (longitudinal):\n');
disp(sort(eig(Alon)));

%% 3) Diseno LQR
% Pesos (Bryson): desviaciones tolerables VT~2 m/s, alfa~1 deg, q~5 deg/s,
% theta~2 deg, P3/alfaf libres; controles de~5 deg, dth~0.2
Q = diag([1/2^2, 1/(1*pi/180)^2, 1/(5*pi/180)^2, 1/(2*pi/180)^2, 1e-6, 1e-6]);
R = diag([1/5^2, 1/0.2^2]);
[K,~] = lqr_gain(Alon,Blon,Q,R);
fprintf('Autovalores en lazo cerrado (A-BK):\n');
disp(sort(eig(Alon-Blon*K)));

%% 4) Simulacion NO lineal 6-DOF en lazo cerrado
% Perturbacion inicial respecto al trim + escalon de referencia en theta
Xo = Xtrim;
Xo(4) = Xtrim(4) + 3*pi/180;        % +3 deg de alfa (rafaga vertical)
alfa0 = Xo(4);
Xo(9)=cos(0.5*teta_tr); Xo(11)=sin(0.5*teta_tr);   % actitud de trim

xlon_ref = [VT0; Xtrim(4); 0; teta_tr; Xtrim(1); Xtrim(2)];
u_trim   = [Utrim(1); Utrim(4)];

ho=0.002; to=0; Tf=20; N=round(Tf/ho);
time=zeros(N+1,1); X=zeros(15,N+1); X(:,1)=Xo;
de_hist=zeros(N+1,1); dth_hist=zeros(N+1,1);
for k=1:N
    % Estado longitudinal medido del modelo no lineal
    q0k=Xo(9); q1k=Xo(10); q2k=Xo(11); q3k=Xo(12);
    teta_k = asin(max(-1,min(1,2*(q0k*q2k-q1k*q3k))));
    xlon = [Xo(3); Xo(4); Xo(7); teta_k; Xo(1); Xo(2)];
    % Ley LQR sobre el no lineal + saturaciones fisicas
    u  = u_trim - K*(xlon - xlon_ref);
    de = min(max(u(1),-25),25);
    dth= min(max(u(2),0),1);
    U  = [de,0,0,dth]';
    de_hist(k)=de; dth_hist(k)=dth;
    [tn,hn,Xn] = rkfv03(@funciones,to,ho,Xo,U,theta);
    [to,time(k+1),ho,X(:,k+1),Xo] = act_edo(tn,hn,Xn);
end
de_hist(N+1)=de_hist(N); dth_hist(N+1)=dth_hist(N);

%% 5) Graficacion
t=time;
teta_hist = asin(max(-1,min(1,2*(X(9,:).*X(11,:)-X(10,:).*X(12,:)))));
figure('Name','LQR longitudinal sobre F-16 no lineal 6-DOF','NumberTitle','off');

subplot(3,2,1);
plot(t,X(3,:),'b',[0 Tf],[VT0 VT0],'k--','LineWidth',1.2); grid on;
xlabel('t [s]'); ylabel('V_T [m/s]'); title('Velocidad total');

subplot(3,2,2);
plot(t,X(4,:)*180/pi,'b',[0 Tf],[1 1]*info.alfa_deg,'k--','LineWidth',1.2); grid on;
xlabel('t [s]'); ylabel('\alpha [deg]');
title(sprintf('Alfa (perturbado +3\\circ, trim %.2f\\circ)',info.alfa_deg));

subplot(3,2,3);
plot(t,X(7,:)*180/pi,'LineWidth',1.2); grid on;
xlabel('t [s]'); ylabel('q [deg/s]'); title('Velocidad de cabeceo');

subplot(3,2,4);
plot(t,teta_hist*180/pi,'b',[0 Tf],[1 1]*teta_tr*180/pi,'k--','LineWidth',1.2); grid on;
xlabel('t [s]'); ylabel('\theta [deg]'); title('Angulo de cabeceo');

subplot(3,2,5);
plot(t,de_hist,'LineWidth',1.2); grid on;
xlabel('t [s]'); ylabel('\delta_e [deg]'); title('Elevador (LQR)');

subplot(3,2,6);
plot(t,dth_hist,'LineWidth',1.2); grid on;
xlabel('t [s]'); ylabel('\delta_{th}'); title('Mariposa (LQR)');
