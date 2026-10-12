function [Xtrim,Utrim,info] = trim_vuelo(VT,h,gamma_deg,psidot_dps,theta)
% TRIM_VUELO  Trim general (Stevens & Lewis cap. 3): recto/nivelado,
%   ascenso/descenso y viraje coordinado sostenido.
%
%   [Xtrim,Utrim,info] = trim_vuelo(VT, h, gamma_deg, psidot_dps, theta)
%       VT         : velocidad verdadera [m/s]
%       h          : altitud [m]
%       gamma_deg  : angulo de trayectoria [deg]  (0 = nivelado)
%       psidot_dps : razon de viraje [deg/s]      (0 = recto)
%
%   Coordinacion: beta = 0. Incognitas z = [alfa, de, da, dr, dth, fi];
%   se minimiza ||[dVT,dalfa,dbeta,dp,dq,dr]|| del modelo no lineal completo
%   (funciones.m). theta_pitch sale de la restriccion de razon de ascenso y
%   (p,q,r) de la cinematica del viraje estacionario.
%
%   trim_vuelo(VT,h,0,0,theta) reproduce a trim_crucero.

    zE   = -abs(h);
    gam  = gamma_deg*pi/180;
    psid = psidot_dps*pi/180;
    g    = theta(2);

    % Estimacion inicial: banco de viraje coordinado y alfa/controles suaves
    fi0 = atan2(psid*VT, g);
    z0  = [2*pi/180, -2, 0, 0, 0.3, fi0];
    opciones = optimset('TolX',1e-11,'TolFun',1e-14, ...
                        'MaxFunEvals',60000,'MaxIter',30000);
    [z,J] = fminsearch(@(z) residuo(z,VT,zE,gam,psid,theta), z0, opciones);
    [z,J] = fminsearch(@(z) residuo(z,VT,zE,gam,psid,theta), z, opciones);
    % fminsearch puede caer en la meseta del throttle recortado (z(5)<0).
    % Proyectar no cambia el costo actual; Newton amortiguado recupera una
    % direccion de busqueda fisica y solo acepta pasos que reducen el residuo.
    [z,J] = refinar_trim(z,VT,zE,gam,psid,theta);

    [~,Xtrim,Utrim] = residuo(z,VT,zE,gam,psid,theta);
    info.residuo   = sqrt(J);
    info.converge  = info.residuo < 1e-6;
    info.alfa_deg  = z(1)*180/pi;
    info.de_deg    = z(2);
    info.da_deg    = z(3);
    info.dr_deg    = z(4);
    info.dth       = min(max(z(5),0),1);
    info.fi_deg    = z(6)*180/pi;
    info.teta_deg  = Xtrim_teta(z,gam)*180/pi;
end

function teta = Xtrim_teta(z,gam)
% Restriccion de razon de ascenso (S&L 3.6-2) con beta=0:
%   a = cos(alfa),  b = sin(fi)*0 + cos(fi)*sin(alfa) -> forma general:
    alfa = z(1); fi = z(6);
    a = cos(alfa);            % cos(alfa)*cos(beta), beta=0
    bb = cos(fi)*sin(alfa);   % sin(fi)*sin(beta)+cos(fi)*sin(alfa)*cos(beta)
    sg = sin(gam);
    teta = atan( (a*bb + sg*sqrt(a^2 - sg^2 + bb^2)) / (a^2 - sg^2) );
end

function [J,X,U,R] = residuo(z,VT,zE,gam,psid,theta)
    alfa = z(1); de = z(2); da = z(3); dr = z(4);
    dth  = min(max(z(5),0),1); fi = z(6);
    teta = Xtrim_teta(z,gam);
    % Velocidades angulares del viraje estacionario (S&L 3.6-1)
    p = -psid*sin(teta);
    q =  psid*sin(fi)*cos(teta);
    r =  psid*cos(fi)*cos(teta);
    % Cuaterniones desde (fi, teta, psi=0)
    q0=cos(fi/2)*cos(teta/2); q1=sin(fi/2)*cos(teta/2);
    q2=cos(fi/2)*sin(teta/2); q3=-sin(fi/2)*sin(teta/2);   % ZYX estandar, psi=0
    % Motor y filtro LEF en estacionario
    P3    = Calc_P1(dth);
    alfaf = 1.38*(alfa*180/pi);
    X = [P3,alfaf,VT,alfa,0,p,q,r,q0,q1,q2,q3,0,0,zE]';
    U = [de,da,dr,dth]';
    dX = funciones(0,X,U,theta);
    % Equilibrio completo: traslacional + rotacional
    R = [dX(3);100*dX(4:8)];
    J = sum(R.^2);
end

function [z,J] = refinar_trim(z,VT,zE,gam,psid,theta)
z=z(:); z(5)=min(max(z(5),0),1);
fun=@(v) residuo_vector(v,VT,zE,gam,psid,theta);
R=fun(z); J=sum(R.^2);
for k=1:15
    if sqrt(J)<1e-9,break;end
    D=jacobiano_fd(fun,z);
    if any(~isfinite(D(:))) || rcond(D)<1e-12,break;end
    step=-(D\R); accepted=false;
    for j=0:12
        trial=z+step*2^(-j); trial(5)=min(max(trial(5),0),1);
        Rt=fun(trial);
        if isreal(Rt) && all(isfinite(Rt)) && sum(Rt.^2)<J
            z=trial;R=Rt;J=sum(R.^2);accepted=true;break;
        end
    end
    if ~accepted,break;end
end
end

function R = residuo_vector(z,VT,zE,gam,psid,theta)
[~,~,~,R]=residuo(z,VT,zE,gam,psid,theta);
end
