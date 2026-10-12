function [y] = Cm(alpha,beta,de)
    teta = [-0.053016014965495,-0.000241978499145,0.000244041048684,0.000115479727957,-0.000002538683564,0.000000000000008,-0.005433237569061];
    y = teta(1)+teta(2)*beta+teta(3)*alpha+teta(4)*alpha^2+teta(5)*alpha^3+teta(6)*alpha^7+teta(7)*de;
end