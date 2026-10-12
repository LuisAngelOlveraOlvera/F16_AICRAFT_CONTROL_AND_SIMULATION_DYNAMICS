function y = dCmds(alpha,de)
    gauss = @(X,xo,Y,yo,sigma,A) A*exp( -( (X-xo).^2+(Y-yo).^2 )/sigma^2 );
    teta = [0.004587286384687,0.848489391522845];
    Ym01 = gauss(de,   0, alpha, 70, 26,  0.1250);
    Ym02 = gauss(de, -25, alpha, 90, 20, -0.0300);
    Ym03 = gauss(de,  25, alpha, 90, 20, -0.0650);
    Ym   = Ym01+Ym02+Ym03;
    y = teta(1)+teta(2)*Ym;
end

