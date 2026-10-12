function [y] = Funcion_Tmax(mach,altitud)
    teta = [0.079015880381970,0.976546246176990];
    Ym1  = 12.30-1*gauss01(altitud, 0.0000,mach, 1.0, 1.0, -5.5);
    Ym2  =      -1*gauss01(altitud, 1.5240,mach, 0.2, 2.0, 11.4);
    Ym3  =      -1*gauss01(altitud, 1.5240,mach, 1.0, 0.4,  1.0);
    Ym4  =      -1*gauss01(altitud, 0.0000,mach, 0.2, 0.2, -0.5);
    Ym   = Ym1 + Ym2 + Ym3 + Ym4;
    y    = teta(1)+teta(2)*Ym;
    y=y*1e4;
end