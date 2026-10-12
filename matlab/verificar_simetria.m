% VERIFICAR_SIMETRIA  Prueba de simetria lateral en las TRES formulaciones.
%   En una condicion perfectamente simetrica (beta=p=r=0, da=dr=0, alas a
%   nivel) un avion simetrico NO debe generar dinamica lateral:
%       beta_dot = p_dot = r_dot = 0   (y fi_dot = psi_dot = 0)
%   Esta prueba protege contra el sesgo residual de los ajustes de minimos
%   cuadrados en Cl/Cn/Cy (corregido en Clt/Cnt/Cyt restando la linea base
%   en beta=0). Ejecutar despues de cualquier cambio en la aerodinamica.
clc; clear;

%% Parametros (identicos a pruebarkf)
g=9.80665; m=9295.44; S=27.87; b=9.144; cbar=3.45;
Xcgr=0.35; Xcg=0.30;
Ix=12874.8; Iy=75673.6; Iz=85552.1; Ixz=1331.4;
gama=Ix*Iz-Ixz^2;
c1=((Iy-Iz)*Iz-Ixz^2)/gama; c2=((Ix-Iy+Iz)*Ixz)/gama; c3=Iz/gama;
c4=Ixz/gama; c5=(Iz-Ix)/Iy; c6=Ixz/Iy; c7=1/Iy;
c8=(Ix*(Ix-Iy)+Ixz^2)/gama; c9=Ix/gama; Heng=216.9;
theta=[m,g,S,cbar,b,Xcgr,Xcg,c1,c2,c3,c4,c5,c6,c7,c8,c9,Heng,0,0]';

VT0=170; h0=3000;
[Xtrim,Utrim,info] = trim_crucero(VT0,h0,theta);
teta_tr = 2*asin(Xtrim(11));
% Nota: el termino giroscopico del motor (q*Heng) SI acopla cabeceo con
% alabeo/guinada, pero en trim q=0, asi que no contribuye aqui.
tol = 1e-10;
ok  = true;

%% 1) funciones.m  (cuaterniones + ejes viento, 15 estados)
X = Xtrim;
X(5)=0; X(6)=0; X(8)=0;             % beta, p, r
U = Utrim; U(2)=0; U(3)=0;          % da, dr
dX = funciones(0,X,U,theta);
fprintf('--- funciones.m (cuaterniones + ejes viento) ---\n');
fprintf('beta_dot = %.12e\n', dX(5));
fprintf('p_dot    = %.12e\n', dX(6));
fprintf('r_dot    = %.12e\n', dX(8));
ok = ok && all(abs(dX([5 6 8]))<tol);

%% 2) funciones_euler.m  (Euler + ejes viento, 14 estados)
Xe = [Xtrim(1); Xtrim(2); Xtrim(3); Xtrim(4); 0; 0;0;0; ...
      0; teta_tr; 0; 0; 0; Xtrim(15)];
dXe = funciones_euler(0,Xe,U,theta);
fprintf('--- funciones_euler.m (Euler + ejes viento) ---\n');
fprintf('beta_dot = %.12e\n', dXe(5));
fprintf('p_dot    = %.12e\n', dXe(6));
fprintf('r_dot    = %.12e\n', dXe(8));
fprintf('fi_dot   = %.12e\n', dXe(9));
fprintf('psi_dot  = %.12e\n', dXe(11));
ok = ok && all(abs(dXe([5 6 8 9 11]))<tol);

%% 3) modelo_cuerpo.m  (cuaterniones + ejes cuerpo, 13 estados)
%    (sin motor: solo aerodinamica; v=0 es la condicion simetrica)
u_b = VT0*cos(Xtrim(4)); w_b = VT0*sin(Xtrim(4));
q0=cos(0.5*teta_tr); q2=sin(0.5*teta_tr);
Xb = [u_b; 0; w_b; 0;0;0; q0;0;q2;0; 0;0;Xtrim(15)];
alfaf = Xtrim(2);
dXb = modelo_cuerpo(0,Xb,U,theta,alfaf);
fprintf('--- modelo_cuerpo.m (cuaterniones + ejes cuerpo) ---\n');
fprintf('v_dot    = %.12e\n', dXb(2));
fprintf('p_dot    = %.12e\n', dXb(4));
fprintf('r_dot    = %.12e\n', dXb(6));
ok = ok && all(abs(dXb([2 4 6]))<tol);

%% Veredicto
fprintf('-------------------------------------------------\n');
if ok
    fprintf('OK: simetria lateral exacta en las 3 formulaciones (tol %.0e).\n',tol);
else
    fprintf('FALLO: hay dinamica lateral espuria. Revisa Clt/Cnt/Cyt\n');
    fprintf('(resta de la linea base en beta=0) y los fits laterales.\n');
end
