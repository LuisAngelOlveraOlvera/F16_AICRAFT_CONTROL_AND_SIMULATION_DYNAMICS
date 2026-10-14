function records=run(profile,cfg)
if nargin<2,cfg=f16lab.defaults(profile);end
cfg=f16lab.validate(profile,cfg);
if cfg.original
    if strcmp(profile,'waypoints')
        records={simular_f16_academico(struct('escenario','waypoints','duracion',cfg.duracion,'paso',cfg.paso))};
    elseif strcmp(profile,'generico')
        records={simular_f16_academico(struct('escenario',cfg.escenario,'duracion',cfg.duracion,'paso',cfg.paso))};
    else,records=f16lab.demos(profile,cfg);end
else
    switch cfg.escenario
        case 'pid_alfa',records=f16lab.demos('pid',cfg);
        case 'longitudinal_lqr',records=f16lab.demos('lqr_longitudinal',cfg);
        case 'comparacion',records=f16lab.demos('comparacion',cfg);
        otherwise
            if strcmp(profile,'dryden_original')
                c=cfg;c.escenario='dryden_abierto';a=f16lab.solve(c);c.escenario='dryden_lqr';b=f16lab.solve(c);records={a,b};
            else,records={f16lab.solve(cfg)};end
    end
end
hashes=f16lab.hashes;
for k=1:numel(records)
    records{k}.laboratorio=struct('perfil',profile,'original',cfg.original,'opciones',cfg,'implementacion','MATLAB','contrato',1, ...
       'matlab_version',version,'fuentes_sha256',hashes,'procedencia','Scripts MATLAB nativos en original; contrato común en personalizado');
    f16lab.validate_record(records{k});
end
end
