function y = dClb(alpha)
    teta = [9e-5,3e-6,-6e-8];
    y = teta(1)+teta(2)*alpha+teta(3)*alpha.^2;
end
