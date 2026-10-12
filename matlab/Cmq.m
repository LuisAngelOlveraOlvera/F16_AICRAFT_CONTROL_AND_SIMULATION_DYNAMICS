function y = Cmq(alpha)
    teta = [-6.0883,0.0029,0.0002];
    y = teta(1)+teta(2)*alpha+teta(3)*alpha.^2;
end

