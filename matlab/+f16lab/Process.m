classdef Process < handle
    properties
        Handle=[]
        JobPath=''
        Root=''
    end
    methods
        function o=Process(root),o.Root=root;end
        function value=busy(o),value=~isempty(o.Handle);end
        function start(o,profile,cfg)
            assert(~o.busy,'lab:Ocupado','Hay un cálculo en curso.');
            assert(ispc,'lab:Sistema','El ejecutor independiente está implementado para Windows.');
            base=fullfile(o.Root,'resultados');if ~isfolder(base),mkdir(base);end
            o.JobPath=tempname(base);mkdir(o.JobPath);save(fullfile(o.JobPath,'config.mat'),'profile','cfg');
            prefs=fullfile(base,'lab_prefs');tmp=fullfile(base,'lab_tmp');if ~isfolder(prefs),mkdir(prefs);end;if ~isfolder(tmp),mkdir(tmp);end
            psi=System.Diagnostics.ProcessStartInfo;psi.FileName=fullfile(matlabroot,'bin','matlab.exe');
            expr=sprintf('addpath(''%s'');f16lab.worker(''%s'')',strrep(o.Root,'''',''''''),strrep(o.JobPath,'''',''''''));
            log=fullfile(o.JobPath,'matlab.log');psi.Arguments=sprintf('-batch "%s" -logfile "%s"',expr,log);
            psi.UseShellExecute=false;psi.CreateNoWindow=true;psi.WindowStyle=System.Diagnostics.ProcessWindowStyle.Hidden;
            env=psi.EnvironmentVariables;
            for name={'MATLAB_PREFDIR','TEMP','TMP'},env.Remove(name{1});end
            env.Add('MATLAB_PREFDIR',prefs);env.Add('TEMP',tmp);env.Add('TMP',tmp);
            o.Handle=System.Diagnostics.Process; o.Handle.StartInfo=psi;
            try,assert(o.Handle.Start(),'lab:Proceso','No se inició MATLAB.');catch e,o.cancel;rethrow(e);end
        end
        function [ready,records,message]=poll(o)
            ready=false;records={};message='';if ~o.busy,return;end
            if isfile(fullfile(o.JobPath,'terminado.txt'))
                ready=true;
                cleanup=onCleanup(@()o.cancel()); %#ok<NASGU>
                try
                    if isfile(fullfile(o.JobPath,'error.mat')),data=load(fullfile(o.JobPath,'error.mat'),'error_text');message=data.error_text;
                    else,data=load(fullfile(o.JobPath,'resultado.mat'),'records');records=data.records;end
                catch e
                    records={};message=['No se pudo leer el resultado del trabajo: ' e.message];
                end
            elseif o.Handle.HasExited
                ready=true;message='El proceso terminó sin resultados. Revisa el registro del trabajo.';
                file=fullfile(o.JobPath,'matlab.log');if isfile(file),message=fileread(file);end;o.cancel;
            end
        end
        function cancel(o)
            if ~isempty(o.Handle)
                try,if ~o.Handle.HasExited,o.Handle.Kill();o.Handle.WaitForExit(3000);end;o.Handle.Dispose();catch,end
                o.Handle=[];
            end
        end
        function delete(o),o.cancel;end
    end
end
