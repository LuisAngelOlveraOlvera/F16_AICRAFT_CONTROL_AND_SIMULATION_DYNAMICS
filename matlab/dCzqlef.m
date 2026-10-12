function y = dCzqlef(alpha)
    teta = [3.0946,-0.5266,0.0102];
    y = teta(1)+teta(2)*alpha+teta(3)*alpha.^2;
end
