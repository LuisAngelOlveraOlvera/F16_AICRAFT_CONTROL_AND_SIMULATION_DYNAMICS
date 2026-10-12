function y = dCnrlef(alpha)
    teta = [0.0053,-0.008,0.0002];
    y = teta(1)+teta(2)*alpha+teta(3)*alpha.^2;
end
