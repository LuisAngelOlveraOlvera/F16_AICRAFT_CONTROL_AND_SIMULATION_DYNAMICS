function figs = graficar_f16_academico(r,visible)
% GRAFICAR_F16_ACADEMICO  Seis figuras; no altera r ni figuras existentes.
if nargin<2,visible='on';end
cols=[.07 .32 .65;.80 .28 .12;.16 .52 .35];
setdefault=@(f) set(f,'Color','w');
figs.estados=figure('Name',['Estados | ' r.config.escenario],'Visible',visible,'Position',[60 60 1180 800]);
setdefault(figs.estados);t=r.t;deg=180/pi;
tl=tiledlayout(3,3,'Padding','compact','TileSpacing','compact');
nexttile;hh=plot(t,r.altitud_m,'Color',cols(1,:));hh.Tag='altitud_real';lab('Altitud','h [m]');
nexttile;plot(t,r.X(:,3),'Color',cols(1,:));lab('Velocidad verdadera','V_T [m/s]');
nexttile;plot(t,r.Mach);lab('Mach','M [-]');
nexttile;plot(t,r.X(:,4:5)*deg);lab('Angulos aerodinamicos','[deg]');legend('\alpha','\beta');
nexttile;plot(t,r.angulos_rad(:,1:2)*deg);lab('Actitud','[deg]');legend('\phi','\theta');
nexttile;plot(t,unwrap(r.angulos_rad(:,3))*deg);lab('Rumbo','\psi [deg]');
nexttile;plot(t,r.X(:,6:8)*deg);lab('Tasas cuerpo','[deg/s]');legend('p','q','r');
nexttile;plot(t,r.qbar_Pa/1000);lab('Presion dinamica','qbar [kPa]');
nexttile;plot(t,(r.norma_cuaternion-1)*1e14);lab('Deriva de norma','(||Q||-1) x 10^{14}');
title(tl,['F-16 6 DOF | ' strrep(r.config.escenario,'_',' ')]);

figs.mandos=figure('Name','Mandos, motor y LEF','Visible',visible,'Position',[80 80 1180 800]);
setdefault(figs.mandos);tl=tiledlayout(3,2,'Padding','compact');
for j=1:3
    nexttile;plot(t,r.U_comando(:,j),'Color',[.65 .65 .65]);hold on;
    plot(t,r.U_acotado(:,j),'--','Color',cols(3,:));plot(t,r.U_real(:,j),'Color',cols(1,:));
    labels={'Elevador','Aleron','Timon'};lab(labels{j},'[deg]');
    legend('Comando bruto','Acotado','Real','Location','best');
end
nexttile;plot(t,r.U_real(:,4));lab('Throttle','[0..1]');
nexttile;plot(t,r.X(:,1));lab('Potencia del motor','P3 [%]');
nexttile;yyaxis left;plot(t,r.LEF_deg);ylabel('LEF [deg]');yyaxis right;
plot(t,r.empuje_N/1000);ylabel('Empuje [kN]');title('LEF y empuje');grid on;xlabel('t [s]');
title(tl,'Mandos sincronizados con el estado registrado');

figs.cargas=figure('Name','Fuerzas, momentos y aceleraciones','Visible',visible,'Position',[100 100 1180 800]);
setdefault(figs.cargas);tl=tiledlayout(3,2,'Padding','compact');
nexttile;plot(t,r.fuerzas_N/1000);lab('Fuerzas aerodinamicas cuerpo','[kN]');legend('X','Y','Z');
nexttile;plot(t,r.momentos_Nm/1000);lab('Momentos aerodinamicos','[kNm]');legend('L','M','N');
nexttile;plot(t,r.especifica_cuerpo_m_s2);lab('Fuerza especifica (incluye empuje)','[m/s^2]');legend('x_B','y_B','z_B');
nexttile;plot(t,r.aceleracion_inercial_m_s2);lab('Aceleracion NED (incluye gravedad)','[m/s^2]');legend('N','E','D');
nexttile;plot(t,r.an_g);lab('Normal especifica en CG','a_n [g]');
nexttile;plot(t,r.rafaga_m_s);lab('Rafaga cuerpo (Dryden simplificado)','[m/s]');legend('u_g','v_g','w_g');
title(tl,'No confundir fuerza especifica con aceleracion inercial');

figs.seguimiento=figure('Name','Consignas y seguimiento','Visible',visible,'Position',[120 120 1180 720]);
setdefault(figs.seguimiento);tl=tiledlayout(2,3,'Padding','compact');
nexttile;plot(t,r.altitud_m);hold on;hh=plot(t,r.referencia(:,1),'k--');hh.Tag='referencia_h';
plot(t,r.objetivo(:,1),':','Color',[.6 .6 .6]);lab('Altitud','[m]');legend('Real','Ref filtrada','Objetivo');
nexttile;plot(t,r.X(:,3),t,r.referencia(:,2),'k--');lab('Velocidad','[m/s]');
nexttile;plot(t,unwrap(r.angulos_rad(:,3))*deg,t,unwrap(r.referencia(:,3))*deg,'k--');lab('Rumbo','[deg]');
nexttile;plot(t,r.altitud_m-r.referencia(:,1));lab('Error de altitud','[m]');
nexttile;plot(t,r.X(:,3)-r.referencia(:,2));lab('Error de velocidad','[m/s]');
nexttile;plot(t,atan2(sin(r.angulos_rad(:,3)-r.referencia(:,3)), ...
    cos(r.angulos_rad(:,3)-r.referencia(:,3)))*deg);lab('Error de rumbo envuelto','[deg]');
title(tl,sprintf('RMS: h %.2f m | V %.3f m/s | rumbo %.2f deg', ...
    r.metricas.rms_altitud_m,r.metricas.rms_velocidad_m_s,r.metricas.rms_rumbo_deg));

figs.trayectoria=figure('Name','Trayectoria 3D ENU','Visible',visible,'Position',[140 140 1000 740]);
setdefault(figs.trayectoria);
axes('Parent',figs.trayectoria,'Position',[.13 .22 .70 .57]);
idx=unique(round(linspace(1,numel(t),min(6000,numel(t)))));
plot3(r.X(idx,14)/1000,r.X(idx,13)/1000,r.altitud_m(idx)/1000,'Color',cols(1,:),'LineWidth',1.5);hold on;
nom=r.ruta_nominal_ned;plot3(nom(idx,2)/1000,nom(idx,1)/1000,-nom(idx,3)/1000,'k--');
plot3(r.X(1,14)/1000,r.X(1,13)/1000,r.altitud_m(1)/1000,'o','Color',cols(3,:),'MarkerFaceColor',cols(3,:));
plot3(r.X(end,14)/1000,r.X(end,13)/1000,r.altitud_m(end)/1000,'s','Color',cols(2,:),'MarkerFaceColor',cols(2,:));
grid on;axis equal;view(35,25);xlabel('Este [km]');ylabel('Norte [km]');zlabel('Altitud [km]');
legend('Real','Ruta cinematica orientativa','Inicio','Fin','Location','northeastoutside');
title({'Trayectoria 3D (ENU)','Consignas h/V/rumbo; ruta nominal orientativa'});
if isfield(r,'navegacion')
    title({'Trayectoria 3D (ENU)','Seguimiento espacial de ruta por waypoints'});
    legend('Real','Ruta 3D deseada','Inicio','Fin','Location','northeastoutside');
end

figs.modos=figure('Name','Polos del trim de diseno','Visible',visible,'Position',[160 160 1000 500]);
setdefault(figs.modos);tl=tiledlayout(1,2,'Padding','compact');
nexttile;scatter(real(r.control.polos_lon),imag(r.control.polos_lon),65,'filled');xline(0,'k:');grid on;
xlabel('Re [1/s]');ylabel('Im [1/s]');title('Longitudinal (motor y filtro incluidos)');
nexttile;scatter(real(r.control.polos_lat),imag(r.control.polos_lat),65,'filled');xline(0,'k:');grid on;
xlabel('Re [1/s]');ylabel('Im [1/s]');title('Lateral [beta,p,r,phi]');
title(tl,'Polos locales de la planta; giro/ascenso: Jacobiano instantaneo');
end

function lab(titulo,unidad)
grid on;title(titulo);xlabel('t [s]');ylabel(unidad);
end
