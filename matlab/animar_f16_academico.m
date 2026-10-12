function a = animar_f16_academico(r,op)
% ANIMAR_F16_ACADEMICO  Escena ENU + actitud a escala + telemetria.
% animar_f16_academico(r) reproduce en MATLAB.
% animar_f16_academico(r,struct('video','vuelo.mp4','velocidad',6)).
if nargin<2,op=struct;end
cfg=struct('visible','on','video','','fps',20,'velocidad',6,'tiempo_real',false);
fields=fieldnames(op);
for k=1:numel(fields)
    assert(isfield(cfg,fields{k}),'animar_f16:Config','Opcion desconocida.');
    cfg.(fields{k})=op.(fields{k});
end
validateattributes(cfg.fps,{'numeric'},{'scalar','finite','positive','<=',60});
validateattributes(cfg.velocidad,{'numeric'},{'scalar','finite','positive'});
if ~isempty(cfg.video)
    assert(~exist(cfg.video,'file'),'animar_f16:Salida','Video existente: no se sobrescribe.');
end
f=figure('Name',['F-16 3D | ' r.config.escenario],'Color','w', ...
    'Visible',cfg.visible,'Position',[70 80 1200 700]);
ax=axes(f,'Position',[.06 .26 .48 .64]);hold(ax,'on');grid(ax,'on');
% Escena global uniformemente en km; pose fisica y geometria local en m.
xyz=[r.X(:,14) r.X(:,13) r.altitud_m]/1000;nom=r.ruta_nominal_ned/1000;
ix=unique(round(linspace(1,size(xyz,1),min(5000,size(xyz,1)))));
plot3(ax,xyz(ix,1),xyz(ix,2),xyz(ix,3),'Color',[.8 .86 .92],'LineWidth',1.2);
plot3(ax,nom(ix,2),nom(ix,1),-nom(ix,3),'k--');
trail=animatedline(ax,'Color',[.06 .32 .66],'LineWidth',2);
dot=plot3(ax,xyz(1,1),xyz(1,2),xyz(1,3),'o','MarkerFaceColor',[.9 .3 .1],'Color',[.9 .3 .1]);
xlabel(ax,'Este [km]');ylabel(ax,'Norte [km]');zlabel(ax,'Altitud [km]');
axis(ax,'equal');view(ax,35,25);
limits=[min(xyz,[],1);max(xyz,[],1)];span=max(limits(2,:)-limits(1,:),[.2 .2 .1]);
mid=mean(limits,1);xlim(ax,mid(1)+[-.6 .6]*span(1));ylim(ax,mid(2)+[-.6 .6]*span(2));zlim(ax,mid(3)+[-.6 .6]*span(3));
title(ax,{'Trayectoria real / ruta nominal orientativa','Coordenadas ENU, kilometros'});
if isfield(r,'navegacion')
    wp=r.navegacion.waypoints_ned/1000;
    plot3(ax,wp(:,2),wp(:,1),-wp(:,3),'ks','MarkerFaceColor','y');
    title(ax,{'Vuelo real / ruta 3D por waypoints','Coordenadas ENU, kilometros'});
end

ax2=axes(f,'Position',[.60 .30 .34 .58]);hold(ax2,'on');grid(ax2,'on');
axis(ax2,'equal');axis(ax2,[-9 9 -9 9 -7 7]);view(ax2,38,24);
xlabel(ax2,'Este [m]');ylabel(ax2,'Norte [m]');zlabel(ax2,'Arriba [m]');
title(ax2,'Actitud del avion (geometria docente, escala en metros)');
body=hgtransform('Parent',ax2);
geometry(body);
plot3(ax2,[0 0],[0 7],[0 0],'Color',[.7 .7 .7]);
text(ax2,0,7,0,' N','Color',[.4 .4 .4]);
hud=annotation(f,'textbox',[.04 .03 .92 .19],'EdgeColor',[.85 .85 .85], ...
    'BackgroundColor',[.96 .97 .99],'FontName','Consolas','FontSize',11,'Interpreter','none');
writer=[];cleanup=[];
if ~isempty(cfg.video)
    writer=VideoWriter(cfg.video,'MPEG-4');writer.FrameRate=cfg.fps;writer.Quality=85;
    open(writer);cleanup=onCleanup(@() close(writer));
end
% Tiempo uniforme de video, incluye muestra final aun en recorridos cortos.
sample_t=unique([0:cfg.velocidad/cfg.fps:r.t(end),r.t(end)]);
% Mantener indices repetidos: a velocidad baja cada muestra ocupa varios
% fotogramas. Eliminarlos alteraria la duracion fisica de la reproduccion.
indices=min(numel(r.t),1+round(sample_t/r.config.paso));
for j=1:numel(indices)
    if ~isgraphics(f),break;end
    k=indices(j);T=pose_f16_enu(r.X(k,9:12),r.X(k,13:15));
    local=T;local(1:3,4)=0;body.Matrix=local;
    addpoints(trail,xyz(k,1),xyz(k,2),xyz(k,3));
    set(dot,'XData',xyz(k,1),'YData',xyz(k,2),'ZData',xyz(k,3));
    d=r.angulos_rad(k,:)*180/pi;u=r.U_real(k,:);
    hud.String=sprintf(['t=%6.2f s   VT=%6.2f m/s   h=%7.2f m   Mach=%.3f   an=%5.2f g\n' ...
        'phi=%6.2f  theta=%6.2f  psi=%7.2f deg     alfa=%5.2f  beta=%5.2f deg\n' ...
        'p/q/r = %+6.2f / %+6.2f / %+6.2f deg/s   de/da/dr = %+6.2f / %+6.2f / %+6.2f deg\n' ...
        'throttle=%.3f  P3=%5.2f%%  LEF=%5.2f deg   empuje=%6.2f kN   ref h/psi=%.1f m / %.1f deg'], ...
        r.t(k),r.X(k,3),r.altitud_m(k),r.Mach(k),r.an_g(k),d(1),d(2),d(3), ...
        r.X(k,4)*180/pi,r.X(k,5)*180/pi,r.X(k,6:8)*180/pi, ...
        u(1),u(2),u(3),u(4),r.X(k,1),r.LEF_deg(k),r.empuje_N(k)/1000, ...
        r.referencia(k,1),r.referencia(k,3)*180/pi);
    drawnow;
    if ~isempty(writer),writeVideo(writer,getframe(f));end
    if cfg.tiempo_real,pause(1/cfg.fps);end
end
if ~isempty(cleanup),clear cleanup;end
a=struct('figura',f,'pose_final',T,'video',cfg.video,'fotogramas',j);
end

function geometry(parent)
% Fuselaje x~15 m, envergadura~9 m. Cuerpo x adelante,y derecha,z abajo.
x=[7.4 4 1 -4 -7.4];rad=[.03 .55 .85 .7 .12];
n=14;v=zeros(numel(x)*n,3);
for i=1:numel(x)
    a=(0:n-1)'*2*pi/n;ids=(i-1)*n+(1:n);
    v(ids,:)=[x(i)*ones(n,1),rad(i)*cos(a),rad(i)*sin(a)];
end
faces=zeros((numel(x)-1)*n,4);k=0;
for i=1:numel(x)-1
    for j=1:n
        jj=mod(j,n)+1;k=k+1;
        faces(k,:)=[(i-1)*n+j,(i-1)*n+jj,i*n+jj,i*n+j];
    end
end
patch('Parent',parent,'Vertices',v,'Faces',faces,'FaceColor',[.63 .69 .75],'EdgeColor','none');
% alas, estabilizadores y deriva; silueta esquematica, no CAD homologado.
polys={ [2 .6 .2;-3.2 4.57 .25;-4.2 4.57 .25;-3 .6 .2], ...
    [2 -.6 .2;-3.2 -4.57 .25;-4.2 -4.57 .25;-3 -.6 .2], ...
    [-4.5 .5 0;-6.5 2.7 .1;-7.3 2.3 .1;-6.8 .5 0], ...
    [-4.5 -.5 0;-6.5 -2.7 .1;-7.3 -2.3 .1;-6.8 -.5 0], ...
    [-4 0 -.5;-5.4 0 -3.3;-6.9 0 -3;-7.2 0 -.3]};
for k=1:numel(polys)
    patch('Parent',parent,'Vertices',polys{k},'Faces',[1 2 3 4], ...
        'FaceColor',[.35 .44 .55],'EdgeColor',[.22 .28 .36],'FaceAlpha',1);
end
patch('Parent',parent,'Vertices',[4 -.35 -.5;4 .35 -.5;1 .45 -.9;1 -.45 -.9], ...
    'Faces',[1 2 3 4],'FaceColor',[.1 .48 .62],'EdgeColor','none');
end
