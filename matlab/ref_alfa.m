function [ref] = ref_alfa (VT,Ze)
% Referencia de angulo de ataque [grados].
%   En crucero subsonico el F-16 vuela con alfa de trim pequeno y positivo
%   (~2-4 deg). A baja velocidad (aproximacion/despegue) se pide mas alfa
%   para sostener el peso.
VTO = 83;                   % umbral de baja velocidad [m/s]
Zc  = -100;                 % umbral de altitud (NED: Ze<0 es arriba) [m]
if VT>VTO && Ze<Zc
    ref = 3;                % crucero: alfa de trim moderado
else
    ref = 8;                % baja velocidad / cerca del suelo: mas sustentacion
end
end
