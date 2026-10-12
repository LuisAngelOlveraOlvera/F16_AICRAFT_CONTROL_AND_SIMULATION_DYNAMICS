clc
clear all
close all
g  = 9.80665;         % [g]=m/s^2
%%  Par�metros para un F16
m    = 9295.44;         % [m]=kg
S    = 27.87;           % [A]=m^2 (�rea del ala)
b    = 9.144;           % [b]=m (referencia de la envergadura del ala)
cbar = 3.45;            % [cbar]=m (cuerda media aerodin�mica)
Xcgr = 0.35;            % referencia c.g. (adimensional, fraccion de cbar)
Xcg  = 0.30;            % localizacion c.g. (adimensional, fraccion de cbar)
%%  Productos de inercia
Ix  = 12874.8; % Producto de inercia del cabeceo = [kg*m^2]
Iy  = 75673.6; % Producto de inercia del gui�ado = [kg*m^2]
Iz  = 85552.1; % Productos de momento de inercia = [kg*m^2]
Ixz = 1331.4;
Ixy =0;
Iyz =0;
%%  Determinante del tensor de inercia
gama = Ix*Iz-Ixz^2;
%%  Constantes
c1 = ((Iy-Iz)*Iz-Ixz^2)/gama;
c2 = ((Ix-Iy+Iz)*Ixz)/gama;
c3 = Iz/gama;
c4 = Ixz/gama;
c5 = (Iz-Ix)/Iy;
c6 = (Ixz)/Iy;
c7 = 1/Iy;
c8 = (Ix*(Ix-Iy)+Ixz^2)/gama;
c9 = Ix/gama;
%%  Par�metros del motor
Heng  = 216.9;         % [Heng]=kg.m^2/2 (momento angular del motor).
%%      Condiciones iniciales (crucero subs�nico realista)
%   El modelo aerodin�mico (NASA/Nguyen) es de baja velocidad: v�lido en
%   r�gimen subs�nico. Condici�n t�pica: ~170 m/s (M~0.52) a 3000 m.
%      �ngulos de orientaci�n
fi   = 0;
teta = 2*pi/180;    % cabeceo inicial ~ alfa de trim (vuelo casi nivelado)
psi  = 0;
%    Superficies de control (grados) y mariposa
de   = 0;                               % Deflexi�n del elevador [deg]
da   = 0;                               % Deflexi�n de alerones [deg]
dr   = 0;                               % Deflexi�n del tim�n [deg]
dth  = 0.35;                            % Mariposa del motor (crucero parcial)
%%  Estados
alfa  = 2*pi/180;   % [rad] cerca del alfa de trim para arrancar suave
beta  = 0;          % [rad]
VT    = 170;        % [m/s] (M ~ 0.52 a 3000 m)
p     = 0;  % Velocidad angular del alabeo X(4).
q     = 0;  % Velocidad angular del cabeceo X(5).
r     = 0;  % Velocidad angular del gui�ado X(6).
%   Definici�n de Cuaternios
q0 = cos(0.5*fi)*cos(0.5*teta)*cos(0.5*psi)+sin(0.5*fi)*sin(0.5*teta)*sin(0.5*psi);
q1 = sin(0.5*fi)*cos(0.5*teta)*cos(0.5*psi)-cos(0.5*fi)*sin(0.5*teta)*sin(0.5*psi);
q2 = cos(0.5*fi)*sin(0.5*teta)*cos(0.5*psi)+sin(0.5*fi)*cos(0.5*teta)*sin(0.5*psi);
q3 = cos(0.5*fi)*cos(0.5*teta)*sin(0.5*psi)-sin(0.5*fi)*sin(0.5*teta)*cos(0.5*psi);
%  Vector de orientaci�n en marco de referencia fijo para la tierra (NED)
xE = 0;
yE = 0;
zE = -3000;         % [m] 3000 m de altitud (zE positivo hacia abajo)
%%
alfaf = 1.38*(alfa*180/pi);   % estado del filtro LEF en su valor estacionario
P3=0;
% Construcci�n de vectores
%   Posici�n de los estados
%     1    2    3     4   5   6  7  8  9   10  11  12  13   14  15
Xo = [P3,alfaf,VT, alfa,beta, p, q, r, q0, q1, q2, q3, xE,  yE, zE]';
theta = [m,g,S,cbar,b,Xcgr,Xcg,c1,c2,c3,c4,c5,c6,c7,c8,c9,Heng,teta,fi]';
%%  Runge-Kutta (paso fijo)
ho = 0.002;     % Tama�o de paso [s]
to = 0;         % Tiempo inicial
Tf = 15;        % Tiempo final de simulaci�n [s]
N  = round(Tf/ho);
time=zeros(N+1,1);
X=zeros(15,N+1);
X(:,1)=Xo;
de_hist   = zeros(N+1,1);   % historial del elevador [deg]
dlef_hist = zeros(N+1,1);   % historial del LEF [deg]
ref_hist  = zeros(N+1,1);   % referencia de alfa [deg]
ie = 0;                     % integral del error de alfa (para el PID)
for k=1:N
    % Refrescar estados usados por el control desde el estado actual Xo
    VT   = Xo(3);
    alfa = Xo(4);
    q    = Xo(7);
    zE   = Xo(15);
    ref  = ref_alfa(VT,zE);
    [U,ie] = ctrl_PID(ref,alfa,q,ie,ho,dth);
    % Registro para graficaci�n
    [~,Ps,Rho,~] = atmosfera(-zE);   % NED: altitud h = -zE
    qbar = 0.5*Rho*VT^2;
    de_hist(k)   = U(1);
    dlef_hist(k) = hlef(to,Xo(2),[alfa,qbar,Ps],theta);
    ref_hist(k)  = ref;
    [tn,hn,Xn] = rkfv03(@funciones,to,ho,Xo,U,theta);
    [to,time(k+1),ho,X(:,k+1),Xo] = act_edo(tn,hn,Xn);
end
de_hist(N+1)=de_hist(N); dlef_hist(N+1)=dlef_hist(N); ref_hist(N+1)=ref_hist(N);
%% Graficaci�n de resultados
%   Layout de estados X:
%   1 P3 | 2 alfaf | 3 VT | 4 alfa | 5 beta | 6 p | 7 q | 8 r
%   9-12 cuaternios | 13 xE | 14 yE | 15 zE   (marco NED, zE positivo hacia abajo)
t = time;
figure('Name','Simulaci�n de vuelo F-16 (crucero subs�nico)','NumberTitle','off');

subplot(3,3,1);
plot(t, -X(15,:),'LineWidth',1.2); grid on;
xlabel('t [s]'); ylabel('h [m]'); title('Altitud (h = -z_E)');

subplot(3,3,2);
plot(t, X(3,:),'LineWidth',1.2); grid on;
xlabel('t [s]'); ylabel('V_T [m/s]'); title('Velocidad total');

subplot(3,3,3);
plot(t, X(4,:)*180/pi,'b', t, ref_hist,'k--','LineWidth',1.2); grid on;
xlabel('t [s]'); ylabel('\alpha [deg]'); legend('\alpha','\alpha_{ref}');
title('�ngulo de ataque');

subplot(3,3,4);
plot(t, X(5,:)*180/pi,'LineWidth',1.2); grid on;
xlabel('t [s]'); ylabel('\beta [deg]'); title('�ngulo de derrape');

subplot(3,3,5);
plot(t, X(6,:)*180/pi,'r', t, X(7,:)*180/pi,'g', t, X(8,:)*180/pi,'b','LineWidth',1.0);
grid on; xlabel('t [s]'); ylabel('[deg/s]'); legend('p','q','r'); title('Velocidades angulares');

subplot(3,3,6);
plot(X(13,:), -X(15,:),'LineWidth',1.2); grid on;
xlabel('x_E [m]'); ylabel('h [m]'); title('Trayectoria (perfil vertical)');

subplot(3,3,7);
plot(t, de_hist,'LineWidth',1.2); grid on;
xlabel('t [s]'); ylabel('\delta_e [deg]'); title('Elevador');

subplot(3,3,8);
plot(t, dlef_hist,'LineWidth',1.2); grid on;
xlabel('t [s]'); ylabel('\delta_{LEF} [deg]'); title('Leading-edge flap');

subplot(3,3,9);
teta_hist = asin( max(-1,min(1, 2*(X(9,:).*X(11,:)-X(10,:).*X(12,:)) )) );
plot(t, teta_hist*180/pi,'LineWidth',1.2); grid on;
xlabel('t [s]'); ylabel('\theta [deg]'); title('�ngulo de cabeceo');

figure('Name','Trayectoria 3D','NumberTitle','off');
plot_trayectoria3d(X(13,:),X(14,:),X(15,:),'Trayectoria 3D del vuelo de crucero');
