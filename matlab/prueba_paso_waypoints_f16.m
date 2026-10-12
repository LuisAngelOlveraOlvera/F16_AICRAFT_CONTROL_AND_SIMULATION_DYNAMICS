function prueba_paso_waypoints_f16
% Detecta sensibilidad excesiva del lazo discreto y fin prematuro de la ruta.
cfg=struct('escenario','waypoints','duracion',20,'paso',.004, ...
    'waypoints_ned',[0 0 -3000;12000 0 -3000], ...
    'posicion_inicial_ned',[0 200 -3000]);
a=simular_f16_academico(cfg);cfg.paso=.002;b=simular_f16_academico(cfg);
dp=norm(a.X(end,13:15)-b.X(end,13:15));
assert(dp<.5 && max(abs(a.X(end,3:8)-b.X(end,3:8)))<.01);
c=simular_f16_academico(struct('escenario','waypoints','duracion',20,'paso',.004, ...
    'waypoints_ned',[0 0 -3000;2000 0 -3000]));
assert(c.navegacion.finalizado && c.t(end)<20);
assert(c.metricas.distancia_final_m<=250 && c.metricas.distancia_final_m>249);
assert(size(c.X,1)==numel(c.t) && size(c.ruta_nominal_ned,1)==numel(c.t));
fprintf('PRUEBA_PASO_WAYPOINTS: PASS; diferencia posicion dt .004/.002 = %.6g m; llegada recta %.3f s.\n',dp,c.t(end));
end
