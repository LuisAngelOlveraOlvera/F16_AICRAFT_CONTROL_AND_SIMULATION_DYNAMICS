function prueba_laboratorio_bordes
% Regresiones de recuperacion, cambios de escenario y reproduccion.
root=fileparts(mfilename('fullpath'));p=f16lab.Process(root);clean=onCleanup(@()delete(p)); %#ok<NASGU>
p.JobPath=tempname(fullfile(root,'resultados'));mkdir(p.JobPath);p.Handle=1;
fid=fopen(fullfile(p.JobPath,'terminado.txt'),'w');fprintf(fid,'done');fclose(fid);
[ready,records,message]=p.poll;assert(ready&&isempty(records)&&~isempty(message)&&~p.busy,'lab:Recuperacion','Resultado ausente debe liberar el ejecutor.');
cfg=f16lab.defaults('comparacion');cfg.duracion=.02;records=f16lab.run('comparacion',cfg);bad=rmfield(records{1},'up');
failed=false;try,f16lab.validate_record(bad);catch,failed=true;end;assert(failed,'lab:Registro','Comparacion incompleta debe rechazarse antes de visualizar.');
app=lab_f16_app(struct('visible','off','timers',false));cleanApp=onCleanup(@()delete(app)); %#ok<NASGU>
app.loadProfile('generico');app.Scenario.Value='dryden_lqr';app.scenarioChanged;
e=app.Fields('turbulence.sigma_u');e.Value=0;e=app.Fields('VT');e.Value=180;
app.Scenario.Value='manual';app.scenarioChanged;c=f16lab.validate('generico',app.configuration);assert(c.turbulence.sigma_u==3&&c.VT==180);
app.Scenario.Value='pid_alfa';app.scenarioChanged;e=app.Fields('pid.kp');e.Value=2;
app.Scenario.Value='nivelado';app.scenarioChanged;c=f16lab.validate('generico',app.configuration);assert(c.pid.kp==5&&c.VT==180);
% Un registro disperso sigue avanzando a media velocidad, sin truncar dt.
r=records{1};r.t=(0:numel(r.t)-1)'*.1;app.accept({r});app.changeSpeed('0.5');app.seek(0);
for k=1:6,app.Playing=true;app.LastTick=tic;pause(.05);app.tick;end
assert(app.Index>1,'lab:Reproduccion','Reproduccion detenida entre muestras.');app.pause;
fprintf('LABORATORIO BORDES: PASS (recuperacion, registros, escenarios y tiempo continuo).\n');
end
