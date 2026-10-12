function y = dCyplef(alpha)
    teta = [-0.0382,0.0026,-0.0002];
    y = teta(1)+teta(2)*alpha+teta(3)*alpha.^2;
end
