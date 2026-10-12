function [y] = Cz(alpha,beta,de)
    teta = [-0.091238995686850,-0.000425255531389,-0.064942888822511,0.000215918921229,0.000005939707941,-0.000000000000046,-0.006157878453039];
    y = teta(1)+teta(2)*beta+teta(3)*alpha+teta(4)*alpha^2+teta(5)*alpha^3+teta(6)*alpha^7+teta(7)*de;
end