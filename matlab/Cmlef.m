function y = Cmlef(alpha,beta)
    teta = [-0.027090750432187,-0.000178931585292,0.000986056281143,-0.000005706787715,-0.000003396643484,0.000000000000570];
    y = teta(1)+teta(2)*beta+teta(3)*alpha+teta(4)*alpha.^2+teta(5)*alpha.^3+teta(6)*alpha.^7;
end