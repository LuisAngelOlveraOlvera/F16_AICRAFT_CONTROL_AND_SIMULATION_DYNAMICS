function y = Cndalef(alpha,beta)
    gauss = @(X,xo,Y,yo,sigma,A) A*exp( -( (X-xo).^2+(Y-yo).^2 )/sigma^2 );
    teta = [-0.001364218115686,0.870921134743448];
    Ym01 = gauss(beta,  15, alpha, 36, 20, -0.1000);
    Ym02 = gauss(beta, -15, alpha, 36, 20,  0.1000);
    Ym03 = gauss(beta, -30, alpha,  6, 28, -0.1300);
    Ym04 = gauss(beta,  30, alpha,  6, 28,  0.1100);
    Ym05 = gauss(beta,  30, alpha, 90, 40,  0.0100);
    Ym06 = gauss(beta, -30, alpha, 90, 45,  0.0200);
    Ym   = Ym01 + Ym02 + Ym03 + Ym04 + Ym05 + Ym06;
    y = teta(1)+teta(2)*Ym; 
end