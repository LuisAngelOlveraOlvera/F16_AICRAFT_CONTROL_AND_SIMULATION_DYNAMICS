function y = Cyr(alpha)
    teta = [1.0038,-0.0405,0.0003];
    y = teta(1)+teta(2)*alpha+teta(3)*alpha.^2;
end
