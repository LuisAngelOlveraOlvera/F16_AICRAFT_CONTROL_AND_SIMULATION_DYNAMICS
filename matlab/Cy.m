function y = Cy(alpha,beta)
    gauss = @(X,xo,Y,yo,sigma,A) A*exp( -( (X-xo).^2+(Y-yo).^2 )/sigma^2 );
    teta = [0.019744634907533,0.866893553554607];
    Ym01 = gauss(beta, -30, alpha,  7, 30,  0.6200);
    Ym02 = gauss(beta,  30, alpha,  7, 30, -0.6200);
    Ym03 = gauss(beta, -30, alpha, 90, 50,  0.3990);
    Ym04 = gauss(beta,  30, alpha, 90, 50, -0.3990);
    Ym05 = gauss(beta, -30, alpha, 50, 25, -0.1000);
    Ym06 = gauss(beta,  30, alpha, 50, 25, -0.1000);
    Ym = Ym01 + Ym02 + Ym03 + Ym04 + Ym05 + Ym06;
    y = teta(1)+teta(2)*Ym;
    
end