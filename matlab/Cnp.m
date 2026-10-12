function y = Cnp(alpha)
    teta = [0.0261,0.0016,-3e-5];
    y = teta(1)+teta(2)*alpha+teta(3)*alpha.^2;
end
