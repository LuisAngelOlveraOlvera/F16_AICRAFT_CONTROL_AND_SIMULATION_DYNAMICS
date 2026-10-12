function [U,ie] = ctrl_PID(alfa_r,alfa,q,ie,h,dth)
% Control PID de alfa con amortiguamiento de cabeceo.
%   alfa_r : referencia [deg]
%   alfa   : estado [rad]
%   q      : velocidad de cabeceo [rad/s]  (actua como termino D "limpio")
%   ie     : integral acumulada del error [deg*s] (el llamador la conserva)
%   h      : paso de integracion [s]
%   Signos: de>0 genera momento de cabeceo negativo (nariz abajo).
%   Anti-windup: la integral se congela cuando el elevador esta saturado.
    Kp = 5.0;               % deg de elevador por deg de error
    Ki = 1.5;               % deg de elevador por deg*s de error acumulado
    Kq = 0.8;               % deg de elevador por (deg/s) de q
    alfa_deg = alfa*180/pi;
    q_deg    = q*180/pi;
    e  = alfa_r - alfa_deg;
    de = -Kp*e - Ki*ie + Kq*q_deg;
    if abs(de) < 25
        ie = ie + e*h;      % solo integra si no hay saturacion (anti-windup)
        de = -Kp*e - Ki*ie + Kq*q_deg;
    end
    de = min(max(de,-25),25);
    %    1   2  3  4
    U = [de  0  0 dth]';
end
