function prueba_laboratorio_visual
app=lab_f16_app(struct('visible','off','timers',false));clean=onCleanup(@()delete(app)); %#ok<NASGU>
assert(numel(app.Tabs.Children)==9);app.loadProfile('pid');assert(app.configuration.duracion==15);
e=app.Fields('pid.kp');e.Value=2;app.restore;assert(app.configuration.pid.kp==5);
cfg=f16lab.defaults('pid');cfg.duracion=.02;records=f16lab.run('pid',cfg);app.accept(records);app.saveA;app.seek(.02);
assert(app.Index==11&&app.Time.Value==.02&&app.StateTime.Value==.02);
assert(all(arrayfun(@(x)x.Value==.02,app.Cursors)));
bad=records{1};bad.t=[0;.02];failed=false;try,app.accept({bad});catch,failed=true;end;assert(failed&&isequal(app.B.X,records{1}.X));
folder=tempname(fullfile(fileparts(mfilename('fullpath')),'resultados'));f16lab.export_record(app.B,folder);
data=load(fullfile(folder,'registro.mat'),'r');assert(isequal(data.r.X,app.B.X));
failed=false;try,f16lab.export_record(app.B,folder);catch,failed=true;end;assert(failed);
out=fullfile(folder,'estados.png');app.Figure.Visible='on';app.Tabs.SelectedTab=app.TabMap('Estados');drawnow;pause(3);drawnow;
positions=vertcat(app.StateAxes.Position);disp(positions);
assert(size(unique(positions(:,1:2),'rows'),1)==9,'lab:Layout','Gráficas de estados superpuestas.');
outer=vertcat(app.StateAxes.OuterPosition);assert(all(outer(:,3)>200)&&all(outer(:,4)>100),'lab:Layout','Paneles de estados demasiado pequeños.');
for i=1:9,for j=i+1:9
    overlap=min(outer(i,1:2)+outer(i,3:4),outer(j,1:2)+outer(j,3:4))-max(outer(i,1:2),outer(j,1:2));
    assert(~all(overlap>1),'lab:Layout','Paneles superpuestos.');
end,end
exportapp(app.Figure,out);
fprintf('LABORATORIO VISUAL: PASS (tabs, defaults, estados/cursores, A/B, carga y guardado).\nCAPTURA %s\n',out);
end
