function[y]=Cnt(alfa,beta,de,dlef,Xcgr,Xcg,cbar,b,da,dr,r,VT,p)
% Coeficiente total de momento de guinada (modelo hi-fi NASA/Nguyen).
% Entradas: alfa,beta en rad; da,dr,dlef en grados; p,r en rad/s.
% Xcgr,Xcg adimensionales (fracciones de cbar).
if VT==0
    y=0;
else
    % Cyt se evalua con los argumentos originales (hace su propia conversion)
    Cy_tot = Cyt(alfa,beta,dlef,da,dr,r,b,VT,p,de);
    r2d  = 180/pi;
    alfa = r2d*alfa;            % los ajustes aerodinamicos estan en grados
    beta = r2d*beta;
    % Linea base en beta=0 restada: por simetria Cn(alfa,0,de)=0, pero el
    % ajuste de minimos cuadrados deja un sesgo residual.
    A = (Cn(alfa,beta,de)-Cn(alfa,0,de)) ...
      + (dCnlef(alfa,beta)-dCnlef(alfa,0))*(1-dlef/25);
    B = Cy_tot*(Xcgr-Xcg)*cbar/b;
    C = (dCnda(alfa,beta)+dCndalef(alfa,beta)*(1-dlef/25))*(da/21.5);
    D = (dCndr(alfa,beta)*dr/30);
    E = (r*b/(2*VT))*(Cnr(alfa)+dCnrlef(alfa)*(1-dlef/25));
    F = (p*b/(2*VT))*(Cnp(alfa)+dCnplef(alfa)*(1-dlef/25))+dCnB(alfa)*beta;
    y = A-B+C+D+E+F;
end
