function [y]=FT(P3,mach,zE)
% Empuje [N] en funcion de la potencia P3, mach y la posicion vertical zE (NED).
% Los ajustes gaussianos Funcion_T* estan identificados con la ALTITUD en
% unidades de 1e4 m, positiva hacia arriba (centros en 0.6096 = 20000 ft y
% 1.5240 = 50000 ft del reporte NASA); aqui se hace la conversion desde zE.
altitud = max(0,-zE)*1e-4;      % [1e4 m]
%% Valores de teta para Tidle
Tidle = Funcion_Tidle(mach,altitud);
%% Valores de teta para Tmil
Tmil  = Funcion_Tmil(mach,altitud);
%% Valores de teta para Tmax
Tmax  = Funcion_Tmax(mach,altitud);
%% Calculo de Empuje
y = Calc_Empuje(P3,Tidle,Tmil,Tmax);
end