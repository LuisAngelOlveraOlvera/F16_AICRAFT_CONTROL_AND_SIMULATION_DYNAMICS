function y = Cnda(alpha,beta)
    gauss = @(X,xo,Y,yo,sigma,A) A*exp( -( (X-xo).^2+(Y-yo).^2 )/sigma^2 );
    teta = [0.000454321190216,0.823762651935457];
    Ym01 = gauss(beta,  15, alpha, 36, 20, -0.1000);
    Ym02 = gauss(beta, -15, alpha, 36, 20,  0.1000);
    Ym03 = gauss(beta, -30, alpha,  6, 28, -0.1300);
    Ym04 = gauss(beta,  30, alpha,  6, 28,  0.1100);
    Ym05 = gauss(beta,  30, alpha, 90, 40, -0.00700);
    Ym06 = gauss(beta, -30, alpha, 90, 45,  0.0300);
    Ym   = Ym01 + Ym02 + Ym03 + Ym04 + Ym05 + Ym06;
    y = teta(1)+teta(2)*Ym;
end