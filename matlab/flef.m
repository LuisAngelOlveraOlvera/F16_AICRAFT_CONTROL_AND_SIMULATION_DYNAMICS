function[dX]=flef(t,X,U,theta)
%%  Dinamica del filtro de alfa para el leading-edge flap.
%   dlef = 1.38*(2s+7.25)/(s+7.25)*alfa_deg - 9.05*qbar/Ps + 1.45  [grados]
%   Realizacion: y = 2.76*alfa_deg - X,  con  dX = -7.25*X + 10.005*alfa_deg
% X = alfaf (estado del filtro, en grados)
% U = [alfa (rad), qbar, Ps]
    alfa_deg = U(1)*180/pi;
    dX = -7.25*X + 10.005*alfa_deg;
end
