function f16_guardar_json(path,datos)
% F16_GUARDAR_JSON  JSON UTF-8, con proteccion de evidencia existente.
assert(~isfile(path) && ~isfolder(path),'f16_json:Existente', ...
    'Archivo existente: no se sobrescribe.');
[f,msg]=fopen(path,'w','n','UTF-8');
assert(f~=-1,'f16_json:Apertura','No se puede abrir la salida "%s": %s',path,msg);
c=onCleanup(@() fclose(f)); %#ok<NASGU>
fprintf(f,'%s',jsonencode(datos,'PrettyPrint',true));
end
