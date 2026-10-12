function y = dCnb(alpha)
    teta = [3e-6,1e-6,-1e-8];
    y = teta(1)+teta(2)*alpha+teta(3)*alpha.^2;
end
