function[T,presion,Rho,a]=atmosfera(h)
%%  Modelo simplificado de la atm�sfera.
%   altura=Altura del centro de masa de la aeronave
%     respecto al nivel del mar.
    To=288.15; % [To]=�K.
    po=101325; % [po]=N/m^2.
    R=287.05;  % [R]=J/(kg*�K).
    lamda=-0.0065; % [lamda]=K/m.
    go=9.80665; % [go]=m/s^2.
    gamma=1.4;  % razon de calores especificos del aire (estandar).
    ha=11000;
    if h<=ha
        T=To+lamda*h;
        presion=po*(1+lamda*h/To)^(-go/(R*lamda));
    else 
        T=To+lamda*ha;
        presion=po*(1+lamda*ha/To)^(-go/(R*lamda))*exp(-go*(h-ha)/(R*T));
    end
    Rho=presion/(R*T);
    a=sqrt(gamma*R*T);
end