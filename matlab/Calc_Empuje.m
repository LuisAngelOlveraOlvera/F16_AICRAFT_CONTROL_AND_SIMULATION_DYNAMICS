function y = Calc_Empuje(P3,Tidle,Tmil,Tmax)
    if P3 < 50
        y = Tidle+(Tmil-Tidle)*P3/50;
    else 
        y = Tmil+(Tmax-Tmil)*(P3-50)/50;
    end
end