function y = Cyp(alpha)
    teta = [0.1286,0.0145,-0.0002];
    y = teta(1)+teta(2)*alpha+teta(3)*alpha.^2;
end
