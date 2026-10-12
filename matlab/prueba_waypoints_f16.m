function prueba_waypoints_f16
% Invertir Este/Norte o quitar realimentacion de posicion rompe estas pruebas.
assert(exist('guiar_waypoints_f16','file')==2,'f16:Ausente','Falta guia espacial.');
w=[0 0 3000;8000 0 3100;16000 3000 3200];
[u,g]=guiar_waypoints_f16([1000 200 -3000],w,1,170,2000,250);
assert(u(3)<0 && abs(u(3))<pi/4); % Volver al eje Norte desde Este positivo.
assert(u(1)>3000 && u(1)<3100 && u(2)==170);
assert(g.tramo==1 && ~g.finalizado);
[u,g]=guiar_waypoints_f16([0 1000 -3000],[0 0 3000;0 8000 3000],1,170,2000,250);
assert(abs(u(3)-pi/2)<1e-12 && g.error_transversal_m<1e-10);
[~,g]=guiar_waypoints_f16([16000 3000 -3200],w,2,170,2000,250);
assert(g.finalizado && g.distancia_final_m<1e-10);
cfg=struct('escenario','waypoints','duracion',40,'paso',.004, ...
    'waypoints_ned',[0 0 -3000;12000 0 -3000], ...
    'posicion_inicial_ned',[0 200 -3000]);
r=simular_f16_academico(cfg);
assert(size(r.X,2)==18 && all(isfinite(r.X),'all'));
assert(abs(r.X(end,14))<50 && abs(r.X(1,14)-200)<1e-12);
assert(r.navegacion.error_transversal_m(end)<50);
assert(max(abs(r.norma_cuaternion-1))<1e-8);
assert(max(abs(diff(r.referencia(:,3))/.004))<=3*pi/180+1e-8);
assert(max(abs(diff(r.referencia(:,1))/.004))<=10+1e-7);
fprintf('PRUEBA_WAYPOINTS_F16: PASS (ejes, captura espacial, limites y 18 estados).\n');
end
