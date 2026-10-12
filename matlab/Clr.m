function y = Clr(alpha)
    teta = [0.0424,0.0096,-0.0001];
    y = teta(1)+teta(2)*alpha+teta(3)*alpha.^2;
end