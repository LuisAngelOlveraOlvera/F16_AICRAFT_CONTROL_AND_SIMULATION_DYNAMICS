function y = Cllef(alpha,beta)
    gauss = @(X,xo,Y,yo,sigma,A) A*exp( -( (X-xo).^2+(Y-yo).^2 )/sigma^2 );
    teta = [-0.001243947996349,1.014224957479365];
    Ym01  = gauss(beta, -30, alpha,  45, 50,  0.0600);
    Ym02  = gauss(beta,  30, alpha,  45, 50, -0.0600);
    Ym03  = gauss(beta, -30, alpha,  22, 20,  0.0300);
    Ym04  = gauss(beta,  30, alpha,  22, 20, -0.0300);
    Ym05  = gauss(beta, -30, alpha, -20, 20, -0.0380);
    Ym06  = gauss(beta,  30, alpha, -20, 20,  0.0480);
    Ym07  = gauss(beta, -15, alpha, -20, 15,  0.0250);
    Ym08  = gauss(beta,  15, alpha, -20, 15, -0.0250);
    Ym09  = gauss(beta, -15, alpha,  45, 15, -0.0200);
    Ym010 = gauss(beta,  15, alpha,  45, 15,  0.0200);
    Ym    = Ym01 + Ym02 + Ym03 + Ym04 + Ym05 + Ym06 + Ym07 + Ym08 + Ym09 + Ym010;
    y = teta(1)+teta(2)*Ym;
end