function y = Cydalef(alpha,beta)
    gauss = @(X,xo,Y,yo,sigma,A) A*exp( -( (X-xo).^2+(Y-yo).^2 )/sigma^2 );
    teta = [0.008355886662505,0.930178282294210];
    Ym01 = gauss(beta, -30, alpha,  7, 26,  0.5000);
    Ym02 = gauss(beta,  30, alpha,  7, 26, -0.5000);
    Ym03 = gauss(beta, -30, alpha, 45, 50,  0.2000);
    Ym04 = gauss(beta,  30, alpha, 45, 44, -0.2000);
    Ym05 = gauss(beta, -30, alpha, 50, 25, -0.1000);
    Ym06 = gauss(beta,  30, alpha, 50, 25, -0.1000);
    Ym07 = gauss(beta, -30, alpha,-20, 15,  0.2000);
    Ym08 = gauss(beta,  30, alpha,-20, 15, -0.2000);
    Ym = Ym01 + Ym02 + Ym03 + Ym04 + Ym05 + Ym06 + Ym07 + Ym08;
    y = teta(1)+teta(2)*Ym;
end