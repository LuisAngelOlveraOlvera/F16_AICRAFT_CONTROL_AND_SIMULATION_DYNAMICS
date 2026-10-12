function y = Calc_inv_Tt(P2,P3)
    m = -0.0360;  % Calcular
    b = 1.9;  % Calcular 
    x = P2-P3;
    if x<25
        y = 1;
    elseif (x>=25) && (x<=50)
        y = b + m*x; 
        
    else
         y = 0.1;
    end
end