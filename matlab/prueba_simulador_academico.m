function prueba_simulador_academico
% Pruebas fisicas del ejecutor, registro y pose visual; sin mocks.
assert(exist('simular_f16_academico','file')==2, ...
    'prueba_simulador:Ausente','Falta el ejecutor simular_f16_academico.');
assert(exist('pose_f16_enu','file')==2, ...
    'prueba_simulador:Ausente','Falta la transformacion visual ENU.');
% Una inversion de z o intercambio incorrecto de ejes rompe estas pruebas.
T=pose_f16_enu([1 0 0 0],[100 200 -300]);
assert(max(abs(T(1:3,4)-[200;100;300]))<1e-12);
assert(max(abs(T(1:3,1)-[0;1;0]))<1e-12);
T=pose_f16_enu([cos(pi/4) 0 0 sin(pi/4)],[0 0 0]);
assert(max(abs(T(1:3,1)-[1;0;0]))<1e-12);
T=pose_f16_enu([cos(pi/12) sin(pi/12) 0 0],[0 0 0]);
assert(T(3,2)<0 && abs(det(T(1:3,1:3))-1)<1e-12);

cfg=struct('escenario','nivelado','duracion',2,'paso',.002);
r=simular_f16_academico(cfg);
assert(size(r.X,1)==1001 && size(r.X,2)==15);
assert(max(abs(r.X(:,3)-170))<1e-5);
assert(max(abs(r.altitud_m-3000))<1e-5);
assert(max(abs(r.aceleracion_inercial_m_s2),[],'all')<1e-5);
assert(max(abs(r.especifica_cuerpo_m_s2(:,3)+9.80665*cos(r.angulos_rad(:,2))))<1e-5);
assert(max(abs(r.norma_cuaternion-1))<1e-8);
assert(max(abs(r.U_real-r.U_acotado),[],'all')<1e-12);
assert(max(abs(r.derivadas(:,1:8)),[],'all')<1e-5);

v=simular_f16_academico(struct('escenario','viraje','duracion',2));
psi=unwrap(v.angulos_rad(:,3));
assert(abs((psi(end)-psi(1))/2-3*pi/180)<1e-5);
assert(max(abs(v.altitud_m-3000))<1e-4);
a=simular_f16_academico(struct('escenario','ascenso','duracion',2));
assert(abs(-a.derivadas(1,15)-170*sin(5*pi/180))<1e-8);
% El trim es local: la densidad cambia al ascender con mandos congelados.
assert(abs(a.altitud_m(end)-a.altitud_m(1)-2*170*sin(5*pi/180))<.1);

% Quitar realimentacion o intercambiar p/r destruye la recuperacion lateral.
l=simular_f16_academico(struct('escenario','lateral_lqr','duracion',8));
assert(abs(l.X(end,5))<.1*pi/180);
assert(abs(l.angulos_rad(end,1))<.5*pi/180);
assert(all(abs(l.U_real(:,1:3))<=[25 21.5 30]+1e-10,'all'));
assert(all(l.U_real(:,4)>=0 & l.U_real(:,4)<=1));

% Un uso accidental de rng global o referencias no repetibles rompe esto.
before=rng;
d1=simular_f16_academico(struct('escenario','dryden_lqr','duracion',1,'semilla',7));
d2=simular_f16_academico(struct('escenario','dryden_lqr','duracion',1,'semilla',7));
after=rng;
assert(isequal(before,after));
assert(isequal(d1.X,d2.X) && isequal(d1.rafaga_m_s,d2.rafaga_m_s));
assert(any(d1.rafaga_m_s(:)~=0));

p=simular_f16_academico(struct('escenario','autopiloto','duracion',2));
assert(size(p.X,2)==18 && all(isfinite(p.X),'all'));
assert(max(abs(diff(p.U_real(:,1:3))/.002),[],'all')<=120+1e-7);
assert(size(p.referencia,1)==size(p.X,1));
assert(all(isfinite(p.LEF_deg)) && all(p.LEF_deg>=0 & p.LEF_deg<=25));
assert(abs(p.t(end)-2)<1e-12);

% Integracion independiente con paso mitad: discrimina ruido numerico.
l2=simular_f16_academico(struct('escenario','lateral_lqr','duracion',8,'paso',.001));
assert(max(abs(l.X(end,3:12)-l2.X(end,3:12)))<2e-3);
fprintf('PRUEBA_SIMULADOR_ACADEMICO: PASS (fisica, control, semillas, ejes y paso).\n');
end
