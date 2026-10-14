function evidencia = validar_fuentes_aerodinamicas(outdir)
% VALIDAR_FUENTES_AERODINAMICAS  Contraste de fits con hojas disponibles.
% Solo lectura de Tablas 2.xlsx. No recalibra ningun coeficiente.
% Las hojas son fuentes candidatas: falta procedencia/configuracion NASA.
% Columnas verificadas en la hoja: Cmq y dCm A/B; demas hojas B/C.
% Supuesto declarado: alfa en grados y coeficiente de la funcion homonima.
if nargin<1,outdir='';end
if ~isempty(outdir) && (exist(outdir,'file') || exist(outdir,'dir'))
    error('fuentes_aero:Exists','La carpeta de salida debe ser nueva.');
end
root=fileparts(mfilename('fullpath')); path=fullfile(root,'Tablas 2.xlsx');
if ~isfile(path),path=fullfile(root,'datos_locales','Tablas 2.xlsx');end
assert(isfile(path),'fuentes_aero:DatosLocales', ...
    'Auditoria opcional: falta datos_locales/Tablas 2.xlsx. Ver ../docs/DATOS_Y_FUENTES.md.');
names={'Cmq','dCm','Cnr','dCnrlef','Cnp','dCnplef','Clp','dClplef', ...
    'Cyr','dCyrlef','Cyp','dCyplef'};
r=validar_lewis(struct('mostrar',false)); at=r.trim.alfa_deg;
evidencia=struct('fuente',path,'estado_fidelidad','NO_VERIFICADA', ...
    'supuestos','Cmq/dCm A/B, otras B/C como alfa[deg]/coeficiente; nombres de hojas corresponden a funciones', ...
    'configuracion_LEF','No documentada inequívocamente en las hojas; no intercambiar total e incremento', ...
    'alfa_trim_deg',at);
for k=1:numel(names)
    c=readcell(path,'Sheet',names{k},'Range','A1:C120','UseExcel',false);
    cols=[2 3]; if any(strcmp(names{k},{'Cmq','dCm'})),cols=[1 2];end
    rows=[];xx=[];yy=[];
    for j=1:size(c,1)
        if isnumeric(c{j,cols(1)}) && isscalar(c{j,cols(1)}) && isfinite(c{j,cols(1)}) && ...
                isnumeric(c{j,cols(2)}) && isscalar(c{j,cols(2)}) && isfinite(c{j,cols(2)})
            rows(end+1,1)=j;xx(end+1,1)=c{j,cols(1)};yy(end+1,1)=c{j,cols(2)}; %#ok<AGROW>
        end
    end
    assert(numel(xx)>=3 && numel(unique(xx))==numel(xx),'fuentes_aero:Axes','Eje incompleto/duplicado en %s.',names{k});
    [xx,idx]=sort(xx);yy=yy(idx);rows=rows(idx);
    fun=str2func(names{k}); pred=arrayfun(fun,xx); err=pred-yy;
    local=fun(at); source=interp1(xx,yy,at,'linear');
    h=1e-4; slope_fit=(fun(at+h)-fun(at-h))/(2*h);
    slope_source=(interp1(xx,yy,at+h,'linear')-interp1(xx,yy,at-h,'linear'))/(2*h);
    percentage=nan(size(yy)); mask=yy~=0;percentage(mask)=100*abs(err(mask))./abs(yy(mask));
    item=struct('hoja',names{k},'filas',rows,'columnas',cols,'alfa_deg',xx,'dato',yy, ...
        'ajuste',pred,'error',err,'error_porcentaje',percentage, ...
        'rmse',sqrt(mean(err.^2)),'mae',mean(abs(err)), ...
        'max_error_absoluto',max(abs(err)),'valor_trim_ajuste',local, ...
        'valor_trim_hoja_interpolado',source,'diferencia_trim',local-source, ...
        'pendiente_trim_ajuste_por_grado',slope_fit, ...
        'pendiente_trim_hoja_por_grado',slope_source, ...
        'signo_distinto_trim',sign(local)~=sign(source), ...
        'certificacion','No certifica fidelidad NASA sin procedencia, unidades y configuracion verificadas');
    evidencia.hojas(k)=item; %#ok<AGROW>
    fprintf('%-10s: n=%d RMSE=%.5g; trim fit=%+.6g hoja=%+.6g delta=%+.6g\n', ...
        names{k},numel(xx),item.rmse,local,source,item.diferencia_trim);
end
evidencia.pendientes={'No hay hojas Cl/Clr completas para certificar las pendientes de alabeo.'; ...
    'Cm y otras superficies multidimensionales carecen de definicion inequívoca de todos los ejes/mandos.'; ...
    'Cmqlef no se equipara a dCmqlef: total e incremento pueden ser magnitudes distintas.'; ...
    'Sin contrato de error del ajuste no se clasifica toda aproximacion como error de implementacion.'};
if ~isempty(outdir)
    mkdir(outdir); save(fullfile(outdir,'contraste_fuentes.mat'),'evidencia');
    f=fopen(fullfile(outdir,'contraste_fuentes.json'),'w');assert(f~=-1);
    cleanup=onCleanup(@() fclose(f)); %#ok<NASGU>
    fwrite(f,jsonencode(evidencia,'PrettyPrint',true),'char');
end
end
