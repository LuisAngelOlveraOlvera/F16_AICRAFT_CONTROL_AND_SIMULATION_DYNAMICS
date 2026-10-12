function[dX]=fm(t,X,U,theta)
    P3 = X;
    dth = U(1);
    P1 = Calc_P1(dth);
    %% Calculo de P2
    if P1 < 50
        if P3 < 50
            P2 = P1;
            inv_Tt = Calc_inv_Tt(P2,P3);  
        else
            P2 = 40;
            inv_Tt = 5.0;
        end
    else
        if P3 < 50
            P2 = 60;
            inv_Tt = Calc_inv_Tt(P2,P3);
        else
            P2 = P1;
            inv_Tt = 5.0;
        end
    end
    %% Calculo de dP3/dt
    dX = inv_Tt*(P2-P3); 
end