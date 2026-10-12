function y = dCm(alpha)
    teta = [0.0225,0.0012,-9e-6];
    y = teta(1)+teta(2)*alpha+teta(3)*alpha.^2;
end