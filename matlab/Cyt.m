function[y]=Cyt(alfa,beta,dlef,da,dr,r,b,VT,p,de)
% Coeficiente total de fuerza lateral (modelo hi-fi NASA/Nguyen).
% Entradas: alfa,beta en rad; da,dr,dlef en grados; p,r en rad/s.
% Normalizaciones del modelo original: da/21.5, dr/30, (1-dlef/25).
if VT==0
    y=0;
else
    r2d  = 180/pi;
    alfa = r2d*alfa;            % los ajustes aerodinamicos estan en grados
    beta = r2d*beta;
    % Se resta la linea base en beta=0: por simetria del avion Cy(alfa,0)=0,
    % pero el ajuste de minimos cuadrados deja un sesgo residual.
    A = (Cy(alfa,beta)-Cy(alfa,0)) ...
      + (dCylef(alfa,beta)-dCylef(alfa,0))*(1-dlef/25);
    B = dCyda(alfa,beta)+dCydalef(alfa,beta)*(1-dlef/25);
    C = (da/21.5);
    D = dCydr(alfa,beta)*(dr/30);
    E = r*b/(2*VT);
    F = Cyr(alfa)+dCyrlef(alfa)*(1-dlef/25);
    G = p*b/(2*VT);
    H = Cyp(alfa)+dCyplef(alfa)*(1-dlef/25);
    y = A+B*C+D+E*F+G*H;
end
