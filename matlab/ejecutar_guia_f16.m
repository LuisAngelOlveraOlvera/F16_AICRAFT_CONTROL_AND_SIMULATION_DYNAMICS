function resumen = ejecutar_guia_f16(outdir,op)
% EJECUTAR_GUIA_F16  Ejecuta la guia y exporta resultados sin sobrescribir.
% resumen=ejecutar_guia_f16; % carpeta con fecha y hora, verificaciones incluidas
% resumen=ejecutar_guia_f16('carpeta_nueva',struct('validar',false,'legado',false));
if nargin<1 || isempty(outdir),outdir=['resultados_f16_' datestr(now,'yyyymmdd_HHMMSS')];end
if nargin<2,op=struct;end
cfg=struct('validar',true,'legado',true,'graficas',true,'video',true);
names=fieldnames(op);
for k=1:numel(names)
    assert(isfield(cfg,names{k}),'guia_f16:Config','Opcion desconocida.');
    cfg.(names{k})=op.(names{k});
    validateattributes(cfg.(names{k}),{'logical'},{'scalar'});
end
assert(~exist(outdir,'dir') && ~exist(outdir,'file'), ...
    'guia_f16:SalidaExistente','Use una carpeta nueva; no se sobrescriben resultados.');
[ok,msg]=mkdir(outdir);
assert(ok,'guia_f16:CrearSalida','No se puede crear la salida: %s',msg);
[ok,atributos]=fileattrib(outdir);
assert(ok,'guia_f16:RutaSalida','No se puede resolver la carpeta de salida.');
outdir=atributos.Name; % Ruta absoluta resuelta respecto a pwd de MATLAB, no Java.
root=fileparts(mfilename('fullpath'));
fuentes=inventario(root);write_json(fullfile(outdir,'fuentes_codigo.json'),fuentes);
diary(fullfile(outdir,'ejecucion.log'));clean=onCleanup(@() diary('off')); %#ok<NASGU>
visAnterior=get(groot,'defaultFigureVisible');
visCleanup=onCleanup(@() set(groot,'defaultFigureVisible',visAnterior)); %#ok<NASGU>
fprintf('MATLAB %s | Salida %s\n',version,outdir);
if cfg.validar
    verificar;
    comparacion=comparar_f16_estandarizado;
    sensibilidad=sensibilidad_jacobiano_6dof(comparacion);
    save(fullfile(outdir,'comparacion_guia.mat'),'comparacion','sensibilidad');
end
if cfg.legado
    demos={'prueba_lqr_lat','prueba_autopiloto','prueba_dryden','prueba_trayectoria'};
    for k=1:numel(demos)
        fprintf('Demostracion original: %s\n',demos{k});
        d=demo_original(demos{k});
        path=fullfile(outdir,['original_' demos{k}]);mkdir(path);
        figuras=d.figuras;d=rmfield(d,'figuras');
        save(fullfile(path,'registro.mat'),'d');
        f=fopen(fullfile(path,'consola.txt'),'w');assert(f~=-1);fwrite(f,d.consola,'char');fclose(f);
        for j=1:numel(figuras)
            exportgraphics(figuras(j),fullfile(path,sprintf('figura_%02d.png',j)),'Resolution',140);
            close(figuras(j));
        end
    end
end
casos={'nivelado','lateral_abierto','longitudinal_abierto','lateral_lqr', ...
    'viraje','ascenso','autopiloto','trayectoria','dryden_abierto','dryden_lqr'};
duraciones=[20 30 20 15 60 20 40 180 30 30];
resumen=struct('matlab',version,'opciones',cfg,'salida',outdir);
for k=1:numel(casos)
    fprintf('Ensayo %d/%d: %s (%g s)\n',k,numel(casos),casos{k},duraciones(k));
    opciones=struct('escenario',casos{k},'duracion',duraciones(k));
    if startsWith(casos{k},'dryden'),opciones.semilla=7;end
    % Trayectoria: mismo horizonte, tramos y semilla de prueba_trayectoria.
    if strcmp(casos{k},'trayectoria'),opciones.tramo=30;end
    r=simular_f16_academico(opciones);
    path=fullfile(outdir,casos{k});mkdir(path);
    save(fullfile(path,'registro.mat'),'r');
    tabla=tabla_vuelo(r);writetable(tabla,fullfile(path,'telemetria.csv'));
    st=struct('escenario',casos{k},'duracion_s',duraciones(k),'muestras',numel(r.t), ...
        'estados',size(r.X,2),'metricas',r.metricas,'trim',r.trim, ...
        'polos_laterales_real',real(r.control.polos_lat), ...
        'polos_laterales_imag',imag(r.control.polos_lat));
    resumen.ensayos(k)=st; %#ok<AGROW>
    write_json(fullfile(path,'metricas.json'),st);
    if cfg.graficas
        figs=graficar_f16_academico(r,'off');fn=fieldnames(figs);
        for j=1:numel(fn)
            exportgraphics(figs.(fn{j}),fullfile(path,[fn{j} '.png']),'Resolution',140);
            close(figs.(fn{j}));
        end
    end
    if cfg.video && any(strcmp(casos{k},{'autopiloto','trayectoria'}))
        fprintf('Exportando animacion 3D: %s\n',casos{k});
        a=animar_f16_academico(r,struct('visible','off','video',fullfile(path,'vuelo_3d.mp4'), ...
            'velocidad',12));
        exportgraphics(a.figura,fullfile(path,'vista_3d.png'),'Resolution',140);
        close(a.figura);
    end
    fprintf('RMS: h %.4g m, V %.4g m/s, rumbo %.4g deg | norma %.3g\n', ...
        r.metricas.rms_altitud_m,r.metricas.rms_velocidad_m_s, ...
        r.metricas.rms_rumbo_deg,r.metricas.max_error_norma_quat);
end
write_json(fullfile(outdir,'resumen.json'),resumen);
save(fullfile(outdir,'resumen.mat'),'resumen');
fprintf('GUIA EJECUTADA: %d escenarios; resultados en %s\n',numel(casos),outdir);
end

function verificar
[nfail,~]=prueba_regresion_lewis;assert(nfail==0);
prueba_trim_refinado;prueba_6dof_estandarizado;
% run_tests usa clear; este workspace aislado no destruye el ejecutor.
run_tests;assert(nfail==0);
prueba_simulador_academico;
end

function d=demo_original(nombre)
% Los scripts usan clear/close all. Se aislan del registro del ejecutor.
set(groot,'defaultFigureVisible','off');
texto=evalc(nombre);
d=struct('consola',texto,'figuras',findall(groot,'Type','figure'),'datos',struct);
vars={'X','time','t','H','R','ref_hist','Xtrim','Utrim','info','A15','B15','Alon','Alat','Klon','Klat'};
for k=1:numel(vars)
    if exist(vars{k},'var'),d.datos.(vars{k})=eval(vars{k});end
end
% La preferencia se restaura por el onCleanup del ejecutor.
end

function tabla=tabla_vuelo(r)
tabla=table(r.t,'VariableNames',{'t_s'});
names={'P3_pct','alfaf_deg','VT_m_s','alfa_rad','beta_rad','p_rad_s','q_rad_s','r_rad_s', ...
    'q0','q1','q2','q3','N_m','E_m','D_m','de_real_deg','da_real_deg','dr_real_deg'};
for k=1:size(r.X,2),tabla.(names{k})=r.X(:,k);end
tabla.h_m=r.altitud_m;
for k=1:3
    an={'phi_rad','theta_rad','psi_rad'};tabla.(an{k})=r.angulos_rad(:,k);
    refs={'h_ref_m','V_ref_m_s','psi_ref_rad'};tabla.(refs{k})=r.referencia(:,k);
end
tabla.Mach=r.Mach;tabla.qbar_Pa=r.qbar_Pa;tabla.LEF_deg=r.LEF_deg;
tabla.empuje_N=r.empuje_N;tabla.an_g=r.an_g;
names={'de','da','dr','dth'};
for k=1:4
    tabla.([names{k} '_comando'])=r.U_comando(:,k);
    tabla.([names{k} '_acotado'])=r.U_acotado(:,k);
    tabla.([names{k} '_real'])=r.U_real(:,k);
end
names={'N','E','D'};
for k=1:3,tabla.(['acc_' names{k} '_m_s2'])=r.aceleracion_inercial_m_s2(:,k);end
end

function out=inventario(root)
files=[dir(fullfile(root,'*.m'));dir(fullfile(root,'*.xlsx'));dir(fullfile(root,'*.pdf'))];
out=struct('archivo',{},'sha256',{});
for k=1:numel(files)
    f=fopen(fullfile(root,files(k).name),'rb');assert(f~=-1);bytes=fread(f,Inf,'*uint8');fclose(f);
    md=java.security.MessageDigest.getInstance('SHA-256');md.update(bytes);
    hash=lower(reshape(dec2hex(typecast(md.digest(),'uint8'),2).',1,[]));
    out(k)=struct('archivo',files(k).name,'sha256',hash);
end
end
function write_json(path,x)
f16_guardar_json(path,x);
end
