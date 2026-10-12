function r=ejecutar_waypoints_f16(opciones,carpeta)
% EJECUTAR_WAYPOINTS_F16 Integra, registra y conserva la animacion de dos vistas.
% Coordenadas waypoint NED [Norte,Este,Abajo] en metros, con h=-Abajo.
if nargin<1,opciones=struct;end
if nargin<2,carpeta=['vuelo_waypoints_' datestr(now,'yyyymmdd_HHMMSS')];end
assert(~exist(carpeta,'file'),'f16:Salida','Carpeta existente: no se sobrescribe.');
mkdir(carpeta);
cfg=struct('escenario','waypoints','duracion',180,'paso',.002);
names=fieldnames(opciones);
for i=1:numel(names),cfg.(names{i})=opciones.(names{i});end
assert(strcmp(cfg.escenario,'waypoints'),'f16:Escenario','Este ejecutor requiere waypoints.');
r=simular_f16_academico(cfg);
save(fullfile(carpeta,'registro.mat'),'r','-v7.3');
f16_guardar_json(fullfile(carpeta,'metricas.json'),r.metricas);
registro=table(r.t,r.X(:,13),r.X(:,14),r.altitud_m,r.X(:,3), ...
    r.navegacion.tramo,r.navegacion.error_transversal_m,r.navegacion.error_espacial_m, ...
    'VariableNames',{'t_s','Norte_m','Este_m','h_m','VT_m_s','tramo','error_horizontal_m','error_espacial_m'});
writetable(registro,fullfile(carpeta,'registro.csv'));
figs=graficar_f16_academico(r,'off');names=fieldnames(figs);
for i=1:numel(names)
    exportgraphics(figs.(names{i}),fullfile(carpeta,[names{i} '.png']),'Resolution',120);
    close(figs.(names{i}));
end
f=figure('Visible','off','Color','w');
plot(r.t,r.navegacion.error_transversal_m,r.t,r.navegacion.error_espacial_m);
grid on;xlabel('t [s]');ylabel('Distancia a la ruta [m]');legend('Horizontal','Espacial 3D');
exportgraphics(f,fullfile(carpeta,'error_posicion.png'),'Resolution',120);close(f);
a=animar_f16_academico(r,struct('visible','off','video',fullfile(carpeta,'vuelo_3d.mp4'),'velocidad',12));
exportgraphics(a.figura,fullfile(carpeta,'animacion_final.png'),'Resolution',120);close(a.figura);
fprintf('WAYPOINTS: t=%.3f s; RMS espacial=%.3f m; max=%.3f m; llegada=%.3f m; completada=%d\n', ...
    r.t(end),r.metricas.rms_error_espacial_m,r.metricas.max_error_espacial_m, ...
    r.metricas.distancia_final_m,r.metricas.ruta_completada);
end
