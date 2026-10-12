close all
clc
t=0;
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
%%      Condiciones iniciales
%      �ngulos de orientaci�n
fi   = 0;   
teta = 0;
psi  = 0;
%    �ngulos de orientaci�n para actuador
de   = 0;                               % Deflexi�n del elevador en radianes.
da   = 0;                               % Deflexi�n de alerones en radianes.
dr   = 0;                               % Deflexi�n del estabilizador horizontal en radianes.
dth  = 0.7;                               % Mariposa del motor.
%%  Estados
u  = 1;
v  = 0;  
w  = 0;  
%   Variables auxiliares


p     = 0;  % Velocidad angular del alabeo X(4).
q     = 0;  % Velocidad angular del cabeceo X(5).
r     = 0;  % Velocidad angular del gui�ado X(6).
%   Definici�n de Cuaternios
q0 = cos(0.5*fi)*cos(0.5*teta)*cos(0.5*psi)+sin(0.5*fi)*sin(0.5*teta)*sin(0.5*psi);  
q1 = sin(0.5*fi)*cos(0.5*teta)*cos(0.5*psi)-cos(0.5*fi)*sin(0.5*teta)*sin(0.5*psi);  
q2 = cos(0.5*fi)*sin(0.5*teta)*cos(0.5*psi)+sin(0.5*fi)*cos(0.5*teta)*sin(0.5*psi);  
q3 = cos(0.5*fi)*cos(0.5*teta)*sin(0.5*psi)-sin(0.5*fi)*sin(0.5*teta)*cos(0.5*psi);
%  Vector de orientaci�n en marco de referencia fijo para la tierra.
xE = 0;  
yE = 0; 
zE = 0;
%%
alfaf = 0;
P3=0;

X=[u,v,w,p,q,r,q0,q1,q2,q3,xE,yE,zE,P3,alfaf]';
U=[de,da,dr,dth]';
theta = [m,g,S,cbar,b,Xcgr,Xcg,c1,c2,c3,c4,c5,c6,c7,c8,c9,Heng]';

A = matriz_A(t,X,U,theta);
for i = 1:13
    fprintf('\n')
    for j=1:13
        fprintf('\t%6.2f ',A(i,j))
    end
end
fprintf('\n')