function y = Cnlef(alpha,beta)
    gauss = @(X,xo,Y,yo,sigma,A) A*exp( -( (X-xo).^2+(Y-yo).^2 )/sigma^2 );
    teta = [-0.000353759398496,0.907026824141920];
    Ym01 = gauss(beta,  15, alpha, 36, 20, -0.0500);
    Ym02 = gauss(beta, -15, alpha, 36, 20,  0.0500);
    Ym03 = gauss(beta, -30, alpha,  6, 28, -0.1200);
    Ym04 = gauss(beta,  30, alpha,  6, 28,  0.1200);
    Ym05 = gauss(beta,  30, alpha, 45, 30, -0.0300);
    Ym06 = gauss(beta, -30, alpha, 45, 30,  0.0300);
    Ym   = Ym01 + Ym02 + Ym03 + Ym04 + Ym05 + Ym06;
    y = teta(1)+teta(2)*Ym;
end