function y = dCnplef(alpha)
    teta = [0.0076,-0.0012,0.0002];
    y = teta(1)+teta(2)*alpha+teta(3)*alpha.^2;
end
