function y = Czq(alpha)
    teta = [-29.289,-0.3097,0.0063];
    y = teta(1)+teta(2)*alpha+teta(3)*alpha.^2;
end 
