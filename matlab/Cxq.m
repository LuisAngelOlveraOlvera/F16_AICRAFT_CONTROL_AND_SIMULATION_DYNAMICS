function y = Cxq(alpha)
    teta = [1.8022,0.025,-0.0005];
    y = teta(1)+teta(2)*alpha+teta(3)*alpha.^2;
end
