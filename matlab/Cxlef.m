function [y] = Cxlef(alpha,beta)
    teta = [-0.010506953719709,0.000023298673900,0.001721766817944,0.000029515725369,-0.000001689841463,0.000000000000148];
    y = teta(1)+teta(2)*beta+teta(3)*alpha+teta(4)*alpha^2+teta(5)*alpha^3+teta(6)*alpha^7;
end