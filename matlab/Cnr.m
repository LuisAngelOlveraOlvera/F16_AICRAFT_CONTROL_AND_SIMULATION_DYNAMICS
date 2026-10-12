function y = Cnr(alpha)
    teta = [-0.5342,-0.0054,0.0001];
    y = teta(1)+teta(2)*alpha+teta(3)*alpha.^2;
end
