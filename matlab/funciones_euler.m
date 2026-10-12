function[dX]=funciones_euler(t,X,U,theta)
% FUNCIONES_EULER  Modelo NO lineal 6-DOF con actitud en ANGULOS DE EULER.
%   Mismas ecuaciones traslacionales (ejes viento) y de momentos que
%   funciones.m, pero la cinematica de actitud usa (fi, teta, psi) en vez
%   de cuaterniones. Util para comparar formulaciones y para analisis
%   clasico; tiene la singularidad de Euler en teta = +-90 deg.
%
%   X = [P3, alfaf, VT, alfa, beta, p, q, r, fi, teta, psi, xE, yE, zE]'
%         1    2     3    4     5   6  7  8   9   10    11  12  13  14
%   U = [de da dr dth]'   (superficies en grados, mariposa 0-1)
    dX = 0*X;
    P3=X(1); VT=X(3); alfa=X(4); beta=X(5);
    p=X(6); q=X(7); r=X(8);
    fi=X(9); teta=X(10); psi=X(11); zE=X(14);
    de=U(1); da=U(2); dr=U(3); dth=U(4);
    [m,g,S,cbar,b,Xcgr,Xcg,c1,c2,c3,c4,c5,c6,c7,c8,c9,Heng]=parametros(theta);

    [~,Ps,Rho,a]=atmosfera(-zE);   % NED: altitud h = -zE
    qbar = 0.5*Rho*VT^2;
    mach = VT/a;
%% MOTOR
    U1 = [dth,mach,zE]';
    dX(1) = fm(t,P3,U1,theta);
    FTint = hm(t,P3,U1);
%% Leading-edge flap
    U2 = [alfa,qbar,Ps];
    dX(2) = flef(t,X(2),U2,theta);
    dlef  = hlef(t,X(2),U2,theta);
%% Fuerzas y momentos aerodinamicos (ejes cuerpo)
    U3 = [de,da,dr,qbar,dlef];
    y3 = hu(t,[VT,alfa,beta,p,q,r],U3,theta);
    Xint=y3(1); Yint=y3(2); Zint=y3(3); Nint=y3(4); Lint=y3(5); Mint=y3(6);
%% Velocidades en ejes cuerpo
    u=VT*cos(alfa)*cos(beta);
    v=VT*sin(beta);
    w=VT*sin(alfa)*cos(beta);
%% Fuerzas en ejes viento
    D = -Xint*cos(alfa)*cos(beta)-Yint*sin(beta)-Zint*sin(alfa)*cos(beta);
    Y = -Xint*cos(alfa)*sin(beta)+Yint*cos(beta)-Zint*sin(alfa)*sin(beta);
    L =  Xint*sin(alfa)-Zint*cos(alfa);
%% Gravedad en ejes viento (con fi, teta directos)
    g1 = g*(-cos(alfa)*cos(beta)*sin(teta)+sin(beta)*sin(fi)*cos(teta)+sin(alfa)*cos(beta)*cos(fi)*cos(teta));
    g2 = g*( cos(alfa)*sin(beta)*sin(teta)+cos(beta)*sin(fi)*cos(teta)-sin(alfa)*sin(beta)*cos(fi)*cos(teta));
    g3 = g*( sin(alfa)*sin(teta)+cos(alfa)*cos(fi)*cos(teta));
%% Ecuaciones traslacionales (ejes viento)
    dX(3) = (-D+FTint*cos(alfa)*cos(beta)+m*g1)/m;
    if VT==0
        dX(4)=0; dX(5)=0;
    else
        dX(4) = q-(p*cos(alfa)+r*sin(alfa))*tan(beta)-(L+FTint*sin(alfa)-m*g3)/(m*VT*cos(beta));
        dX(5) = p*sin(alfa)-r*cos(alfa)+(Y-FTint*cos(alfa)*sin(beta)+m*g2)/(m*VT);
    end
%% Ecuaciones de momentos (identicas a fa.m)
    dX(6) = (c1*r+c2*p)*q+c3*Lint+c4*(Nint+q*Heng);
    dX(7) = c5*p*r-c6*(p^2-r^2)+c7*(Mint-r*Heng);
    dX(8) = (c8*p-c2*r)*q+c4*Lint+c9*(Nint+q*Heng);
%% Cinematica de Euler (singular en teta = +-90 deg)
    dX(9)  = p + tan(teta)*(q*sin(fi)+r*cos(fi));
    dX(10) = q*cos(fi)-r*sin(fi);
    dX(11) = (q*sin(fi)+r*cos(fi))/cos(teta);
%% Posicion NED via DCM(fi,teta,psi)
    dX(12) = u*cos(teta)*cos(psi) + v*(sin(fi)*sin(teta)*cos(psi)-cos(fi)*sin(psi)) ...
           + w*(cos(fi)*sin(teta)*cos(psi)+sin(fi)*sin(psi));
    dX(13) = u*cos(teta)*sin(psi) + v*(sin(fi)*sin(teta)*sin(psi)+cos(fi)*cos(psi)) ...
           + w*(cos(fi)*sin(teta)*sin(psi)-sin(fi)*cos(psi));
    dX(14) = -u*sin(teta) + v*sin(fi)*cos(teta) + w*cos(fi)*cos(teta);
end
