function[y]=Clt(alfa,beta,dlef,da,dr,r,b,VT,de,p)
% Coeficiente total de momento de alabeo (modelo hi-fi NASA/Nguyen).
% Entradas: alfa,beta en rad; da,dr,dlef en grados; p,r en rad/s.
if VT==0
    y=0;
else
    r2d  = 180/pi;
    alfa = r2d*alfa;            % los ajustes aerodinamicos estan en grados
    beta = r2d*beta;
    % Linea base en beta=0 restada: por simetria Cl(alfa,0,de)=0, pero el
    % ajuste de minimos cuadrados deja un sesgo residual.
    A=(Cl(alfa,beta,de)-Cl(alfa,0,de)) ...
     +(dCllef(alfa,beta)-dCllef(alfa,0))*(1-dlef/25);
    B=(dClda(alfa,beta)+dCldalef(alfa,beta)*(1-dlef/25))*(da/21.5);
    C=dCldr(alfa,beta)*(dr/30)+(r*b/(2*VT))*(Clr(alfa)+dClrlef(alfa)*(1-dlef/25));
    D=(p*b/(2*VT))*(Clp(alfa)+(dClplef(alfa)*(1-dlef/25)))+dClB(alfa)*beta;
    y=A+B+C+D;
end
