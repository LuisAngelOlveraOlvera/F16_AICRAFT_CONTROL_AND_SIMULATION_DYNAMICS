function [y] = Cn(alpha,beta,de)
    gauss = @(X,xo,Y,yo,sigma,A) A*exp( -( (X-xo).^2+(Y-yo).^2 )/sigma^2 );
    teta = [-0.001440372540832,0.395674436639150,-0.000000682405010];
    Ym01 = gauss(beta,  15, alpha, 36, 20, -0.1790);
    Ym02 = gauss(beta, -15, alpha, 36, 20,  0.1790);
    Ym03 = gauss(beta, -30, alpha,  6, 28, -0.2200);
    Ym04 = gauss(beta,  30, alpha,  6, 28,  0.2200);
    Ym05 = gauss(beta,  30, alpha, 90, 45, -0.0300);
    Ym06 = gauss(beta, -30, alpha, 90, 45,  0.0300);
    Ym   = Ym01 + Ym02 + Ym03 + Ym04 + Ym05 + Ym06;
    y = teta(1)+teta(2)*Ym+teta(3)*de;
end