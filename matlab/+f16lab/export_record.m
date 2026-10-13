function export_record(r,path)
f16lab.validate_record(r);assert(~isfolder(path)&&~isfile(path),'lab:Salida','No se sobrescriben resultados.');
[ok,msg]=mkdir(path);assert(ok,'lab:Salida','%s',msg);save(fullfile(path,'registro.mat'),'r','-v7.3');
f16_guardar_json(fullfile(path,'metricas.json'),r.metricas);
if isfield(r,'laboratorio'),meta=r.laboratorio;else,meta=struct('config',r.config,'implementacion','MATLAB','procedencia','Registro cargado sin metadatos del laboratorio');end
f16_guardar_json(fullfile(path,'configuracion.json'),meta);
values=[r.t,r.X,r.U_real];names={'t_s','P3_pct','alfaf_deg','VT_m_s','alpha_rad','beta_rad','p_rad_s','q_rad_s','r_rad_s','q0','q1','q2','q3','N_m','E_m','D_m'};
if size(r.X,2)==18,names=[names,{'de_real_deg','da_real_deg','dr_real_deg'}];end
names=[names,{'de_deg','da_deg','dr_deg','throttle'}];writetable(array2table(values,'VariableNames',names),fullfile(path,'registro.csv'));
end
