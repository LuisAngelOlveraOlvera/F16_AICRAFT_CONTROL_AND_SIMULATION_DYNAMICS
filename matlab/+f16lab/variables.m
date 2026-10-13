function [labels,y]=variables(r,label)
labels={'Altitud [m]','Velocidad [m/s]','Alfa [°]','Beta [°]','Alabeo [°]','Cabeceo [°]','Rumbo [°]', ...
 'p [°/s]','q [°/s]','r [°/s]','Elevador [°]','Alerón [°]','Timón [°]','Throttle [0-1]', ...
 'Mach','Empuje [N]','Presión dinámica [Pa]','Normal específica [g]', ...
 'Fuerza X [N]','Fuerza Y [N]','Fuerza Z [N]','Momento L [N·m]','Momento M [N·m]','Momento N [N·m]', ...
 'Ráfaga u [m/s]','Ráfaga v [m/s]','Ráfaga w [m/s]','LEF [°]'};
if nargin<2,y=[];return;end
idx=find(strcmp(labels,label),1);assert(~isempty(idx),'lab:Variable','Variable desconocida.');
switch idx
 case 1,y=r.altitud_m;case 2,y=r.X(:,3);
 case {3,4},y=r.X(:,idx+1)*180/pi;
 case {5,6},y=r.angulos_rad(:,idx-4)*180/pi;
 case 7,y=unwrap(r.angulos_rad(:,3))*180/pi;
 case {8,9,10},y=r.X(:,idx-2)*180/pi;
 case {11,12,13,14},y=r.U_real(:,idx-10);
 case 15,y=r.Mach;case 16,y=r.empuje_N;case 17,y=r.qbar_Pa;case 18,y=r.an_g;
 case {19,20,21},y=r.fuerzas_N(:,idx-18);
 case {22,23,24},y=r.momentos_Nm(:,idx-21);
 case {25,26,27},y=r.rafaga_m_s(:,idx-24);
 case 28,y=r.LEF_deg;
end
end
