function validate_record(r)
assert(isstruct(r)&&isscalar(r),'lab:Registro','Registro inválido.');
t=r.t;X=r.X;validateattributes(t,{'numeric'},{'column','finite','real','nonempty'});n=numel(t);
assert(size(X,1)==n&&any(size(X,2)==[15 18])&&all(isfinite(X),'all')&&isreal(X)&&all(diff(t)>0),'lab:Registro','Estados/tiempo incompatibles.');
assert(all(vecnorm(X(:,9:12),2,2)>1e-12),'lab:Registro','Cuaternión nulo.');
names={'altitud_m','Mach','empuje_N','qbar_Pa','an_g','LEF_deg'};
for k=1:numel(names),v=r.(names{k});assert(isequal(size(v),[n 1])&&all(isfinite(v))&&isreal(v),'lab:Registro','Salida incompatible.');end
names={'angulos_rad','U_real','rafaga_m_s','referencia','fuerzas_N','momentos_Nm','ruta_nominal_ned'};cols=[3 4 3 3 3 3 3];
for k=1:numel(names),v=r.(names{k});assert(isequal(size(v),[n cols(k)])&&all(isfinite(v),'all')&&isreal(v),'lab:Registro','Salida incompatible.');end
if isfield(r,'referencia_alfa_deg'),assert(isequal(size(r.referencia_alfa_deg),[n 1])&&all(isfinite(r.referencia_alfa_deg)),'lab:Registro','Referencia alfa inválida.');end
if isfield(r,'navegacion'),w=r.navegacion.waypoints_ned;assert(size(w,2)==3&&size(w,1)>=2&&all(isfinite(w),'all'),'lab:Registro','Waypoints inválidos.');end
validateattributes(r.config.VT,{'numeric'},{'scalar','finite','real'});validateattributes(r.config.altitud,{'numeric'},{'scalar','finite','real'});
assert(isstruct(r.config)&&isscalar(r.config)&&(ischar(r.config.escenario)&&isrow(r.config.escenario)||isstring(r.config.escenario)&&isscalar(r.config.escenario)),'lab:Registro','Escenario invalido.');
if isfield(r,'laboratorio'),assert(isstruct(r.laboratorio)&&isscalar(r.laboratorio)&&islogical(r.laboratorio.original)&&isscalar(r.laboratorio.original),'lab:Registro','Metadatos invalidos.');end
if strcmp(r.config.escenario,'comparacion')
    names={'He','Xl','Xp','Xk','up','uk'};cols=[4 6 6 6 1 2];
    for k=1:numel(names),v=r.(names{k});validateattributes(v,{'numeric'},{'size',[n cols(k)],'finite','real'});end
    validateattributes(r.Xtrim,{'numeric'},{'vector','numel',15,'finite','real'});
    validateattributes(r.Utrim,{'numeric'},{'vector','numel',4,'finite','real'});
end
for key={'rms_altitud_m','rms_velocidad_m_s','rms_rumbo_deg'},validateattributes(r.metricas.(key{1}),{'numeric'},{'scalar','finite','real'});end
end
