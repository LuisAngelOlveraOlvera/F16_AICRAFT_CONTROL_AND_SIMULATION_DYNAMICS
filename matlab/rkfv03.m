function [tn,hn,Xn] = rkfv03(funciones,to,h,Xo,U,theta)
% RKFV03  Integrador Runge-Kutta-Fehlberg de PASO FIJO.
%   Usa los coeficientes RKF45 pero avanza con la solucion de 4o orden y
%   NO adapta el paso (el control adaptativo original quedo comentado
%   abajo; reactivarlo requiere descomentar el while y el calculo de R/s).
%   Con h=0.002 s es mas que suficiente para la dinamica del F-16.
   format long
    tol = 1e-3;
    R   = 2*tol;
    A   = [1/4,3/8,3/32,9/32,12/13,1932/2197,7200/2197,7296/2197,439/216,3680/513,845/4104,1/2,8/27,3544/2565,1859/4104,11/40];
    B   = [25/216,1408/2565,2197/4104,1/5,16/135,6656/12825,28561/56430,9/50,2/55];
   % while (R>tol)

        k1 = h*funciones(to,Xo,U,theta);
        k2 = h*funciones(to+A(1)*h,Xo+A(1)*k1,U,theta);
        k3 = h*funciones(to+A(2)*h,Xo+A(3)*k1+A(4)*k2,U,theta);
        k4 = h*funciones(to+A(5)*h,Xo+A(6)*k1-A(7)*k2+A(8)*k3,U,theta);
        k5 = h*funciones(to+h,Xo+A(9)*k1-8*k2+A(10)*k3-A(11)*k4,U,theta);
        k6 = h*funciones(to+A(12)*h,Xo-A(13)*k1+2*k2-A(14)*k3+A(15)*k4-A(16)*k5,U,theta);

        Xn1 = Xo+B(1)*k1+B(2)*k3+B(3)*k4-B(4)*k5;
%         Xn2 = Xo+B(5)*k1+B(6)*k3+B(7)*k4-B(8)*k5+B(9)*k6;
%      
%         R  = norm(Xn2-Xn1)/h;
%         s  = 0.84*(tol*h/R)^0.25;
%         hn = h;      % Se almacena el valor probable de h
%         h  = s*h;     
%     end
    Xn = Xn1;
    hn=h;
    tn = to+hn;
    format short
end