function [y] = Cx(alpha,beta,de)
    teta = [-0.058167792386493,-0.000028547600456,0.006491011788641,-0.000029206018766,-0.000000608938486,0.000000000000005,-0.001406325966851];
    y = teta(1)+teta(2)*beta+teta(3)*alpha+teta(4)*alpha^2+teta(5)*alpha^3+teta(6)*alpha^7+teta(7)*de;
end