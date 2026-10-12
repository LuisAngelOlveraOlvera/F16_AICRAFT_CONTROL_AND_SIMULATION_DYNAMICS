% VALIDAR_A  Compara la matriz A ANALITICA (matriz_A) contra el Jacobiano
%   NUMERICO del modelo no lineal (modelo_cuerpo). Imprime un mapa de error
%   celda por celda y senala cualquier derivada analitica que no cuadre.
%
%   Uso:  >> validar_A
clc;   % (sin 'clear': permite invocarlo desde run_tests sin borrar su workspace)

%% Parametros del F-16 (identicos a constantes / prueba_calc_ABCD)
g=9.80665; m=9295.44; S=27.87; b=9.144; cbar=3.45;
Xcgr=0.35; Xcg=0.30;    % adimensionales (fracciones de cbar)
Ix=12874.8; Iy=75673.6; Iz=85552.1; Ixz=1331.4;
gama=Ix*Iz-Ixz^2;
c1=((Iy-Iz)*Iz-Ixz^2)/gama; c2=((Ix-Iy+Iz)*Ixz)/gama; c3=Iz/gama;
c4=Ixz/gama; c5=(Iz-Ix)/Iy; c6=Ixz/Iy; c7=1/Iy;
c8=(Ix*(Ix-Iy)+Ixz^2)/gama; c9=Ix/gama; Heng=216.9;
theta=[m,g,S,cbar,b,Xcgr,Xcg,c1,c2,c3,c4,c5,c6,c7,c8,c9,Heng]';

%% Punto de operacion (NO degenerado: alfa y beta != 0 para exponer errores)
t=0;
u=150; v=8; w=20;            % m/s  -> VT~152, alfa~7.6deg, beta~3deg
p=0.02; q=0.01; r=-0.015;    % rad/s
fi=0.10; teta=0.05; psi=0.20;
q0=cos(fi/2)*cos(teta/2)*cos(psi/2)+sin(fi/2)*sin(teta/2)*sin(psi/2);
q1=sin(fi/2)*cos(teta/2)*cos(psi/2)-cos(fi/2)*sin(teta/2)*sin(psi/2);
q2=cos(fi/2)*sin(teta/2)*cos(psi/2)+sin(fi/2)*cos(teta/2)*sin(psi/2);
q3=cos(fi/2)*cos(teta/2)*sin(psi/2)-sin(fi/2)*sin(teta/2)*cos(psi/2);
xE=0; yE=0; zE=-3000;        % altitud 3000 m
alfaf=0;                     % alfa filtrada congelada
de=0; da=0; dr=0; dth=0.7;

U   = [de,da,dr,dth]';
X13 = [u,v,w,p,q,r,q0,q1,q2,q3,xE,yE,zE]';        % para modelo_cuerpo / FD
P3  = 0;
X15 = [u,v,w,p,q,r,q0,q1,q2,q3,xE,yE,zE,P3,alfaf]';% para matriz_A (asignaX)

%% A analitica (tu trabajo) y A numerica (verdad de referencia)
A_ana = matriz_A(t,X15,U,theta);
A_num = jacobiano_fd(@(x) modelo_cuerpo(t,x,U,theta,alfaf), X13);

%% Comparacion
Err = abs(A_ana - A_num);
escala = max(1, max(abs(A_num(:))));
tol = 1e-4 * escala;
nombres = {'u','v','w','p','q','r','q0','q1','q2','q3','xE','yE','zE'};

fprintf('\n===========================================================\n');
fprintf(' VALIDACION DE LA MATRIZ A   (max|A_num| = %.3e)\n', max(abs(A_num(:))));
fprintf(' tol = %.3e     max|error| = %.3e\n', tol, max(Err(:)));
fprintf('===========================================================\n');

malos = 0;
for i=1:13
  for j=1:13
    if Err(i,j) > tol
      malos = malos+1;
      fprintf(' A(%2d,%2d)  d(%-3s)/d(%-3s):  ana=% .5e  num=% .5e  err=% .2e\n',...
              i,j,nombres{i},nombres{j},A_ana(i,j),A_num(i,j),Err(i,j));
    end
  end
end

fprintf('-----------------------------------------------------------\n');
if malos==0
   fprintf(' OK: la matriz A analitica COINCIDE con el Jacobiano numerico.\n');
else
   fprintf(' %d celda(s) con error > tol. Revisa esas derivadas analiticas\n', malos);
   fprintf(' (columna j = derivada respecto al estado j; usa la tabla de nombres).\n');
end
fprintf('===========================================================\n');
