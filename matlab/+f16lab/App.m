classdef App < handle
    properties
        Figure
        Tabs
        TabMap
        Fields
        Profile='pid'
        Picker
        Original
        Scenario
        Info
        Status
        RunButton
        CancelButton
        Route
        RouteAxes
        RouteEditors
        RouteSelection=1
        PositionUse
        PositionEditors
        A=[]
        B=[]
        Records={}
        RecordPicker
        StatePicker
        StateAxes
        StateContainer
        Cursors=gobjects(0)
        CompareAxes
        CompareContainer
        CompareVariable
        CompareInfo
        CompareCursor=[]
        FlightAxes
        PoseAxes
        Model=[]
        Dot=[]
        Trail=[]
        XYZ=[]
        Time
        StateTime
        TimeText
        StateTimeText
        Speed
        StateSpeed
        Camera
        Telemetry
        PlayButton
        StatePlayButton
        Index=1
        Playing=false
        LastTick
        Clock=0
        PlaybackTime=0
        Worker
        PollTimer=[]
        PlayTimer=[]
        Closed=false
        Root
    end
    methods
        function o=App(options)
            o.Root=fileparts(fileparts(mfilename('fullpath')));o.Worker=f16lab.Process(o.Root);
            o.Fields=containers.Map('KeyType','char','ValueType','any');o.TabMap=containers.Map('KeyType','char','ValueType','any');
            visible='on';if isfield(options,'visible'),visible=options.visible;end
            o.Figure=uifigure('Name','Laboratorio F-16 · MATLAB','Position',[80 80 1240 850],'Visible',visible,'CloseRequestFcn',@(s,e)delete(o));
            o.Figure.UserData=o;layout=uigridlayout(o.Figure,[4 1]);layout.RowHeight={32,40,'1x',32};
            title=uilabel(layout,'Text','LABORATORIO ACADÉMICO F-16 · MATLAB','FontSize',19,'FontWeight','bold');title.Layout.Row=1;
            bar=uigridlayout(layout,[1 5]);bar.Layout.Row=2;bar.ColumnWidth={'1x',230,125,85,95};
            [~,labels]=f16lab.profiles;o.Picker=uidropdown(bar,'Items',labels,'ValueChangedFcn',@(s,e)o.profileChanged());
            o.Original=uicheckbox(bar,'Text','Configuración original README','Value',true,'ValueChangedFcn',@(s,e)o.sync());
            uibutton(bar,'Text','Restaurar original','ButtonPushedFcn',@(s,e)o.restore());
            o.CancelButton=uibutton(bar,'Text','Cancelar','Enable','off','ButtonPushedFcn',@(s,e)o.cancel());
            o.RunButton=uibutton(bar,'Text','Simular','ButtonPushedFcn',@(s,e)o.start());
            o.Tabs=uitabgroup(layout);o.Tabs.Layout.Row=3;
            names={'Avión','Simulación','Condiciones iniciales','Control','Ruta','Turbulencia','Estados','Comparación','Vuelo y resultados'};
            for k=1:numel(names),o.TabMap(names{k})=uitab(o.Tabs,'Title',names{k});end
            o.Status=uilabel(layout,'Text','Selecciona experimento y pulsa Simular.','WordWrap','on');o.Status.Layout.Row=4;
            o.buildAircraft;o.buildForms;o.buildRoute;o.buildStates;o.buildComparison;o.buildFlight;o.loadProfile('pid');
            timers=true;if isfield(options,'timers'),timers=options.timers;end
            o.PlayTimer=timer('ExecutionMode','fixedSpacing','Period',.05,'BusyMode','drop','TimerFcn',@(s,e)o.tick());
            if timers,o.PollTimer=timer('ExecutionMode','fixedSpacing','Period',.3,'BusyMode','drop','TimerFcn',@(s,e)o.poll());start(o.PollTimer);end
        end
        function buildAircraft(o)
            g=uigridlayout(o.TabMap('Avión'),[1 2]);g.ColumnWidth={'1x',420};ax=uiaxes(g);f16lab.geometry(ax);axis(ax,'equal');view(ax,35,25);
            ax.XLim=[-9 9];ax.YLim=[-6 6];ax.ZLim=[-4 4];xlabel(ax,'x cuerpo [m]');ylabel(ax,'y cuerpo [m]');zlabel(ax,'z cuerpo [m]');title(ax,'Geometría docente · dimensiones reales no certificadas');
            a=f16lab.aircraft;hold(ax,'on');plot3(ax,[-3.7 -3.7],[-a.envergadura_m/2 a.envergadura_m/2],[.7 .7]);text(ax,-3.7,0,1.2,sprintf('Envergadura %.3f m',a.envergadura_m));hold(ax,'off');
            right=uigridlayout(g,[2 1]);right.RowHeight={'1x',75};
            labels={'Masa [kg]','Peso = m × g [N]','Gravedad [m/s²]','Superficie [m²]','Envergadura [m]','Cuerda media [m]','CG/cuerda','CG referencia/cuerda','Ix [kg·m²]','Iy [kg·m²]','Iz [kg·m²]','Ixz [kg·m²]','Momento angular motor [kg·m²/s]'};
            keys={'masa_kg','peso_N','gravedad_m_s2','superficie_m2','envergadura_m','cuerda_m','cg_fraccion','cg_referencia_fraccion','Ix_kg_m2','Iy_kg_m2','Iz_kg_m2','Ixz_kg_m2','momento_motor_kg_m2_s'};
            data=cell(numel(keys),2);for k=1:numel(keys),data(k,:)={labels{k},a.(keys{k})};end
            uitable(right,'Data',data,'ColumnName',{'Parámetro del modelo','Valor'},'ColumnWidth',{240,100});
            uilabel(right,'Text','Datos de solo lectura. Longitud y altura reales no documentadas. La silueta es ilustrativa.','WordWrap','on');
        end
        function buildForms(o)
            schemas={
             'Simulación',{'duracion','Duración [s]';'paso','Paso [s]';'VT','Velocidad inicial [m/s]';'altitud','Altitud inicial [m]';'semilla','Semilla';'tramo','Intervalo de consignas [s]'};
             'Condiciones iniciales',{'initial.alpha_deg','Δ alfa [°]';'initial.beta_deg','Δ beta [°]';'initial.phi_deg','Δ alabeo [°]';'initial.theta_deg','Δ cabeceo [°]';'initial.psi_deg','Δ rumbo [°]';'initial.p_deg_s','Δ p [°/s]';'initial.q_deg_s','Δ q [°/s]';'initial.r_deg_s','Δ r [°/s]'};
             'Control',{'pid.kp','PID: Kp';'pid.ki','PID: Ki';'pid.kq','PID: Kq';'pid.alpha_ref_deg','PID: alfa referencia [°]';'pid.alpha_initial_deg','PID: alfa inicial base [°]';'pid.throttle','PID: throttle'; ...
             'weights.q_lon','Factor Q longitudinal';'weights.r_lon','Factor R longitudinal';'weights.q_lat','Factor Q lateral';'weights.r_lat','Factor R lateral'; ...
             'reference.delta_h_m','Cambio de altitud [m]';'reference.delta_v_m_s','Cambio de velocidad [m/s]';'reference.delta_psi_deg','Cambio de rumbo [°]';'reference.time_s','Instante del cambio [s]'; ...
             'reference.h_rate_m_s','Límite vertical referencia [m/s]';'reference.v_rate_m_s2','Límite aceleración ref [m/s²]';'reference.psi_rate_deg_s','Límite rumbo ref [°/s]'; ...
             'reference.gamma_deg','Ascenso: ángulo [°]';'reference.turn_deg_s','Viraje: tasa [°/s]';'reference.trayectoria_h_m','Trayectoria: amplitud h [m]';'reference.trayectoria_rumbo_deg','Trayectoria: paso rumbo [°]'; ...
             'manual.elevador_deg','Manual: elevador [°]';'manual.aleron_deg','Manual: alerón [°]';'manual.timon_deg','Manual: timón [°]';'manual.throttle','Manual: throttle';'manual.time_s','Manual: instante [s]'};
             'Turbulencia',{'turbulence.sigma_u','Intensidad u [m/s]';'turbulence.sigma_v','Intensidad v [m/s]';'turbulence.sigma_w','Intensidad w [m/s]';'turbulence.length_u','Escala u [m]';'turbulence.length_v','Escala v [m]';'turbulence.length_w','Escala w [m]'}};
            for group=1:size(schemas,1)
                tab=o.TabMap(schemas{group,1});fields=schemas{group,2};n=ceil(size(fields,1)/2);extra=0;if group==1,extra=3;end
                g=uigridlayout(tab,[n+extra+1 4],'Scrollable','on');g.ColumnWidth={'1x',110,'1x',110};g.RowHeight=[repmat({32},1,n+extra),{'1x'}];
                if group==1
                    o.Info=uilabel(g,'WordWrap','on');o.Info.Layout.Row=1;o.Info.Layout.Column=[1 4];
                    uilabel(g,'Text','Escenario (perfil genérico)');o.Scenario=uidropdown(g,'Items',{'nivelado','lateral_abierto','longitudinal_abierto','lateral_lqr','viraje','ascenso','autopiloto','trayectoria','dryden_abierto','dryden_lqr','waypoints','pid_alfa','longitudinal_lqr','comparacion','manual'},'ValueChangedFcn',@(s,e)o.scenarioChanged());o.Scenario.Layout.Row=2;o.Scenario.Layout.Column=2;
                    savebtn=uibutton(g,'Text','Guardar configuración…','ButtonPushedFcn',@(s,e)o.saveConfig());savebtn.Layout.Row=3;savebtn.Layout.Column=1;
                    loadbtn=uibutton(g,'Text','Cargar configuración…','ButtonPushedFcn',@(s,e)o.loadConfig());loadbtn.Layout.Row=3;loadbtn.Layout.Column=3;
                end
                for k=1:size(fields,1)
                    row=ceil(k/2)+extra;col=2*mod(k-1,2)+1;l=uilabel(g,'Text',fields{k,2});l.Layout.Row=row;l.Layout.Column=col;
                    e=uieditfield(g,'numeric','Value',0);e.Layout.Row=row;e.Layout.Column=col+1;o.Fields(fields{k,1})=e;
                end
            end
        end
        function buildRoute(o)
            g=uigridlayout(o.TabMap('Ruta'),[1 2]);g.ColumnWidth={'1x','1x'};left=uigridlayout(g,[7 3]);left.RowHeight={'1x',32,32,32,32,32,32};
            o.Route=uitable(left,'Data',zeros(0,3),'ColumnName',{'Norte [m]','Este [m]','Altitud [m]'},'ColumnEditable',true(1,3), ...
             'CellSelectionCallback',@(s,e)o.selectWaypoint(e),'CellEditCallback',@(s,e)o.drawRoute());o.Route.Layout.Row=1;o.Route.Layout.Column=[1 3];
            o.RouteEditors=gobjects(3,1);for k=1:3,o.RouteEditors(k)=uieditfield(left,'numeric');o.RouteEditors(k).Layout.Row=2;o.RouteEditors(k).Layout.Column=k;end
            buttons={'Añadir','Actualizar','Eliminar'};for k=1:3,b=uibutton(left,'Text',buttons{k},'ButtonPushedFcn',@(s,e)o.editRoute(k));b.Layout.Row=3;b.Layout.Column=k;end
            up=uibutton(left,'Text','Subir punto','ButtonPushedFcn',@(s,e)o.moveRoute(-1));up.Layout.Row=4;up.Layout.Column=1;
            down=uibutton(left,'Text','Bajar punto','ButtonPushedFcn',@(s,e)o.moveRoute(1));down.Layout.Row=4;down.Layout.Column=2;
            keys={'anticipacion_m','radio_captura_m'};labels={'Anticipación [m]','Radio captura [m]'};
            for k=1:2,l=uilabel(left,'Text',labels{k});l.Layout.Row=5;l.Layout.Column=k;e=uieditfield(left,'numeric');e.Layout.Row=6;e.Layout.Column=k;o.Fields(keys{k})=e;end
            o.PositionUse=uicheckbox(left,'Text','Posición inicial propia','Value',false);o.PositionUse.Layout.Row=6;o.PositionUse.Layout.Column=3;
            o.PositionEditors=gobjects(3,1);tips={'N inicial','E inicial','Altitud inicial'};for k=1:3,o.PositionEditors(k)=uieditfield(left,'numeric','Tooltip',tips{k});o.PositionEditors(k).Layout.Row=7;o.PositionEditors(k).Layout.Column=k;end
            o.RouteAxes=uiaxes(g,'ButtonDownFcn',@(s,e)o.routeClick());xlabel(o.RouteAxes,'Este [m]');ylabel(o.RouteAxes,'Norte [m]');title(o.RouteAxes,'Ruta configurada · pulsa para editar N/E');
        end
        function buildStates(o)
            g=uigridlayout(o.TabMap('Estados'),[3 1]);g.RowHeight={32,'1x',40};
            top=uigridlayout(g,[1 2],'Padding',0);top.ColumnWidth={290,'1x'};o.StatePicker=uidropdown(top,'Items',{'Sin registro'},'ValueChangedFcn',@(s,e)o.selectRecord(s.Value));
            uilabel(top,'Text','Estados B · referencias punteadas · pulsa una curva para seleccionar tiempo');
            o.StateContainer=uipanel(g,'BorderType','none','AutoResizeChildren','off');o.StateContainer.Layout.Row=2;o.StateAxes=gobjects(9,1);
            for k=1:9,o.StateAxes(k)=uiaxes(o.StateContainer,'FontSize',10,'ButtonDownFcn',@(s,e)o.statesClick(s));end
            o.StateContainer.SizeChangedFcn=@(s,e)o.layoutStates();o.layoutStates;
            bar=uigridlayout(g,[1 4]);bar.Layout.Row=3;bar.ColumnWidth={100,80,'1x',90};
            o.StatePlayButton=uibutton(bar,'Text','Reproducir','ButtonPushedFcn',@(s,e)o.toggle());o.StateSpeed=uidropdown(bar,'Items',{'0.5','1','2','6','12'},'Value','6','ValueChangedFcn',@(s,e)o.changeSpeed(s.Value));
            o.StateTime=uislider(bar,'Limits',[0 1],'ValueChangingFcn',@(s,e)o.scrub(e.Value),'ValueChangedFcn',@(s,e)o.scrub(e.Value));o.StateTime.MajorTicks=[];o.StateTime.MinorTicks=[];o.StateTimeText=uilabel(bar,'Text','0.00 s');
        end
        function buildComparison(o)
            g=uigridlayout(o.TabMap('Comparación'),[4 1]);g.RowHeight={32,56,'1x',48};bar=uigridlayout(g,[1 4],'Padding',0);bar.ColumnWidth={140,150,150,'1x'};
            uibutton(bar,'Text','Guardar B como A','ButtonPushedFcn',@(s,e)o.saveA());uibutton(bar,'Text','Cargar A…','ButtonPushedFcn',@(s,e)o.loadRecord('A'));uibutton(bar,'Text','Cargar B…','ButtonPushedFcn',@(s,e)o.loadRecord('B'));
            o.CompareVariable=uidropdown(bar,'Items',f16lab.variables(),'Value','Alfa [°]','ValueChangedFcn',@(s,e)o.drawComparison());
            o.CompareInfo=uilabel(g,'Text','A: sin registro · B: sin registro','WordWrap','on');o.CompareInfo.Layout.Row=2;
            o.CompareContainer=uipanel(g,'BorderType','none','AutoResizeChildren','off');o.CompareContainer.Layout.Row=3;
            o.CompareAxes=uiaxes(o.CompareContainer);o.CompareContainer.SizeChangedFcn=@(s,e)o.layoutComparison();
            uilabel(g,'Text','RMS se calcula frente a la referencia de cada ensayo. Compara las condiciones antes de interpretar diferencias.','WordWrap','on');
        end
        function buildFlight(o)
            g=uigridlayout(o.TabMap('Vuelo y resultados'),[4 1]);g.RowHeight={32,'1x',40,48};
            bar=uigridlayout(g,[1 3],'Padding',0);bar.ColumnWidth={290,160,'1x'};o.RecordPicker=uidropdown(bar,'Items',{'Sin registro'},'ValueChangedFcn',@(s,e)o.selectRecord(s.Value));
            uibutton(bar,'Text','Guardar ensayo…','ButtonPushedFcn',@(s,e)o.export());o.Camera=uidropdown(bar,'Items',{'Perspectiva','Superior','Lateral'},'ValueChangedFcn',@(s,e)o.camera());
            charts=uigridlayout(g,[1 2]);charts.Layout.Row=2;o.FlightAxes=uiaxes(charts);o.PoseAxes=uiaxes(charts);
            bar=uigridlayout(g,[1 4]);bar.Layout.Row=3;bar.ColumnWidth={100,80,'1x',90};
            o.PlayButton=uibutton(bar,'Text','Reproducir','ButtonPushedFcn',@(s,e)o.toggle());o.Speed=uidropdown(bar,'Items',{'0.5','1','2','6','12'},'Value','6','ValueChangedFcn',@(s,e)o.changeSpeed(s.Value));
            o.Time=uislider(bar,'Limits',[0 1],'ValueChangingFcn',@(s,e)o.scrub(e.Value),'ValueChangedFcn',@(s,e)o.scrub(e.Value));o.Time.MajorTicks=[];o.Time.MinorTicks=[];o.TimeText=uilabel(bar,'Text','0.00 s');
            o.Telemetry=uilabel(g,'Text','Calcula o carga un ensayo para explorar sus resultados.','WordWrap','on');o.Telemetry.Layout.Row=4;
        end
        function profileChanged(o)
            [names,labels]=f16lab.profiles;o.loadProfile(names{strcmp(labels,o.Picker.Value)});
        end
        function loadProfile(o,profile)
            o.Profile=profile;[names,labels]=f16lab.profiles;o.Picker.Value=labels{strcmp(names,profile)};o.apply(f16lab.defaults(profile));
            cfg=f16lab.defaults(profile);o.Status.Text=sprintf('Seleccionado: %s · %g s · %g m/s · %g m. Pendiente de simular; registros anteriores conservados.',o.Picker.Value,cfg.duracion,cfg.VT,cfg.altitud);
        end
        function restore(o),o.loadProfile(o.Profile);end
        function apply(o,c)
            o.Original.Value=c.original;o.Scenario.Value=c.escenario;p=f16lab.flat(c);
            for k=1:size(p,1),key=p{k,1};if isKey(o.Fields,key),e=o.Fields(key);e.Value=p{k,2};end,end
            o.Route.Data=c.waypoints;o.PositionUse.Value=~isempty(c.posicion_inicial);pos=[0 0 c.altitud];if o.PositionUse.Value,pos=c.posicion_inicial;end
            for k=1:3,o.PositionEditors(k).Value=pos(k);end;o.sync;o.drawRoute;
            o.Info.Text=sprintf('%s · Valores originales por práctica. Paso <=0.02 s; VT 100–200 m/s; altitud 0–10000 m.',o.Picker.Value);
        end
        function scenarioChanged(o)
            d=f16lab.defaults('generico');if any(strcmp(o.Scenario.Value,{'lateral_abierto','lateral_lqr'})),d.initial.beta_deg=2;d.initial.phi_deg=10;
            elseif any(strcmp(o.Scenario.Value,{'longitudinal_abierto','longitudinal_lqr'})),d.initial.alpha_deg=3;end
            p=f16lab.flat(d);for k=1:size(p,1),if startsWith(p{k,1},'initial.'),e=o.Fields(p{k,1});e.Value=p{k,2};end,end;o.sync;
        end
        function sync(o)
            baseline=f16lab.defaults(o.Profile);base=f16lab.flat(baseline);
            if o.Original.Value,o.Scenario.Value=baseline.escenario;end
            available=f16lab.applicable(o.Scenario.Value);keys=o.Fields.keys;
            for k=1:numel(keys)
                editable=(~o.Original.Value&&any(strcmp(keys{k},available)))||any(strcmp(keys{k},{'duracion','paso'}));e=o.Fields(keys{k});e.Enable=onoff(editable);
                if ~editable,e.Value=base{strcmp(base(:,1),keys{k}),2};end
            end
            if o.Original.Value||~strcmp(o.Scenario.Value,'waypoints'),o.Route.Data=baseline.waypoints;o.PositionUse.Value=false;end
            o.Scenario.Enable=onoff(strcmp(o.Profile,'generico')&&~o.Original.Value);o.Route.Enable=onoff(~o.Original.Value&&strcmp(o.Scenario.Value,'waypoints'));
            o.PositionUse.Enable=o.Route.Enable;for k=1:3,o.PositionEditors(k).Enable=o.Route.Enable;o.RouteEditors(k).Enable=o.Route.Enable;end
        end
        function c=configuration(o)
            c=f16lab.defaults(o.Profile);c.original=o.Original.Value;c.escenario=o.Scenario.Value;keys=o.Fields.keys;
            for k=1:numel(keys),e=o.Fields(keys{k});c=f16lab.setfield(c,keys{k},e.Value);end
            c.waypoints=o.Route.Data;c.posicion_inicial=[];if o.PositionUse.Value,c.posicion_inicial=arrayfun(@(e)e.Value,o.PositionEditors)';end
        end
        function start(o)
            try,c=f16lab.validate(o.Profile,o.configuration);o.Worker.start(o.Profile,c);o.RunButton.Enable='off';o.CancelButton.Enable='on';o.Status.Text='Calculando en otro proceso MATLAB. Puedes cancelar; los registros anteriores permanecen.';
            catch e,o.error(e.message);end
        end
        function poll(o)
            if o.Closed,return;end
            try,[ready,records,message]=o.Worker.poll;if ~ready,return;end
                o.RunButton.Enable='on';o.CancelButton.Enable='off';
                if isempty(message),o.accept(records);else,o.error(message);end
            catch e,o.Worker.cancel;o.RunButton.Enable='on';o.CancelButton.Enable='off';o.error(e.message);end
        end
        function cancel(o),o.Worker.cancel;o.RunButton.Enable='on';o.CancelButton.Enable='off';o.Status.Text='Cálculo cancelado; registros anteriores conservados.';end
        function accept(o,records)
            assert(iscell(records)&&~isempty(records),'lab:Registro','Sin registros.');for k=1:numel(records),f16lab.validate_record(records{k});end
            oldA=o.A;oldB=o.B;oldRecords=o.Records;o.pause;o.Records=records;o.B=records{end};if numel(records)==2,o.A=records{1};end
            try,o.refresh;catch e,o.A=oldA;o.B=oldB;o.Records=oldRecords;if ~isempty(o.B),o.refresh;end;rethrow(e);end
            o.Tabs.SelectedTab=o.TabMap('Estados');o.Status.Text='Ensayo calculado. Estados muestra las curvas; Vuelo y resultados reproduce el avión.';
        end
        function refresh(o)
            labels=cellfun(@(r)r.config.escenario,o.Records,'UniformOutput',false);labels=arrayfun(@(k)sprintf('%d · %s',k,labels{k}),1:numel(labels),'UniformOutput',false);
            o.RecordPicker.Items=labels;o.StatePicker.Items=labels;id=find(cellfun(@(r)isequal(r.config,o.B.config),o.Records),1,'last');if isempty(id),id=numel(labels);end
            o.RecordPicker.Value=labels{id};o.StatePicker.Value=labels{id};o.drawFlight;o.Cursors=f16lab.states(o.StateAxes,o.B);o.layoutStates;
            maximum=max(o.B.t(end),eps);o.Time.Limits=[0 maximum];o.StateTime.Limits=[0 maximum];o.Clock=0;o.seek(o.B.t(1));o.drawComparison;
        end
        function selectRecord(o,label)
            k=find(strcmp(o.RecordPicker.Items,label),1);if isempty(k),return;end;o.pause;o.B=o.Records{k};o.refresh;
        end
        function saveA(o),if isempty(o.B),o.Status.Text='Calcula o carga un ensayo B.';return;end;o.A=o.B;o.drawComparison;o.Status.Text='A guardado en memoria con sus condiciones originales.';end
        function drawComparison(o)
            ax=o.CompareAxes;cla(ax);hold(ax,'on');legendText={};info={};records={o.A,o.B};slots={'A','B'};
            for k=1:2
                r=records{k};if isempty(r),info{end+1}=[slots{k} ': sin registro'];continue;end %#ok<AGROW>
                [~,y]=f16lab.variables(r,o.CompareVariable.Value);style='-';if k==1,style='--';end;plot(ax,r.t,y,style,'LineWidth',1.3);legendText{end+1}=[slots{k} ' · ' r.config.escenario]; %#ok<AGROW>
                original=isfield(r,'laboratorio')&&r.laboratorio.original;mode='personalizado/cargado';if original,mode='original MATLAB';end
                info{end+1}=sprintf('%s: %s · %g m/s · %g m · %g s · %s | RMS h %.3g m, VT %.3g m/s, rumbo %.3g°',slots{k},r.config.escenario,r.config.VT,r.config.altitud,r.t(end),mode,r.metricas.rms_altitud_m,r.metricas.rms_velocidad_m_s,r.metricas.rms_rumbo_deg); %#ok<AGROW>
            end
            if ~isempty(o.B)
                r=o.B;key=o.CompareVariable.Value;refs={'Altitud [m]','Velocidad [m/s]','Rumbo [°]'};col=find(strcmp(refs,key));
                if ~isempty(col),ref=r.referencia(:,col);if col==3,ref=unwrap(ref)*180/pi;end;plot(ax,r.t,ref,':');legendText{end+1}='Referencia B';
                elseif strcmp(key,'Alfa [°]')&&isfield(r,'referencia_alfa_deg'),plot(ax,r.t,r.referencia_alfa_deg,':');legendText{end+1}='Referencia alfa';end
                if strcmp(r.config.escenario,'comparacion')
                    keys={'Alfa [°]','Cabeceo [°]','Velocidad [m/s]','q [°/s]'};j=find(strcmp(keys,key));scale=[180/pi 180/pi 1 180/pi];
                    if ~isempty(j),plot(ax,r.t,r.He(:,j)*scale(j),':');legendText{end+1}='Euler';end
                    keys={'Alfa [°]','Velocidad [m/s]','q [°/s]'};j=find(strcmp(keys,key));cols=[2 1 3];base=[r.Xtrim(4) r.Xtrim(3) 0];scale=[180/pi 1 180/pi];
                    if ~isempty(j),for item={'Xl','Xp','Xk'},plot(ax,r.t,(r.(item{1})(:,cols(j))+base(j))*scale(j));end;legendText=[legendText,{'Lineal abierto','Lineal + PID','Lineal + LQR'}];end
                    if strcmp(key,'Elevador [°]'),plot(ax,r.t,r.up+r.Utrim(1),':');plot(ax,r.t,r.uk(:,1)+r.Utrim(1),'--');legendText=[legendText,{'Lineal + PID','Lineal + LQR'}];end
                end
            end
            o.CompareCursor=xline(ax,o.Clock,'Color',[.35 .4 .45]);xlabel(ax,'Tiempo [s]');ylabel(ax,o.CompareVariable.Value);grid(ax,'on');
            if ~isempty(legendText),legend(ax,legendText,'Location','best');end;hold(ax,'off');o.CompareInfo.Text=strjoin(info,newline);o.layoutComparison;
        end
        function layoutComparison(o)
            if isempty(o.CompareContainer)||~isgraphics(o.CompareContainer),return;end
            box=o.CompareContainer.InnerPosition;o.CompareAxes.Units='pixels';o.CompareAxes.PositionConstraint='outerposition';o.CompareAxes.OuterPosition=[0 0 max(box(3),300) max(box(4),200)];
        end
        function drawFlight(o)
            r=o.B;o.XYZ=[r.X(:,14),r.X(:,13),r.altitud_m]/1000;ix=unique(round(linspace(1,numel(r.t),min(2500,numel(r.t)))));
            ax=o.FlightAxes;cla(ax);hold(ax,'on');plot3(ax,o.XYZ(ix,1),o.XYZ(ix,2),o.XYZ(ix,3),'Color',[.7 .75 .8]);
            route=r.ruta_nominal_ned(:,[2 1 3])/1000;route(:,3)=-route(:,3);plot3(ax,route(ix,1),route(ix,2),route(ix,3),'--');
            if isfield(r,'navegacion'),w=r.navegacion.waypoints_ned(:,[2 1 3])/1000;w(:,3)=-w(:,3);scatter3(ax,w(:,1),w(:,2),w(:,3),30,'s');end
            o.Dot=plot3(ax,o.XYZ(1,1),o.XYZ(1,2),o.XYZ(1,3),'o');o.Trail=plot3(ax,nan,nan,nan,'LineWidth',1.5);hold(ax,'off');grid(ax,'on');
            span=max(max(o.XYZ)-min(o.XYZ),[.2 .2 .1]);mid=(max(o.XYZ)+min(o.XYZ))/2;ax.XLim=mid(1)+[-.6 .6]*span(1);ax.YLim=mid(2)+[-.6 .6]*span(2);ax.ZLim=mid(3)+[-.6 .6]*span(3);pbaspect(ax,span);
            xlabel(ax,'Este [km]');ylabel(ax,'Norte [km]');zlabel(ax,'Altitud [km]');title(ax,'Trayectoria calculada');
            ax=o.PoseAxes;cla(ax);o.Model=f16lab.geometry(ax);axis(ax,'equal');ax.XLim=[-9 9];ax.YLim=[-9 9];ax.ZLim=[-7 7];xlabel(ax,'Este [m]');ylabel(ax,'Norte [m]');zlabel(ax,'Arriba [m]');title(ax,'Actitud · geometría docente');o.camera;
        end
        function seek(o,t,fromPlayback)
            if isempty(o.B),return;end;r=o.B;k=find(r.t<=t,1,'last');if isempty(k),k=1;end;o.Index=k;o.Clock=r.t(k);o.Time.Value=o.Clock;o.StateTime.Value=o.Clock;
            if nargin<3||~fromPlayback,o.PlaybackTime=o.Clock;end
            o.TimeText.Text=sprintf('%.2f s',o.Clock);o.StateTimeText.Text=o.TimeText.Text;for j=1:numel(o.Cursors),o.Cursors(j).Value=o.Clock;end
            if isgraphics(o.CompareCursor),o.CompareCursor.Value=o.Clock;end
            T=pose_f16_enu(r.X(k,9:12),r.X(k,13:15));T(1:3,4)=0;o.Model.Matrix=T;
            o.Dot.XData=o.XYZ(k,1);o.Dot.YData=o.XYZ(k,2);o.Dot.ZData=o.XYZ(k,3);ix=unique(round(linspace(1,k,min(1500,k))));o.Trail.XData=o.XYZ(ix,1);o.Trail.YData=o.XYZ(ix,2);o.Trail.ZData=o.XYZ(ix,3);
            a=r.angulos_rad(k,:)*180/pi;u=r.U_real(k,:);o.Telemetry.Text=sprintf('t %.2f s · VT %.2f m/s · h %.2f m · alfa/beta %.2f/%.2f° · phi/theta/psi %.2f/%.2f/%.2f°\nElevador/alerón/timón %.2f/%.2f/%.2f° · throttle %.3f · Mach %.3f · an %.2f g',o.Clock,r.X(k,3),r.altitud_m(k),r.X(k,4:5)*180/pi,a,u,r.Mach(k),r.an_g(k));drawnow limitrate;
        end
        function statesClick(o,ax),if ~isempty(o.B),point=ax.CurrentPoint;o.scrub(point(1,1));end,end
        function layoutStates(o)
            if isempty(o.StateContainer)||~isgraphics(o.StateContainer),return;end
            box=o.StateContainer.InnerPosition;w=max(box(3),300)/3;h=max(box(4),300)/3;
            for k=1:numel(o.StateAxes)
                ax=o.StateAxes(k);ax.Units='pixels';ax.PositionConstraint='outerposition';
                ax.OuterPosition=[mod(k-1,3)*w,(3-ceil(k/3))*h,w,h];
            end
        end
        function scrub(o,value),o.pause;o.seek(value);end
        function pause(o),o.Playing=false;if ~isempty(o.PlayTimer)&&isvalid(o.PlayTimer),stop(o.PlayTimer);end;o.PlayButton.Text='Reproducir';o.StatePlayButton.Text='Reproducir';end
        function toggle(o)
            if isempty(o.B),return;end;if o.Playing,o.pause;return;end;if o.Clock>=o.B.t(end),o.seek(0);end
            o.Playing=true;o.PlayButton.Text='Pausar';o.StatePlayButton.Text='Pausar';o.LastTick=tic;start(o.PlayTimer);
        end
        function tick(o)
            if o.Closed||~o.Playing,return;end;dt=toc(o.LastTick);o.LastTick=tic;t=min(o.B.t(end),o.PlaybackTime+dt*str2double(o.Speed.Value));o.PlaybackTime=t;o.seek(t,true);if t>=o.B.t(end),o.pause;end
        end
        function changeSpeed(o,value),o.Speed.Value=value;o.StateSpeed.Value=value;end
        function camera(o)
            switch o.Camera.Value,case 'Superior',v=[-90 90];case 'Lateral',v=[0 0];otherwise,v=[35 25];end
            view(o.FlightAxes,v);view(o.PoseAxes,v);
        end
        function selectWaypoint(o,e)
            if isempty(e.Indices),return;end;o.RouteSelection=e.Indices(1,1);for k=1:3,o.RouteEditors(k).Value=o.Route.Data(o.RouteSelection,k);end
        end
        function routeClick(o),p=o.RouteAxes.CurrentPoint;o.RouteEditors(1).Value=p(1,2);o.RouteEditors(2).Value=p(1,1);end
        function editRoute(o,action)
            if o.Original.Value||~strcmp(o.Scenario.Value,'waypoints'),o.Status.Text='Desactiva configuración original para editar waypoints.';return;end
            d=o.Route.Data;point=arrayfun(@(e)e.Value,o.RouteEditors)';row=min(max(o.RouteSelection,1),size(d,1));
            if action==1,d=[d;point];elseif row>=1&&action==2,d(row,:)=point;elseif row>=1&&action==3,d(row,:)=[];end;o.Route.Data=d;o.drawRoute;
        end
        function drawRoute(o)
            ax=o.RouteAxes;cla(ax);hold(ax,'on');d=o.Route.Data;if ~isempty(d),h=plot(ax,d(:,2),d(:,1),'-o');h.HitTest='off';h.PickableParts='none';for k=1:size(d,1),text(ax,d(k,2),d(k,1),sprintf(' %d',k));end;end
            xlabel(ax,'Este [m]');ylabel(ax,'Norte [m]');grid(ax,'on');axis(ax,'equal');hold(ax,'off');
        end
        function moveRoute(o,delta)
            if o.Original.Value||~strcmp(o.Scenario.Value,'waypoints'),return;end
            d=o.Route.Data;from=o.RouteSelection;to=from+delta;if from<1||from>size(d,1)||to<1||to>size(d,1),return;end
            d([from to],:)=d([to from],:);o.Route.Data=d;o.RouteSelection=to;o.drawRoute;
        end
        function export(o)
            if isempty(o.B),o.Status.Text='No hay ensayo para guardar.';return;end;folder=uigetdir(o.Root,'Carpeta donde crear ensayo');if isequal(folder,0),return;end
            try,path=[tempname(folder) '_ensayo'];f16lab.export_record(o.B,path);o.Status.Text=['Guardado: ' path];catch e,o.error(e.message);end
        end
        function loadRecord(o,slot)
            [file,path]=uigetfile('*.mat',['Cargar registro ' slot]);if isequal(file,0),return;end
            try,d=load(fullfile(path,file),'r');f16lab.validate_record(d.r);
                if strcmp(slot,'B'),o.accept({d.r});else,old=o.A;o.A=d.r;try,o.drawComparison;catch e,o.A=old;o.drawComparison;rethrow(e);end;end
            catch e,o.error(e.message);end
        end
        function saveConfig(o)
            try,cfg=f16lab.validate(o.Profile,o.configuration);catch e,o.error(e.message);return;end
            [file,path]=uiputfile('*.json','Guardar configuración nueva');if isequal(file,0),return;end
            try,f16_guardar_json(fullfile(path,file),struct('contrato',1,'perfil',o.Profile,'opciones',cfg));o.Status.Text='Configuración guardada.';catch e,o.error(e.message);end
        end
        function loadConfig(o)
            [file,path]=uigetfile('*.json','Cargar configuración');if isequal(file,0),return;end
            try,d=jsondecode(fileread(fullfile(path,file)));assert(d.contrato==1,'lab:Version','Versión desconocida.');c=f16lab.validate(d.perfil,d.opciones);o.loadProfile(d.perfil);o.apply(c);o.Status.Text='Configuración cargada; pendiente de simular.';catch e,o.error(e.message);end
        end
        function error(o,message)
            o.Status.Text=['Error: ' message];
            if strcmp(o.Figure.Visible,'on'),uialert(o.Figure,message,'No se completó la operación');else,fprintf(2,'LAB ERROR: %s\n',message);end
        end
        function delete(o)
            if o.Closed,return;end;o.Closed=true;
            for t={o.PollTimer,o.PlayTimer},if ~isempty(t{1})&&isvalid(t{1}),stop(t{1});delete(t{1});end,end
            if ~isempty(o.Worker),o.Worker.cancel;end;if isgraphics(o.Figure),o.Figure.CloseRequestFcn=[];delete(o.Figure);end
        end
    end
end
function text=onoff(value)
if value,text='on';else,text='off';end
end
