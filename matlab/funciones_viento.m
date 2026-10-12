function[dX]=funciones_viento(t,X,U,theta)
% FUNCIONES_VIENTO  Modelo 6-DOF con VIENTO/RAFAGA como entrada exogena.
%   Igual que funciones.m, pero la aerodinamica ve el viento relativo:
%       VT_a   = VT - ug          (rafaga longitudinal)
%       alfa_a = alfa + wg/VT     (rafaga vertical)
%       beta_a = beta + vg/VT     (rafaga lateral)
%   con (ug,vg,wg) en m/s generadas p.ej. por dryden_paso.m.
%
%   X = [P3,alfaf,VT,alfa,beta,p,q,r,q0,q1,q2,q3,xE,yE,zE]'   (15 estados)
%   U = [de, da, dr, dth, ug, vg, wg]'
    dX = 0*X;
    VT = X(3); alfa = X(4); zE = X(15); P3 = X(1);
    de = U(1); da = U(2); dr = U(3); dth = U(4);
    ug = U(5); vg = U(6); wg = U(7);
    [T,Ps,Rho,a]=atmosfera(-zE);   % NED: altitud h = -zE
%% Viento relativo visto por la aerodinamica
    if VT>1
        VT_a   = VT - ug;
        alfa_a = alfa + wg/VT;
        beta_a = X(5) + vg/VT;
    else
        VT_a = VT; alfa_a = alfa; beta_a = X(5);
    end
    qbar = 0.5*Rho*VT_a^2;
    mach = VT/a;
%% MOTOR
    U1 = [dth,mach,zE]';
    dX(1) = fm(t,P3,U1,theta);
    FTint = hm(t,P3,U1);
%% dlef (con el alfa aerodinamico)
    U2 = [alfa_a,qbar,Ps];
    dX(2) = flef(t,X(2),U2,theta);
    dlef  = hlef(t,X(2),U2,theta);
%% Fuerzas y momentos con el viento relativo
    U3 = [de,da,dr,qbar,dlef];
    y3 = hu(t,[VT_a,alfa_a,beta_a,X(6),X(7),X(8)],U3,theta);
    Xint=y3(1); Yint=y3(2); Zint=y3(3); Nint=y3(4); Lint=y3(5); Mint=y3(6);
%% Ecuaciones de movimiento (identicas a funciones.m -> fa.m)
    Xa = X(3:15);
    U3 = [FTint,Xint,Yint,Zint,Nint,Lint,Mint,dlef,qbar]';
    dX(3:15) = fa(t,Xa,U3,theta);
end
