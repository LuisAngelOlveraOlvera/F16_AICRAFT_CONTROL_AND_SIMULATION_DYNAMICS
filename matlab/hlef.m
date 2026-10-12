function[y]=hlef(t,X,U,theta)
%%  Salida del leading-edge flap [grados], saturada a [0, 25].
%   dlef = 1.38*(2s+7.25)/(s+7.25)*alfa_deg - 9.05*qbar/Ps + 1.45
% X = alfaf (estado del filtro, en grados)
% U = [alfa (rad), qbar, Ps]
alfa_deg = U(1)*180/pi;
qbar = U(2);
Ps   = U(3);
y = 2.76*alfa_deg - X - 9.05*qbar/Ps + 1.45;
y = min(max(y,0),25);       % limite fisico del actuador del LEF
end
