function [y] = Funcion_Tidle(mach,altitud)
    teta = [-0.021679531721873,0.986808569463947];
    Ym1  = gauss01(altitud, 0.0000,mach, 1.0, 0.40, -1.6000);
    Ym2  = gauss01(altitud, 0.0000,mach, 0.2, 0.60,  0.3500);
    Ym3  = gauss01(altitud, 1.5240,mach, 0.2, 0.75,  0.7000);
    Ym4  = gauss01(altitud, 1.5240,mach, 1.0, 0.30,  0.1000);
    Ym5  = gauss01(altitud, 0.6096,mach, 0.8, 0.30, -0.4000);
    Ym = Ym1 + Ym2 + Ym3 + Ym4 + Ym5 ;
    y = teta(1)+teta(2)*Ym;
    y = y*1e4;
end