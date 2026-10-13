function prueba_laboratorio_f16
% Pruebas adicionales del laboratorio, sin alterar la suite original.
names={'pid','lqr_longitudinal','lqr_lateral','comparacion','autopiloto','dryden_original','trayectoria_original','waypoints','generico'};
dur=[15 20 15 15 60 30 180 180 90];
for k=1:numel(names)
    cfg=f16lab.defaults(names{k});assert(cfg.duracion==dur(k)&&cfg.VT==170&&cfg.altitud==3000&&cfg.paso==.002);
end
a=f16lab.aircraft;assert(a.masa_kg==9295.44&&abs(a.peso_N-9295.44*9.80665)<1e-8&&a.Ix_kg_m2==12874.8);
cfg=f16lab.defaults('pid');cfg.duracion=.02;r=f16lab.run('pid',cfg);assert(size(r{1}.X,1)==11&&r{1}.X(1,1)==0);
cfg.original=false;cfg.pid.kp=2;s=f16lab.run('pid',cfg);assert(r{1}.U_real(1,1)~=s{1}.U_real(1,1));
cfg=f16lab.defaults('lqr_lateral');cfg.original=false;cfg.duracion=.02;cfg.initial.phi_deg=5;
r=f16lab.run('lqr_lateral',cfg);assert(abs(r{1}.angulos_rad(1,1)*180/pi-5)<1e-8);
cfg=f16lab.defaults('generico');cfg.escenario='dryden_lqr';cfg.duracion=.02;
cfg.turbulence.sigma_u=0;cfg.turbulence.sigma_v=0;cfg.turbulence.sigma_w=0;
r=f16lab.run('generico',cfg);assert(all(r{1}.rafaga_m_s==0,'all'));
cfg=f16lab.defaults('generico');cfg.escenario='manual';cfg.duracion=.02;cfg.manual.elevador_deg=2;cfg.manual.throttle=.4;
r=f16lab.run('generico',cfg);assert(isequal(r{1}.U_real(1,:),[2 0 0 .4]));
cfg=f16lab.defaults('waypoints');cfg.original=false;cfg.duracion=.02;cfg.waypoints=[0 0 3000;100 0 3000];
r=f16lab.run('waypoints',cfg);assert(numel(r{1}.t)==1);f16lab.validate_record(r{1});
cfg=f16lab.defaults('pid');cfg.original=false;cfg.weights.q_lat=2;
failed=false;try,f16lab.validate('pid',cfg);catch,failed=true;end;assert(failed);
cfg=f16lab.defaults('generico');cfg.duracion=.021;
failed=false;try,f16lab.validate('generico',cfg);catch,failed=true;end;assert(failed);
cfg=f16lab.defaults('pid');cfg.initial=rmfield(cfg.initial,'theta_deg');failed=false;try,f16lab.validate('pid',cfg);catch,failed=true;end;assert(failed);
cfg=f16lab.defaults('lqr_longitudinal');cfg.original=false;cfg.duracion=.02;cfg.initial.alpha_deg=20;
r=f16lab.run('lqr_longitudinal',cfg);assert(any(r{1}.saturacion_comando,'all'));
fprintf('LABORATORIO NUMERICO: PASS (perfiles, datos, opciones, limites y registros).\n');
end
