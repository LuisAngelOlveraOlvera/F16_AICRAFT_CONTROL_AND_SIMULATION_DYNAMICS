function c=defaults(profile)
names=f16lab.profiles;idx=find(strcmp(names,profile),1);assert(~isempty(idx),'lab:Perfil','Perfil desconocido.');
dur=[15 20 15 15 60 30 180 180 90];
scenarios={'pid_alfa','longitudinal_lqr','lateral_lqr','comparacion','autopiloto','dryden_lqr','trayectoria','waypoints','trayectoria'};
c=struct('original',idx~=9,'escenario',scenarios{idx},'duracion',dur(idx),'paso',.002, ...
 'VT',170,'altitud',3000,'semilla',11,'tramo',15,'anticipacion_m',2000,'radio_captura_m',250, ...
 'waypoints',[0 0 3000;8000 0 3100;16000 3000 3200;24000 3000 3100],'posicion_inicial',[]);
if idx==6,c.semilla=7;end
if idx==7,c.tramo=30;end
c.initial=struct('alpha_deg',0,'beta_deg',0,'phi_deg',0,'theta_deg',0,'psi_deg',0,'p_deg_s',0,'q_deg_s',0,'r_deg_s',0);
if any(idx==[2 4]),c.initial.alpha_deg=3;end
if idx==3,c.initial.beta_deg=2;c.initial.phi_deg=10;end
c.pid=struct('kp',5,'ki',1.5,'kq',.8,'alpha_ref_deg',3,'throttle',.35,'alpha_initial_deg',2);
c.weights=struct('q_lon',1,'r_lon',1,'q_lat',1,'r_lat',1);
c.manual=struct('elevador_deg',0,'aleron_deg',0,'timon_deg',0,'throttle',.35,'time_s',0);
c.reference=struct('delta_h_m',100,'delta_v_m_s',0,'delta_psi_deg',20,'time_s',5, ...
 'h_rate_m_s',10,'v_rate_m_s2',1,'psi_rate_deg_s',3,'gamma_deg',5,'turn_deg_s',3,'trayectoria_h_m',250,'trayectoria_rumbo_deg',80);
% En original MATLAB el autopiloto usa prefiltros exponenciales desde t=0.
if idx==5,c.reference.time_s=0;end
c.turbulence=struct('sigma_u',3,'sigma_v',3,'sigma_w',3,'length_u',533,'length_v',533,'length_w',533);
end
