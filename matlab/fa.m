function [dX]=fa(t,X,U,theta)
VT = X(1); alfa = X(2); beta = X(3); p = X(4); q = X(5); r = X(6); 
q0 = X(7); q1 = X(8); q2 = X(9); q3 = X(10); xE = X(11); yE = X(12);  zE = X(13);
dX = zeros(13,1);   % Vector de derivadas (columna) correctamente dimensionado
[m,g,S,cbar,b,Xcgr,Xcg,c1,c2,c3,c4,c5,c6,c7,c8,c9,Heng]=parametros(theta);
FTint = U(1); Xint = U(2); Yint = U(3); Zint = U(4); Nint = U(5); Lint = U(6); Mint = U(7); dlef = U(8); qbar =U(9);
%     g  = 9.80665;         
%     m    = 9295.44;        
%     n = m*g; 
%     
%     if zE < 0
%         k = 0;
%         Frm = 0;
%     else
%         k = 0.03;
%         Frm = -g;
%     end
%     
    %% Ecuaciones de eje de viento
    u=VT*cos(alfa)*cos(beta);
    v=VT*sin(beta);
    w=VT*sin(alfa)*cos(beta);  
    
    teta = asin(2*(q0*q2-q1*q3));
    fi   = atan2(2*(q0*q1+q2*q3), q0^2-q1^2-q2^2+q3^2);
% Fuerza de arrastre D, fuerza lateral Y, fuerza de levantamiento L   
    D = -Xint*cos(alfa)*cos(beta)-Yint*sin(beta)-Zint*sin(alfa)*cos(beta);
    Y = -Xint*cos(alfa)*sin(beta)+Yint*cos(beta)-Zint*sin(alfa)*sin(beta);
    L = Xint*sin(alfa)-Zint*cos(alfa);
% Componentes de gravedad para ecuaciones de marco de ejes de viento
    g1 = g*(-cos(alfa)*cos(beta)*sin(teta)+sin(beta)*sin(fi)*cos(teta)+sin(alfa)*cos(beta)*cos(fi)*cos(teta));
    g2 = g*( cos(alfa)*sin(beta)*sin(teta)+cos(beta)*sin(fi)*cos(teta)-sin(alfa)*sin(beta)*cos(fi)*cos(teta));
    g3 = g*( sin(alfa)*sin(teta)+cos(alfa)*cos(fi)*cos(teta));
    %% Ecuaciones de eje de viento
    dX(1) = (-D+FTint*cos(alfa)*cos(beta)+m*g1)/m;
    if VT==0
        dX(2)=0;
        dX(3)=0;
    else
    dX(2) = q-(p*cos(alfa)+r*sin(alfa))*tan(beta)-(L+FTint*sin(alfa)-m*(g3))/(m*VT*cos(beta));
    dX(3) = p*sin(alfa)-r*cos(alfa)+(Y-FTint*cos(alfa)*sin(beta)+m*g2)/(m*VT);
    end
%%  Ecuaciones de momentos, movimiento rotacional
    dX(4)  = (c1*r+c2*p)*q+c3*Lint+c4*(Nint+q*Heng);
    dX(5)  = c5*p*r-c6*(p^2-r^2)+c7*(Mint-r*Heng);
    dX(6)  = (c8*p-c2*r)*q+c4*Lint+c9*(Nint+q*Heng);
%%  Restricciones Cinem�ticas, cuaternios 
    dX(7)  = 0.5*(    -p*q1-q*q2-r*q3);
    dX(8)  = 0.5*(p*q0     +r*q2-q*q3);
    dX(9)  = 0.5*(q*q0-r*q1     +p*q3);
    dX(10) = 0.5*(r*q0+q*q1-p*q2     );
%%  Ecuaciones de posici�n
    dX(11) = (q0^2+q1^2-q2^2-q3^2)*u+2*(q1*q2-q0*q3)*v+2*(q1*q3+q0*q2)*w;
    dX(12) = 2*(q1*q2+q0*q3)*u+(q0^2-q1^2+q2^2-q3^2)*v+2*(q2*q3-q0*q1)*w;

    dX(13) = (2*(q1*q3-q0*q2)*u+2*(q2*q3+q0*q1)*v+(q0^2-q1^2-q2^2+q3^2)*w);
end