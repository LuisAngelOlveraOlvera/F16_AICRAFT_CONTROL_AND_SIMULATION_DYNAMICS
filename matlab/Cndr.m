function y = Cndr(alpha,beta)
    gauss = @(X,xo,Y,yo,sigma,A) A*exp( -( (X-xo).^2+(Y-yo).^2 )/sigma^2 );
    teta = [-0.007824271793252,0.850640977402249];
    Ym01 = gauss(beta,  15, alpha, 36, 10, -0.1000);
    Ym02 = gauss(beta, -15, alpha, 36, 16,  0.0900);
    Ym03 = gauss(beta, -30, alpha,  6, 32, -0.1500);
    Ym04 = gauss(beta,  30, alpha,  6, 14,  0.0800);
    Ym05 = gauss(beta,  30, alpha, 90, 40, -0.0200);
    Ym06 = gauss(beta, -30, alpha, 90, 45,  0.0200);
    Ym   = Ym01 + Ym02 + Ym03 + Ym04 + Ym05 + Ym06;
    y = teta(1)+teta(2)*Ym;
end