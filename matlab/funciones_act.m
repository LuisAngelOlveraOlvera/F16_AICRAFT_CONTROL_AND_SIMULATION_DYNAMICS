function[dX]=funciones_act(t,X,U,theta)
% FUNCIONES_ACT  Modelo 6-DOF + DINAMICA DE ACTUADORES (Stevens & Lewis).
%   Igual que funciones.m pero las superficies no responden instantaneamente:
%   cada una es un primer orden 20.2/(s+20.2) con limite de razon y posicion.
%       elevador: +-25 deg, +-60 deg/s
%       alerones: +-21.5 deg, +-80 deg/s
%       timon   : +-30 deg, +-120 deg/s
%   El acelerador conserva su dinamica propia (estado P3 del motor).
%
%   X = [ X15 ; de_a ; da_a ; dr_a ]   (18 estados)
%       X15 = mismos 15 estados de funciones.m
%       *_a = posicion real de cada superficie [deg]
%   U = [de_cmd, da_cmd, dr_cmd, dth]'   (comandos del controlador, deg)
    dX = 0*X;
    de_a = X(16); da_a = X(17); dr_a = X(18);
%% Dinamica de actuadores (primer orden + limite de razon)
    dX(16) = actuador(U(1), de_a, 20.2,  60, 25);
    dX(17) = actuador(U(2), da_a, 20.2,  80, 21.5);
    dX(18) = actuador(U(3), dr_a, 20.2, 120, 30);
%% Avion: ve las POSICIONES reales de las superficies, no los comandos
    Uavion = [de_a, da_a, dr_a, U(4)]';
    dX(1:15) = funciones(t,X(1:15),Uavion,theta);
end

function dxa = actuador(cmd,pos,wn,rate_lim,pos_lim)
% Primer orden con limite de razon; el comando se satura al limite fisico.
    cmd = min(max(cmd,-pos_lim),pos_lim);
    dxa = wn*(cmd-pos);
    dxa = min(max(dxa,-rate_lim),rate_lim);
end
