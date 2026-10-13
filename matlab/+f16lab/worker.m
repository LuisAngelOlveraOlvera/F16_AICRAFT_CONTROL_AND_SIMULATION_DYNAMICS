function worker(path)
% Proceso exclusivo del laboratorio. Nunca ejecuta comandos del usuario.
try
    job=load(fullfile(path,'config.mat'),'profile','cfg');records=f16lab.run(job.profile,job.cfg);
    save(fullfile(path,'resultado.mat'),'records','-v7.3');
catch e
    error_text=getReport(e,'extended','hyperlinks','off');save(fullfile(path,'error.mat'),'error_text');
end
f=fopen(fullfile(path,'terminado.txt'),'w');assert(f~=-1);fprintf(f,'done');fclose(f);
end
