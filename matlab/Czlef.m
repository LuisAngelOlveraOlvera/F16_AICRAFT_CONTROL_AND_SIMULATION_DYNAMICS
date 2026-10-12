function [y] = Czlef(alpha,beta)
    teta = [-0.058427996550182,-0.000574617239301,-0.069490106246787,0.000144828731909,0.000009290975195,0.000000000000058];
    y = teta(1)+teta(2)*beta+teta(3)*alpha+teta(4)*alpha^2+teta(5)*alpha^3+teta(6)*alpha^7;
end