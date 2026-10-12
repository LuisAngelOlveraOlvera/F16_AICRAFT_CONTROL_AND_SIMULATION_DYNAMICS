function [y] = matriz_A(t,X,U,theta)
% MATRIZ_A  Matriz A (13x13) del modelo linealizado en ejes cuerpo.
%
%   Ensamblador HIBRIDO:
%     * La ESTRUCTURA se calcula ANALITICAMENTE en forma cerrada
%       (gravedad por cuaternios, cinematica de cuaternios, acoplamiento de
%       cuerpo rigido c1..c9, terminos cruzados de Coriolis y filas de
%       posicion). Es la parte conceptual del modelo 6-DOF.
%     * El BLOQUE AERODINAMICO (derivadas de fuerzas/momentos respecto a los
%       estados) se obtiene por diferencias finitas centradas del modelo
%       aerodinamico hu(), que es la practica estandar en simuladores de
%       vuelo y evita los errores de las derivadas aero diferenciadas a mano.
%
%   Estado:  X = [u,v,w,p,q,r,q0,q1,q2,q3,xE,yE,zE,P3,alfaf]   (asignaX)
%   A(i,j) = d f_i / d x_j  (f = modelo_cuerpo).  Columnas: u v w p q r q0 q1 q2 q3 xE yE zE
%   Validar contra el Jacobiano numerico completo con:  >> validar_A

[u,v,w,p,q,r,q0,q1,q2,q3,xE,yE,zE,P3,alfaf] = asignaX(X);
[de,da,dr,dth] = asignaU(U);
[m,g,S,cbar,b,Xcgr,Xcg,c1,c2,c3,c4,c5,c6,c7,c8,c9,Heng] = parametros(theta);

%% ---- Bloque aerodinamico por diferencias finitas de hu() --------------
%   F(estado) = [X;Y;Z;N;L;M] en ejes cuerpo.  (ojo: orden N,L,M de hu)
f = @(uu,vv,ww,pp,qq,rr,zz) aero_eval(uu,vv,ww,pp,qq,rr,zz,de,da,dr,alfaf,theta,t);
st = @(x) 1e-6*max(1,abs(x));
hU=st(u);  dFu=(f(u+hU,v,w,p,q,r,zE)-f(u-hU,v,w,p,q,r,zE))/(2*hU);
hV=st(v);  dFv=(f(u,v+hV,w,p,q,r,zE)-f(u,v-hV,w,p,q,r,zE))/(2*hV);
hW=st(w);  dFw=(f(u,v,w+hW,p,q,r,zE)-f(u,v,w-hW,p,q,r,zE))/(2*hW);
hP=st(p);  dFp=(f(u,v,w,p+hP,q,r,zE)-f(u,v,w,p-hP,q,r,zE))/(2*hP);
hQ=st(q);  dFq=(f(u,v,w,p,q+hQ,r,zE)-f(u,v,w,p,q-hQ,r,zE))/(2*hQ);
hR=st(r);  dFr=(f(u,v,w,p,q,r+hR,zE)-f(u,v,w,p,q,r-hR,zE))/(2*hR);
hZ=st(zE); dFz=(f(u,v,w,p,q,r,zE+hZ)-f(u,v,w,p,q,r,zE-hZ))/(2*hZ);

% Contribucion aerodinamica a las 6 ecuaciones de fuerza/momento (col dada)
%   aero = [dudot; dvdot; dwdot; dpdot; dqdot; drdot]
aero = @(dF)[ dF(1)/m;
              dF(2)/m;
              dF(3)/m;
              c3*dF(5) + c4*dF(4);     % c3*L + c4*N
              c7*dF(6);                % c7*M
              c4*dF(5) + c9*dF(4) ];   % c4*L + c9*N
Au=aero(dFu); Av=aero(dFv); Aw=aero(dFw);
Ap=aero(dFp); Aq=aero(dFq); Ar=aero(dFr); Az=aero(dFz);

%% =================== Ensamblaje de columnas (13x1) =====================
% Columna u  (cruzados: f2:-r  f3:+q)
cu = [ Au(1); -r+Au(2); q+Au(3); Au(4); Au(5); Au(6); 0;0;0;0;
       (q0^2+q1^2-q2^2-q3^2); 2*(q1*q2+q0*q3); 2*(q1*q3-q0*q2) ];

% Columna v  (cruzados: f1:+r  f3:-p)
cv = [ r+Av(1); Av(2); -p+Av(3); Av(4); Av(5); Av(6); 0;0;0;0;
       2*(q1*q2-q0*q3); (q0^2-q1^2+q2^2-q3^2); 2*(q2*q3+q0*q1) ];

% Columna w  (cruzados: f1:-q  f2:+p)
cw = [ -q+Aw(1); p+Aw(2); Aw(3); Aw(4); Aw(5); Aw(6); 0;0;0;0;
       2*(q1*q3+q0*q2); 2*(q2*q3-q0*q1); (q0^2-q1^2-q2^2+q3^2) ];

% Columna p
cp = [ Ap(1);
       w+Ap(2);
       -v+Ap(3);
       c2*q + Ap(4);
       c5*r - 2*c6*p + Ap(5);
       c8*q + Ap(6);
       -0.5*q1; 0.5*q0; 0.5*q3; -0.5*q2; 0;0;0 ];

% Columna q
cq = [ -w+Aq(1);
       Aq(2);
       u+Aq(3);
       (c1*r + c2*p) + c4*Heng + Aq(4);
       Aq(5);
       (c8*p - c2*r) + c9*Heng + Aq(6);
       -0.5*q2; -0.5*q3; 0.5*q0; 0.5*q1; 0;0;0 ];

% Columna r
cr = [ v+Ar(1);
       -u+Ar(2);
       Ar(3);
       c1*q + Ar(4);
       c5*p + 2*c6*r - c7*Heng + Ar(5);
       -c2*q + Ar(6);
       -0.5*q3; 0.5*q2; -0.5*q1; 0.5*q0; 0;0;0 ];

% Columnas de cuaternios (gravedad + cinematica de cuaternios + posicion)
cq0 = [ -2*q2*g; 2*q1*g; 2*q0*g; 0;0;0;
        0; 0.5*p; 0.5*q; 0.5*r;
        2*q0*u-2*q3*v+2*q2*w;  2*q3*u+2*q0*v-2*q1*w;  -2*q2*u+2*q1*v+2*q0*w ];
cq1 = [ 2*q3*g; 2*q0*g; -2*q1*g; 0;0;0;
        -0.5*p; 0; -0.5*r; 0.5*q;
        2*q1*u+2*q2*v+2*q3*w;  2*q2*u-2*q1*v-2*q0*w;  2*q3*u+2*q0*v-2*q1*w ];
cq2 = [ -2*q0*g; 2*q3*g; -2*q2*g; 0;0;0;
        -0.5*q; 0.5*r; 0; -0.5*p;
        -2*q2*u+2*q1*v+2*q0*w;  2*q1*u+2*q2*v+2*q3*w;  -2*q0*u+2*q3*v-2*q2*w ];
cq3 = [ 2*q1*g; 2*q2*g; 2*q3*g; 0;0;0;
        -0.5*r; -0.5*q; 0.5*p; 0;
        -2*q3*u-2*q0*v+2*q1*w;  2*q0*u-2*q3*v+2*q2*w;  2*q1*u+2*q2*v+2*q3*w ];

% Columnas xE, yE (nada depende de la posicion horizontal)
cxE = zeros(13,1);
cyE = zeros(13,1);

% Columna zE (acoplamiento atmosferico, solo aerodinamico)
czE = [ Az(1); Az(2); Az(3); Az(4); Az(5); Az(6); 0;0;0;0;0;0;0 ];

y = [cu, cv, cw, cp, cq, cr, cq0, cq1, cq2, cq3, cxE, cyE, czE];
end

% ----------------------------------------------------------------------
function F = aero_eval(u,v,w,p,q,r,zE,de,da,dr,alfaf,theta,t)
% Fuerzas/momentos aerodinamicos en ejes cuerpo: F = [X;Y;Z;N;L;M]
    VT = sqrt(u^2+v^2+w^2);
    alfa = atan2(w,u);
    if VT==0, beta = 0; else beta = asin(v/VT); end
    [~,Ps,Rho,~] = atmosfera(-zE);   % NED: altitud h = -zE
    qbar = 0.5*Rho*VT^2;
    % LEF en grados (alfaf congelada, en grados)
    dlef = 2.76*(alfa*180/pi) - alfaf - 9.05*qbar/Ps + 1.45;
    dlef = min(max(dlef,0),25);
    F = hu(t,[VT,alfa,beta,p,q,r],[de,da,dr,qbar,dlef],theta);
end
