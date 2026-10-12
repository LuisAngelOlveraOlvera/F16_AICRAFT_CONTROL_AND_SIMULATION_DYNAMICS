function [y] = Funcion_Tmil(mach,altitud)
    teta = [0.016212936579475,1.005049730845808];
    Ym1  = 7.3500-1*gauss01(altitud, 0.6000,mach, 0.2, 6.0, 1.800);
    Ym2  =       -1*gauss01(altitud, 0.6000,mach, 1.0, 6.0, 2.000);
    Ym3  =       -1*gauss01(altitud, 1.5240,mach, 0.2, 1.5, 3.800);
    Ym4  =       -1*gauss01(altitud, 0.0000,mach, 1.0, 1.5,-2.500);
    Ym5  =       -1*gauss01(altitud, 0.0000,mach, 0.2, 0.4,-1.500);
    Ym6  =       -1*gauss01(altitud, 1.5240,mach, 1.0, 0.4, 0.700);
    Ym   = Ym1 + Ym2 + Ym3 + Ym4 + Ym5 + Ym6;
    y    = teta(1)+teta(2)*Ym;
    y = y*1e4;
end