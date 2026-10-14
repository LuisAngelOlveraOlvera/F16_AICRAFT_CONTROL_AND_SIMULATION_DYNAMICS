function prueba_paridad_laboratorios(file)
% Opcional: generar el archivo con python/tools/exportar_paridad_laboratorios.py.
data=load(file,'cases');
for k=1:numel(data.cases)
    example=data.cases{k};cfg=jsondecode(example.config_json);cfg.posicion_inicial=[];
    records=f16lab.run('generico',cfg);r=records{1};
    assert(isequal(size(r.X),size(example.X))&&max(abs(r.t-example.t))<1e-12);
    dx=max(abs(r.X-example.X),[],'all');du=max(abs(r.U_real-example.U),[],'all');dr=max(abs(r.referencia-example.referencia),[],'all');
    assert(dx<2e-6&&du<1e-5&&dr<2e-8,'lab:Paridad','Diferencia %s: X %g, U %g, ref %g.',cfg.escenario,dx,du,dr);
    fprintf('PARIDAD %s: PASS (X %.3g, U %.3g, ref %.3g).\n',cfg.escenario,dx,du,dr);
end
end
