function prueba_exportacion_json_f16
% Detecta perdida de acentos/rutas y sobrescritura de evidencia existente.
assert(exist('f16_guardar_json','file')==2,'prueba_json:Ausente','Falta exportador UTF-8 seguro.');
path=[tempname '.json'];datos=struct('texto','versión','valor',1.25);
f16_guardar_json(path,datos);
f=fopen(path,'rb');bytes=fread(f,Inf,'*uint8');fclose(f);
parsed=jsondecode(native2unicode(bytes.','UTF-8'));
assert(isequal(parsed,datos));
try
    f16_guardar_json(path,struct('valor',0));
    error('prueba_json:NoProtegido','Sobrescritura permitida.');
catch err
    assert(strcmp(err.identifier,'f16_json:Existente'));
end
f=fopen(path,'rb');actual=fread(f,Inf,'*uint8');fclose(f);assert(isequal(bytes,actual));
fprintf('PRUEBA_EXPORTACION_JSON_F16: PASS (UTF-8 y preservacion).\n');
end
