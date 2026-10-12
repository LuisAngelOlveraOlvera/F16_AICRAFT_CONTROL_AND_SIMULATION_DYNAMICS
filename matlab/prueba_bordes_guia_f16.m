function prueba_bordes_guia_f16(tipo,outdir)
% Dos regresiones de la revision final; fixtures del algoritmo original.
if nargin<1,tipo='todos';end
if nargin<2,outdir=tempname;end
if any(strcmp(tipo,{'todos','referencias'}))
    r=simular_f16_academico(struct('escenario','trayectoria','duracion',.06,'tramo',.01));
    href=[3000;2840.13484443838;2759.73762074381;2981.60926324917;3112.46696459607;2960.10180229386];
    pref=[0;-.0406952189667378;-1.40126785325131;-1.43653297829179;-.202776059794886;.776828629717525];
    idx=1+round((0:.01:.05)'/.002);
    assert(max(abs(r.objetivo(idx,1)-href))<1e-8 && ...
        max(abs(r.objetivo(idx,3)-pref))<1e-10, ...
        'prueba_bordes:Referencias','La semilla no reproduce las consignas originales.');
    assert(max(abs(r.objetivo(end,:)-r.objetivo(end-1,:)))<1e-12, ...
        'prueba_bordes:UltimoTramo','Se crea un tramo extra al final.');
end
if any(strcmp(tipo,{'todos','video'}))
    assert(~exist(outdir,'dir'),'prueba_bordes:Salida','Carpeta debe ser nueva.');mkdir(outdir);
    r=simular_f16_academico(struct('escenario','nivelado','duracion',.02));
    path=fullfile(outdir,'lento.mp4');
    a=animar_f16_academico(r,struct('visible','off','video',path,'fps',20,'velocidad',.01));
    close(a.figura);v=VideoReader(path);
    % .02 segundos fisicos a .01x deben ocupar 2 segundos, mas fotograma final.
    assert(v.Duration>=2 && v.Duration<=2.1,'prueba_bordes:Velocidad', ...
        'El video lento no respeta su velocidad: %.4g s.',v.Duration);
end
fprintf('PRUEBA_BORDES_GUIA_F16 (%s): PASS.\n',tipo);
end
