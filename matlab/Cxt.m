function [y]=Cxt(alfa,beta,de,dlef,q,cbar,VT)
% Coeficiente total de fuerza axial (modelo hi-fi NASA/Nguyen).
% Entradas: alfa,beta en rad; de,dlef en grados; q en rad/s.
if VT==0
    y=0;
else
    r2d  = 180/pi;
    alfa = r2d*alfa;            % los ajustes aerodinamicos estan en grados
    beta = r2d*beta;
    A = Cx(alfa,beta,de)+dCxlef(alfa,beta)*(1-dlef/25);
    B = (q*cbar/(2*VT))*(Cxq(alfa)+dCxqlef(alfa)*(1-dlef/25));
    y = A+B;
end
