function y = dCyrlef(alpha)
    teta = [-0.0872,0.0217,-0.0005];
    y = teta(1)+teta(2)*alpha+teta(3)*alpha.^2;
end
