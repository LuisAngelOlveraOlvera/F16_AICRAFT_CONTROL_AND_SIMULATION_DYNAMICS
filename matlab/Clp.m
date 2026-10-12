function y = Clp(alpha)
    teta = [-0.3488,0.0044,-2e-5];
    y = teta(1)+teta(2)*alpha+teta(3)*alpha.^2;
end