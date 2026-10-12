function [dx] = modelo_cuerpo(t,X,U,theta,alfaf)
% MODELO_CUERPO  Modelo NO lineal de 6-DOF en ejes cuerpo (13 estados).
%   Es la VERDAD DE REFERENCIA contra la que se valida la linealizacion
%   analitica (matriz_A). Reutiliza hu() para fuerzas y momentos, de modo
%   que comparte exactamente el mismo modelo aerodinamico que la sim.
%
%   X = [u,v,w, p,q,r, q0,q1,q2,q3, xE,yE,zE]'   (mismo orden que asignaX)
%   U = [de,da,dr,dth]'   (dth no afecta a estos 13 estados aqui)
%   theta = parametros del F-16 (igual que en matriz_A / parametros.m)
%   alfaf = alfa filtrada CONGELADA en el punto de operacion (no es estado aqui,
%           coherente con que matriz_A entrega A de 13x13 sin columna de alfaf).

    u=X(1); v=X(2); w=X(3); p=X(4); q=X(5); r=X(6);
    q0=X(7); q1=X(8); q2=X(9); q3=X(10); zE=X(13);

    [m,g,S,cbar,b,Xcgr,Xcg,c1,c2,c3,c4,c5,c6,c7,c8,c9,Heng] = parametros(theta);
    de=U(1); da=U(2); dr=U(3);

    %% Variables aerodinamicas
    VT   = sqrt(u^2+v^2+w^2);
    alfa = atan2(w,u);
    beta = asin(v/VT);
    [~,Ps,Rho,~] = atmosfera(-zE);   % NED: altitud h = -zE
    qbar = 0.5*Rho*VT^2;
    % LEF en grados, igual que matriz_A (alfaf congelada, en grados)
    dlef = 2.76*(alfa*180/pi) - alfaf - 9.05*qbar/Ps + 1.45;
    dlef = min(max(dlef,0),25);

    %% Fuerzas y momentos en ejes cuerpo (reutiliza hu, ya verificado)
    fm6 = hu(t,[VT,alfa,beta,p,q,r],[de,da,dr,qbar,dlef],theta);
    Xa=fm6(1); Ya=fm6(2); Za=fm6(3); Na=fm6(4); La=fm6(5); Ma=fm6(6);

    %% Gravedad proyectada a ejes cuerpo (cuaternios)
    gx = 2*(q1*q3 - q0*q2)*g;
    gy = 2*(q2*q3 + q0*q1)*g;
    gz = (q0^2 - q1^2 - q2^2 + q3^2)*g;

    dx = zeros(13,1);
    %% Ecuaciones de fuerza (ejes cuerpo)
    dx(1) = Xa/m - (q*w - r*v) + gx;
    dx(2) = Ya/m - (r*u - p*w) + gy;
    dx(3) = Za/m - (p*v - q*u) + gz;
    %% Ecuaciones de momento (acoplamiento de inercia c1..c9)
    dx(4) = (c1*r + c2*p)*q + c3*La + c4*(Na + q*Heng);
    dx(5) = c5*p*r - c6*(p^2 - r^2) + c7*(Ma - r*Heng);
    dx(6) = (c8*p - c2*r)*q + c4*La + c9*(Na + q*Heng);
    %% Cinematica de cuaternios
    dx(7)  = -0.5*(p*q1 + q*q2 + r*q3);
    dx(8)  =  0.5*(p*q0 + r*q2 - q*q3);
    dx(9)  =  0.5*(q*q0 - r*q1 + p*q3);
    dx(10) =  0.5*(r*q0 + q*q1 - p*q2);
    %% Posicion (NED) = DCM(q) * [u v w]
    dx(11) = (q0^2+q1^2-q2^2-q3^2)*u + 2*(q1*q2-q0*q3)*v + 2*(q1*q3+q0*q2)*w;
    dx(12) = 2*(q1*q2+q0*q3)*u + (q0^2-q1^2+q2^2-q3^2)*v + 2*(q2*q3-q0*q1)*w;
    dx(13) = 2*(q1*q3-q0*q2)*u + 2*(q2*q3+q0*q1)*v + (q0^2-q1^2-q2^2+q3^2)*w;
end
