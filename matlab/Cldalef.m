function y = Cldalef(alpha,beta)
    gauss = @(X,xo,Y,yo,sigma,A) A*exp( -( (X-xo).^2+(Y-yo).^2 )/sigma^2 );
    teta = [-0.006940790611846,0.988889095499375];
    Ym01  = gauss(beta, -30, alpha,  45, 50,  0.0800);
    Ym02  = gauss(beta,  30, alpha,  45, 50, -0.0800);
    Ym03  = gauss(beta, -30, alpha,  22, 20,  0.0001);
    Ym04  = gauss(beta,  30, alpha,  22, 20, -0.0001);
    Ym05  = gauss(beta, -30, alpha, -20, 35, -0.0550);
    Ym06  = gauss(beta,  30, alpha, -20, 30,  0.0500);
    Ym07  = gauss(beta, -15, alpha, -20, 15,  0.0150);
    Ym08  = gauss(beta,  15, alpha, -20, 15, -0.0650);
    Ym09  = gauss(beta, -15, alpha,  45, 15, -0.0100);
    Ym10  = gauss(beta,  15, alpha,  45, 15,  0.0100);
    Ym11  = gauss(beta,  30, alpha,  10, 15, -0.0800);
    Ym = Ym01 + Ym02 + Ym03 + Ym04 + Ym05 + Ym06 + Ym07 + Ym08 + Ym09 + Ym10 + Ym11;
    y = teta(1)+teta(2)*Ym;
end