function P1 = Calc_P1(dth)
    if (dth >= 0)&&(dth <= 1)
        if dth <= 0.77
            P1 = 64.94*dth;
        else
            P1 = 217.38*dth-117.38;
        end
    else
        fprintf('Error, dth fuera de rango')
    end
end