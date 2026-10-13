function prueba_laboratorio_originales
% Ejecutar en proceso de prueba: los scripts originales usan clear/close all.
for profile={'pid','lqr_longitudinal','lqr_lateral','comparacion','autopiloto','dryden_original','trayectoria_original'}
    name=profile{1};cfg=f16lab.defaults(name);computed=f16lab.run(name,cfg);
    map=struct('pid','pruebarkf','lqr_longitudinal','prueba_lqr','lqr_lateral','prueba_lqr_lat', ...
      'comparacion','prueba_comparacion','autopiloto','prueba_autopiloto','dryden_original','prueba_dryden','trayectoria_original','prueba_trayectoria');
    snapshot=capture(map.(name));r=computed{end};
    if isfield(snapshot,'X')&&~strcmp(name,'comparacion')
        errorX=max(abs(r.X-snapshot.X'),[],'all');assert(errorX<2e-7,'lab:Original','%s X error %.3g',name,errorX);
    else,errorX=NaN;end
    if strcmp(name,'pid'),assert(max(abs(r.U_real(:,1)-snapshot.de_hist))<1e-7);end
    if strcmp(name,'lqr_longitudinal'),assert(max(abs(r.U_real(:,1)-snapshot.de_hist))<1e-7);end
    if strcmp(name,'comparacion')
        for key={'Hq','He','Xl','Xp','Xk','up','uk'}
            actual=r.(key{1});expected=snapshot.(key{1})';assert(max(abs(actual-expected),[],'all')<2e-7,'lab:Comparacion','Diferencia %s.',key{1});
        end
    end
    if strcmp(name,'dryden_original')
        for k=1:2,assert(max(abs(computed{k}.H-snapshot.R{k}'),[],'all')<2e-7,'lab:Dryden','Ruido/dinámica originales diferentes.');end
    end
    if strcmp(name,'trayectoria_original')
        assert(max(abs(r.referencia(:,[1 3])-snapshot.ref_hist'),[],'all')<1e-8,'lab:Referencia','Referencia original desalineada.');
        short=cfg;short.duracion=60;z=f16lab.run(name,short);assert(max(abs(z{1}.X-r.X(1:numel(z{1}.t),:)),[],'all')<2e-7,'lab:Semilla','Acortar horizonte alteró objetivos originales.');
    end
    fprintf('ORIGINAL %s: PASS (X %.3g)\n',name,errorX);
end
fprintf('LABORATORIO ORIGINALES: PASS.\n');
end
function d=capture(name)
set(groot,'defaultFigureVisible','off');
evalc(name);
d=struct;
vars={'X','time','t','de_hist','dth_hist','u_hist','Hq','He','Xl','Xp','Xk','up','uk','R','ref_hist','W'};
for j=1:numel(vars),if exist(vars{j},'var'),d.(vars{j})=eval(vars{j});end,end
close all;
end
