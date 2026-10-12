function [gust,Xg] = dryden_paso(Xg,h,VT,L,sigma,w3)
% DRYDEN_PASO  Un paso del modelo de turbulencia de Dryden (simplificado).
%   Aproximacion de primer orden por eje (forma estandar en simuladores
%   docentes) del espectro de Dryden MIL-HDBK-1797:
%       x_dot = -(V/L)x + sigma*sqrt(2V/(pi*L))*eta,   eta ~ ruido blanco
%
%   Xg    : estado del filtro [xu; xv; xw]  (inicializar en ceros)
%   h     : paso de integracion [s]
%   VT    : velocidad verdadera [m/s]
%   L     : [Lu Lv Lw] longitudes de escala [m]  (p.ej. 533 m en altura)
%   sigma : [su sv sw] intensidades [m/s] (ligera ~1.5, moderada ~3)
%   w3    : vector 3x1 de ruido N(0,1) para este paso (randn del llamador,
%           asi la semilla queda bajo control del script)
%   gust  : [ug; vg; wg] en m/s
    for i=1:3
        a = VT/L(i);
        Xg(i) = Xg(i) + h*(-a*Xg(i)) + sigma(i)*sqrt(2*a*h)*w3(i);
    end
    gust = Xg;
end
