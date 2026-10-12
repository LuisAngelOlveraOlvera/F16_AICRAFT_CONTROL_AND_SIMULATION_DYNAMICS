function[y]=Cmt(alfa,beta,de,Xcgr,Xcg,dlef,q,cbar,VT)
% Coeficiente total de momento de cabeceo (modelo hi-fi NASA/Nguyen).
% Entradas: alfa,beta en rad; de,dlef en grados; q en rad/s.
% Xcgr,Xcg adimensionales (fracciones de cbar, p.ej. 0.35 y 0.30).
% Nota: el ajuste polinomial Cm(alfa,beta,de) debe absorber la efectividad
% del elevador eta_de del modelo original (verificar contra los datos).
if VT==0
    y=0;
else
    % Czt se evalua con los argumentos originales (hace su propia conversion)
    Cz_tot = Czt(alfa,beta,de,dlef,q,cbar,VT);
    r2d  = 180/pi;
    alfa = r2d*alfa;            % los ajustes aerodinamicos estan en grados
    beta = r2d*beta;
    A = Cm(alfa,beta,de)+Cz_tot*(Xcgr-Xcg);
    B = dCmlef(alfa,beta)*(1-dlef/25);
    C = q*cbar/(2*VT)*(Cmq(alfa)+dCmqlef(alfa)*(1-dlef/25));
    D = dCm(alfa)+dCmds(alfa,de);
    y = A+B+C+D;
end
