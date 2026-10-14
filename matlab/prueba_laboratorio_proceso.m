function prueba_laboratorio_proceso
app=lab_f16_app(struct('visible','off','timers',false));clean=onCleanup(@()delete(app)); %#ok<NASGU>
e=app.Fields('duracion');e.Value=.02;app.start;assert(app.Worker.busy);
clock=tic;while app.Worker.busy&&toc(clock)<120,pause(.2);app.poll;drawnow;end
assert(~app.Worker.busy&&~isempty(app.B),'lab:Proceso','El proceso no entregó registro.');assert(numel(app.B.t)==11);
previous=app.B;app.loadProfile('waypoints');app.start;assert(app.Worker.busy);app.cancel;
assert(~app.Worker.busy&&isequal(previous.X,app.B.X));
fprintf('LABORATORIO PROCESO: PASS (MATLAB independiente, resultados y cancelar).\n');
end
