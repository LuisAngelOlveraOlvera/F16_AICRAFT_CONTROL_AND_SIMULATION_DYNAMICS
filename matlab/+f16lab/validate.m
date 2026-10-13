function c=validate(profile,c)
b=f16lab.defaults(profile);assert(isstruct(c)&&isscalar(c)&&isequal(sort(fieldnames(c)),sort(fieldnames(b))),'lab:Config','Configuración incompleta/desconocida.');
assert(islogical(c.original)&&isscalar(c.original),'lab:Original','Modo original inválido.');
for group={'initial','pid','weights','manual','reference','turbulence'}
    key=group{1};assert(isstruct(c.(key))&&isscalar(c.(key))&&isequal(sort(fieldnames(c.(key))),sort(fieldnames(b.(key)))),'lab:Config','Grupo %s incompleto/desconocido.',key);
end
p=f16lab.flat(c);bp=f16lab.flat(b);allowed=f16lab.applicable(c.escenario);
for k=1:size(p,1)
    key=p{k,1};v=p{k,2};
    if any(strcmp(key,{'original','escenario','waypoints','posicion_inicial'})),continue;end
    validateattributes(v,{'numeric'},{'scalar','real','finite'},'laboratorio',key);
end
assert(c.duracion>0&&c.paso>0&&c.paso<=.02&&c.VT>=100&&c.VT<=200&&c.altitud>=0&&c.altitud<=10000,'lab:Limites','Tiempo, VT o altitud fuera de límites.');
n=round(c.duracion/c.paso);assert(n>=1&&n<=500000&&abs(n*c.paso-c.duracion)<1e-9,'lab:Tiempo','Duración múltiplo del paso y máximo 500000 pasos.');
validateattributes(c.semilla,{'numeric'},{'scalar','integer','>=',0,'<=',2^32-1});
assert(min([c.tramo c.anticipacion_m c.radio_captura_m])>0,'lab:Config','Tramo, anticipación y radio deben ser positivos.');
scenarios={'nivelado','lateral_abierto','longitudinal_abierto','lateral_lqr','viraje','ascenso','autopiloto','trayectoria','dryden_abierto','dryden_lqr','waypoints','pid_alfa','longitudinal_lqr','comparacion','manual'};
assert(any(strcmp(c.escenario,scenarios)),'lab:Escenario','Escenario desconocido.');
if ~strcmp(profile,'generico'),assert(strcmp(c.escenario,b.escenario),'lab:Escenario','Usa perfil genérico para elegir escenario.');end
for k=1:size(p,1)
    key=p{k,1};orig=bp{strcmp(bp(:,1),key),2};
    if c.original,editable=any(strcmp(key,{'original','duracion','paso'}));
    else,editable=any(strcmp(key,allowed));end
    assert(editable||isequal(p{k,2},orig),'lab:NoAplicable','%s no es editable en este modo/escenario.',key);
end
assert(all(cell2mat(struct2cell(c.weights))>0),'lab:Pesos','Q/R deben ser positivos.');
assert(min([c.pid.kp c.pid.ki c.pid.kq])>=0&&c.pid.throttle>=0&&c.pid.throttle<=1,'lab:PID','PID/throttle inválidos.');
u=[c.manual.elevador_deg c.manual.aleron_deg c.manual.timon_deg c.manual.throttle];
assert(all(u>=[-25 -21.5 -30 0])&&all(u<=[25 21.5 30 1])&&c.manual.time_s>=0,'lab:Manual','Mandos fuera de límites.');
z=c.turbulence;assert(min([z.sigma_u z.sigma_v z.sigma_w])>=0&&min([z.length_u z.length_v z.length_w])>0,'lab:Dryden','Sigma >=0 y escalas >0.');
z=c.reference;assert(min([z.h_rate_m_s z.v_rate_m_s2 z.psi_rate_deg_s])>0&&min([z.time_s z.trayectoria_h_m z.trayectoria_rumbo_deg])>=0,'lab:Referencia','Referencia inválida.');
if c.original&&strcmp(profile,'dryden_original'),assert(c.paso==.002&&c.duracion<=30,'lab:Dryden','Dryden original: paso .002 y duración <=30 s.');end
if c.original&&strcmp(profile,'trayectoria_original'),assert(c.duracion<=180,'lab:Trayectoria','Trayectoria original hasta 180 s.');end
if strcmp(c.escenario,'waypoints')
    w=c.waypoints;validateattributes(w,{'numeric'},{'2d','ncols',3,'finite','real'});
    assert(size(w,1)>=2&&all(vecnorm(diff(w(:,1:2)),2,2)>1),'lab:Ruta','Mínimo dos waypoints; tramos horizontales >1 m.');
    pos=w(1,:);if ~isempty(c.posicion_inicial),pos=c.posicion_inicial;end
    validateattributes(pos,{'numeric'},{'numel',3,'finite','real'});assert(abs(pos(3)-c.altitud)<1e-9,'lab:Altitud','Altitud inicial debe coincidir con trim.');
end
end
