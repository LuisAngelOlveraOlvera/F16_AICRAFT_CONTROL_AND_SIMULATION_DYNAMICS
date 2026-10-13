function fields=applicable(s)
fields={'original','escenario','duracion','paso','VT','altitud'};d=f16lab.defaults('generico');
if any(strcmp(s,{'trayectoria','dryden_abierto','dryden_lqr'})),fields{end+1}='semilla';end
if strcmp(s,'trayectoria'),fields{end+1}='tramo';end
if strcmp(s,'waypoints'),fields=[fields,{'waypoints','posicion_inicial','anticipacion_m','radio_captura_m'}];end
keys=fieldnames(d.initial)';if strcmp(s,'comparacion'),keys={'alpha_deg'};end
fields=[fields,strcat('initial.',keys)];
if strcmp(s,'pid_alfa'),fields=[fields,strcat('pid.',fieldnames(d.pid)')];end
if strcmp(s,'comparacion'),fields=[fields,{'pid.kp','pid.ki','pid.kq'}];end
if any(strcmp(s,{'longitudinal_lqr','comparacion'})),fields=[fields,{'weights.q_lon','weights.r_lon'}];
elseif any(strcmp(s,{'lateral_lqr','autopiloto','trayectoria','waypoints','dryden_lqr'})),fields=[fields,strcat('weights.',fieldnames(d.weights)')];end
if startsWith(s,'dryden'),fields=[fields,strcat('turbulence.',fieldnames(d.turbulence)')];end
if strcmp(s,'manual'),fields=[fields,strcat('manual.',fieldnames(d.manual)')];end
if strcmp(s,'autopiloto'),fields=[fields,strcat('reference.',{'delta_h_m','delta_v_m_s','delta_psi_deg','time_s'})];end
if any(strcmp(s,{'autopiloto','trayectoria','waypoints'})),fields=[fields,strcat('reference.',{'h_rate_m_s','v_rate_m_s2','psi_rate_deg_s'})];end
if strcmp(s,'trayectoria'),fields=[fields,{'reference.trayectoria_h_m','reference.trayectoria_rumbo_deg'}];end
if strcmp(s,'ascenso'),fields{end+1}='reference.gamma_deg';end
if strcmp(s,'viraje'),fields{end+1}='reference.turn_deg_s';end
end
