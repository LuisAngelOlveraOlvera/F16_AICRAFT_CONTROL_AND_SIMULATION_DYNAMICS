function [y] = Cl(alpha,beta,de)
    gauss = @(X,xo,Y,yo,sigma,A) A*exp( -( (X-xo).^2+(Y-yo).^2 )/sigma^2 );
    teta = [-0.000435799168635,0.926430028503601,-0.000002636039899];
    Ym01  = gauss(beta, -30, alpha,  90, 48,  0.0990);
    Ym02  = gauss(beta,  30, alpha,  90, 50, -0.0900);
    Ym03  = gauss(beta, -30, alpha,  22, 24,  0.0800);
    Ym04  = gauss(beta,  30, alpha,  22, 24, -0.0800);
    Ym05  = gauss(beta, -30, alpha, -20, 25, -0.0250);
    Ym06  = gauss(beta,  30, alpha, -20, 25,  0.0250);
    Ym07  = gauss(beta, -15, alpha, -20, 15,  0.0250);
    Ym08  = gauss(beta,  15, alpha, -20, 15, -0.0250);
    Ym09  = gauss(beta, -15, alpha,  90, 15, -0.0200);
    Ym010 = gauss(beta,  15, alpha,  90, 15,  0.0200);
    Ym    = Ym01 + Ym02 + Ym03 + Ym04 + Ym05 + Ym06 + Ym07 + Ym08 + Ym09 + Ym010;
    y = teta(1)+teta(2)*Ym+teta(3)*de;
end