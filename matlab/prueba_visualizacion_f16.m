function prueba_visualizacion_f16(outdir)
% Comprueba datos graficados y una exportacion real de video, no mocks.
assert(exist('graficar_f16_academico','file')==2, ...
    'prueba_visual:Ausente','Faltan las graficas sincronizadas.');
assert(exist('animar_f16_academico','file')==2, ...
    'prueba_visual:Ausente','Falta la animacion 3D.');
if nargin<1,outdir=tempname;end
assert(~exist(outdir,'dir'),'prueba_visual:Salida','Carpeta debe ser nueva.');
mkdir(outdir);
r=simular_f16_academico(struct('escenario','nivelado','duracion',.02));
h=graficar_f16_academico(r,'off');
figs=struct2cell(h);assert(numel(figs)==6 && all(cellfun(@isgraphics,figs)));
alt=findobj(h.estados,'Tag','altitud_real');
assert(max(abs(alt.YData(:)-r.altitud_m))<1e-12);
ref=findobj(h.seguimiento,'Tag','referencia_h');
assert(max(abs(ref.YData(:)-r.referencia(:,1)))<1e-12);
curve=findobj(h.trayectoria,'Type','line','DisplayName','Real');
assert(max(abs(curve.YData(:)-r.X(:,13)/1000))<1e-12, ...
    'prueba_visual:Escala','La trayectoria no usa kilometros explicitos.');
f=fullfile(outdir,'smoke.mp4');
a=animar_f16_academico(r,struct('visible','off','video',f,'fps',10,'velocidad',1));
assert(isgraphics(a.figura) && exist(f,'file')==2);
assert(max(abs(a.pose_final-pose_f16_enu(r.X(end,9:12),r.X(end,13:15))),[],'all')<1e-12);
v=VideoReader(f);assert(v.Duration>0 && v.Width>500 && v.Height>300);
frame=readFrame(v);assert(size(frame,3)==3 && std(double(frame(:)))>1);
exportgraphics(a.figura,fullfile(outdir,'smoke.png'),'Resolution',100);
for k=1:numel(figs),close(figs{k});end
close(a.figura);
fprintf('PRUEBA_VISUALIZACION_F16: PASS (curvas, pose final, PNG y video decodificado).\n');
end
