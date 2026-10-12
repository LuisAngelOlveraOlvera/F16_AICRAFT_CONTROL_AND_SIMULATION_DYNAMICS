function y = dCmqlef(alpha)
    teta = [0.0322,-0.0235,-0.0004];
    y = teta(1)+teta(2)*alpha+teta(3)*alpha.^2;
end