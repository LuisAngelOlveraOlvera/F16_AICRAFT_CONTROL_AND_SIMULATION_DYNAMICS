function prueba_laboratorio_pestanas
app=lab_f16_app(struct('visible','off','timers',false));clean=onCleanup(@()delete(app)); %#ok<NASGU>
[names,labels]=f16lab.profiles;
for k=1:numel(names)
    app.Picker.Value=labels{k};app.profileChanged;c=f16lab.validate(names{k},app.configuration);
    d=f16lab.defaults(names{k});assert(isequal(c,d),'lab:Perfil','Seleccion no restaura defaults.');
end
cfg=f16lab.defaults('comparacion');cfg.duracion=.02;records=f16lab.run('comparacion',cfg);app.accept(records);
for label=f16lab.variables,app.CompareVariable.Value=label{1};app.drawComparison;end
app.saveA;app.CompareVariable.Value='Alfa [°]';app.drawComparison;app.seek(.01);
folder=tempname(fullfile(app.Root,'resultados'));mkdir(folder);app.Figure.Visible='on';
tabs={'Avión','Simulación','Control','Ruta','Comparación','Vuelo y resultados'};
for k=1:numel(tabs)
    app.Tabs.SelectedTab=app.TabMap(tabs{k});drawnow;pause(1);drawnow;
    if strcmp(tabs{k},'Comparación')
        p=app.CompareAxes.OuterPosition;assert(p(3)>800&&p(4)>300,'lab:Layout','Grafica de comparacion no ocupa su panel.');
        buttons=findall(app.TabMap(tabs{k}),'Type','uibutton');assert(all(arrayfun(@(b)b.Position(4)>=25,buttons)),'lab:Layout','Botones de comparacion recortados.');
    end
    if strcmp(tabs{k},'Vuelo y resultados')
        p=app.FlightAxes.OuterPosition;q=app.PoseAxes.OuterPosition;
        overlap=min(p(1:2)+p(3:4),q(1:2)+q(3:4))-max(p(1:2),q(1:2));
        assert(~all(overlap>1)&&p(3)>200&&q(3)>200,'lab:Layout','Vistas 3D superpuestas o pequeñas.');
    end
    exportapp(app.Figure,fullfile(folder,sprintf('pestana_%d.png',k)));
end
fprintf('LABORATORIO PESTANAS: PASS (9 perfiles, 28 variables de comparacion y vistas).\nCAPTURAS %s\n',folder);
end
