function y = dClrlef(alpha)
    teta = [0.1293,0.0003,-0.0004];
    y = teta(1)+teta(2)*alpha+teta(3)*alpha.^2;
end
