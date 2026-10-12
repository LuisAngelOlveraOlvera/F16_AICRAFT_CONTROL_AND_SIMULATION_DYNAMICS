function y = Cydr(alpha,beta)
    gauss = @(X,xo,Y,yo,sigma,A) A*exp( -( (X-xo).^2+(Y-yo).^2 )/sigma^2 );
    teta = [0.063506096652943,0.790357271432444];
    Ym01 = gauss(beta, -30, alpha,  7, 30,  0.7000);
    Ym02 = gauss(beta,  30, alpha,  7, 30, -0.7000);
    Ym03 = gauss(beta, -30, alpha, 90, 50,  0.3990);
    Ym04 = gauss(beta,  30, alpha, 90, 50, -0.3990);
    Ym05 = gauss(beta, -30, alpha, 50, 25, -0.1200);
    Ym06 = gauss(beta,  30, alpha, 50, 20, -0.0300);
    Ym = Ym01 + Ym02 + Ym03 + Ym04 + Ym05 + Ym06;
    y = teta(1)+teta(2)*Ym;
end