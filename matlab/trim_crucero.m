function [Xtrim,Utrim,info] = trim_crucero(VT,h,theta)
% TRIM_CRUCERO  Punto de equilibrio en vuelo recto y nivelado (alas a nivel).
%   Busca [alfa, de, dth] tales que dVT=dalfa=dq=0 en el modelo NO lineal
%   completo (funciones.m), con beta=p=q=r=0, theta_pitch=alfa (gamma=0),
%   motor y filtro LEF en estado estacionario.
%
%   [Xtrim,Utrim,info] = trim_crucero(170, 3000, theta)
%     Xtrim : estado 15x1 en el orden de pruebarkf/funciones
%     Utrim : [de(deg); da; dr; dth]
%     info  : residuo final y bandera de convergencia
%
%   Solo usa fminsearch (MATLAB base, sin toolboxes).

    zE = -abs(h);                       % NED: arriba es negativo
    t  = 0;

    % z = [alfa(rad), de(deg), dth]
    z0 = [2*pi/180, -2, 0.35];
    opciones = optimset('TolX',1e-10,'TolFun',1e-12, ...
                        'MaxFunEvals',20000,'MaxIter',10000);
    [z,J] = fminsearch(@(z) residuo(z,VT,zE,t,theta), z0, opciones);

    [~,Xtrim,Utrim] = residuo(z,VT,zE,t,theta);
    info.residuo  = sqrt(J);
    info.converge = info.residuo < 1e-6;
    info.alfa_deg = z(1)*180/pi;
    info.de_deg   = z(2);
    info.dth      = z(3);
end

function [J,X,U] = residuo(z,VT,zE,t,theta)
    alfa = z(1); de = z(2); dth = min(max(z(3),0),1);
    % Vuelo nivelado alas a nivel: theta_pitch = alfa, fi = psi = 0
    q0 = cos(0.5*alfa); q2 = sin(0.5*alfa); q1 = 0; q3 = 0;
    % Motor en estacionario: P3 = P1(dth);  filtro LEF en estacionario
    P3    = Calc_P1(dth);
    alfaf = 1.38*(alfa*180/pi);
    X = [P3,alfaf,VT,alfa,0,0,0,0,q0,q1,q2,q3,0,0,zE]';
    U = [de,0,0,dth]';
    dX = funciones(t,X,U,theta);
    % Equilibrio longitudinal: dVT, dalfa, dq (beta,p,r ya son 0 por simetria)
    J = dX(3)^2 + (100*dX(4))^2 + (100*dX(7))^2;
end
