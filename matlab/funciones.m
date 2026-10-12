function[dX]=funciones(t,X,U,theta)
%% Ubicaci�n de variables
%      1   2     3    4    5  6  7  8 9   10  11  12  13  14   15
% X = [P3,alfaf, VT,alfa,beta,p, q, r,q0, q1, q2, q3, xE, yE  zE]';
%       1   2  3  4  
% U = [de da dr dth]';
    dX = 0*X;
    VT = X(3); alfa = X(4); zE = X(15);P3 = X(1); de = U(1); da = U(2); dr = U(3); dth = U(4);
    [T,Ps,Rho,a]=atmosfera(-zE);   % NED: altitud h = -zE
    qbar = 0.5*Rho*VT^2;
    mach = VT/a;
%% MOTOR
    U1 = [dth,mach,zE]';
    dX(1) = fm(t,P3,U1,theta);
    y1 = hm(t,P3,U1);
    FTint = y1;
    %% dlef
    U2 = [alfa,qbar,Ps];
    dX(2) = flef(t,X(2),U2,theta);
    y2 = hlef(t,X(2),U2,theta);
    dlef = y2;
%%  C�lculo de coeficientes de fuerzas y momentos
    U3 = [de,da,dr,qbar,dlef];
    y3=hu(t,X(3:8),U3,theta); 
    Xint = y3(1); Yint = y3(2); Zint = y3(3); Nint = y3(4); Lint = y3(5); Mint = y3(6);
%% ECUACIONES DE MOVIMIENTO
    Xa = X(3:15); 
    U3 = [FTint,Xint,Yint,Zint,Nint,Lint,Mint,dlef,qbar]';
    dX(3:15) = fa(t,Xa,U3,theta);
end