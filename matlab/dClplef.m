function y = dClplef(alpha)
    teta = [-0.0071,0.0007,8e-5];
    y = teta(1)+teta(2)*alpha+teta(3)*alpha.^2;
end