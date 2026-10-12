function prueba_ruta_salida_f16
% Regresion: pwd de MATLAB puede diferir de java user.dir tras cd.
anterior=pwd;
rutaAnterior=path;
c=onCleanup(@() restaurar(anterior,rutaAnterior)); %#ok<NASGU>
addpath(fileparts(mfilename('fullpath')));
carpeta=tempname;mkdir(carpeta);cd(carpeta);
mkdir('salida');
[ok,a]=fileattrib('salida');assert(ok);
assert(strcmp(a.Name,fullfile(pwd,'salida')));
f16_guardar_json(fullfile(a.Name,'prueba.json'),struct('valor',1));
assert(isfile(fullfile(pwd,'salida','prueba.json')));
codigo=fileread(fullfile(fileparts(mfilename('fullpath')),'ejecutar_guia_f16.m'));
assert(contains(codigo,'fileattrib(outdir)'));
assert(~contains(codigo,'java.io.File(outdir)'));
fprintf('PRUEBA_RUTA_SALIDA_F16: PASS (cd y ruta absoluta MATLAB).\n');
end

function restaurar(carpeta,ruta)
cd(carpeta);
path(ruta);
end
