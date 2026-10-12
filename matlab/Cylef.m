function y = Cylef(alpha,beta)
    gauss = @(X,xo,Y,yo,sigma,A) A*exp( -( (X-xo).^2+(Y-yo).^2 )/sigma^2 );
    teta = [0.008757883384847,0.862109391055227];
    Ym01 = gauss(beta, -30, alpha,   7, 20,  0.400);
    Ym02 = gauss(beta,  30, alpha,   7, 20, -0.400);
    Ym03 = gauss(beta, -30, alpha,  45, 50,  0.3990);
    Ym04 = gauss(beta,  30, alpha,  45, 50, -0.3990);
    Ym05 = gauss(beta, -30, alpha,  30, 25, -0.1000);
    Ym06 = gauss(beta,  30, alpha,  30, 25, -0.1000);
    Ym07 = gauss(beta, -30, alpha, -20, 35,  0.3000);
    Ym08 = gauss(beta,  30, alpha, -20, 35, -0.3000);
    Ym   = Ym01 + Ym02 + Ym03 + Ym04 + Ym05 + Ym06 + Ym07 + Ym08;
    y = teta(1)+teta(2)*Ym;
end