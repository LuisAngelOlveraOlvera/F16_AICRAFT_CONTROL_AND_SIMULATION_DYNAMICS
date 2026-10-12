function resultado = validar_lewis(opciones)
% VALIDAR_LEWIS  Contraste independiente con las cuatro imagenes de Lewis.
%   resultado = validar_lewis;
%   resultado = validar_lewis(struct('altitud_m',3000));
%
% No edita archivos, no guarda resultados, no borra el workspace ni abre
% figuras. Reutiliza trim_crucero, funciones_euler y jacobiano_fd del repo.
% Solo necesita MATLAB base. Los resultados quedan en la estructura devuelta.
%
% Ejemplos 3.7-3/4: VT=502 ft/s, Xcg=0.3*cbar. La altitud NO aparece
% en las imagenes: por defecto se SUPONE 0 m. No se confirma equivalencia
% fisica hasta verificar las condiciones y la variante aerodinamica del libro.
% 'condiciones_confirmadas'=true es una declaracion del usuario, no algo que
% este archivo pueda deducir. 'COINCIDE' significa dentro de tolerancias.
%
% Opciones (struct escalar; todas opcionales):
%   altitud_m                   : 0 por defecto (supuesto, no dato del libro).
%   condiciones_confirmadas     : false por defecto.
%   tol_abs_A / tol_rel_A        : 1e-3 / 0.05, por elemento de A o B.
%   tol_abs_polo / tol_rel_polo  : 1e-3 / 0.05, por polo [1/s].
%   mostrar                     : true, imprime matrices, errores y polos.
%   punto_pull_up / punto_viraje_45g : [] o struct con X15, U4, theta,
%       y opcionalmente condiciones_confirmadas (false por defecto).
%       X15 y U4 usan el orden/unidades de funciones.m; NO ejes cuerpo.
%
% Para figuras 3.7-2/3 se conserva la referencia y, si se suministra el punto
% de operacion real, se comparan A9 (y B9 del pull-up). No se deduce ese punto
% de las matrices impresas. C/D del pull-up quedan pendientes porque falta
% la definicion completa de la salida an (unidad, signo y punto de medida).
%
% Las A4 se obtienen del jacobiano en Euler con potencia P3, estado del
% filtro LEF y demas estados fuera del bloque CONGELADOS. No son polos del
% modelo completo ni una reduccion por equilibrio de esos estados. El LEF
% conserva su dependencia directa de alfa/qbar. Se usa la aerodinamica
% actual del repositorio; no se ajusta el modelo para forzar coincidencia.

if nargin == 0, opciones = struct; end
cfg = configurar(opciones);
ref = referencias_lewis();
theta = parametros_referencia();
[Xtrim,Utrim,info] = trim_crucero(cfg.VT_mps,cfg.altitud_m,theta);
if ~info.converge || ~isfinite(info.residuo)
    error('validar_lewis:Trim','No converge el trim: residuo %.6g.',info.residuo);
end
if any(abs(Utrim(1:3)) > [25;21.5;30])
    error('validar_lewis:TrimLimites','El trim requiere superficies fuera de limites.');
end
Xe = a_euler(Xtrim);
Ae = jacobiano_fd(@(x) funciones_euler(0,x,Utrim,theta),Xe);
% Transformacion de similitud: VT[m/s] -> VT[ft/s]. Resto en rad y rad/s.
S4 = diag([1/0.3048,1,1,1]);
Alon = S4*Ae([3 4 10 7],[3 4 10 7])/S4;
Alat = Ae([5 9 6 8],[5 9 6 8]);
resultado.config = cfg;
resultado.theta = theta;
resultado.Xtrim = Xtrim;
resultado.Utrim = Utrim;
resultado.trim = info;
resultado.A_euler = Ae;
resultado.referencias = ref;
resultado.longitudinal = comparar_caso(Alon,ref.longitudinal,cfg);
resultado.lateral = comparar_caso(Alat,ref.lateral,cfg);
resultado.pull_up = comparar_maniobra(cfg.punto_pull_up,ref.pull_up,cfg);
resultado.viraje_45g = comparar_maniobra(cfg.punto_viraje_45g,ref.viraje_45g,cfg);
resultado.advertencias = {
    'Altitud no documentada en las imagenes: 0 m es solo el supuesto inicial.';
    'La variante aerodinamica, parametros y configuracion LEF deben verificarse contra Lewis.';
    'A4 congela motor/filtro LEF; no representa los modos de todos los estados.';
    'Las tolerancias son criterios de contraste configurables, no tolerancias publicadas por Lewis.'};
if cfg.mostrar, imprimir(resultado); end
end

function cfg = configurar(opciones)
if ~isstruct(opciones) || ~isscalar(opciones)
    error('validar_lewis:Opciones','opciones debe ser un struct escalar.');
end
cfg = struct('altitud_m',0,'condiciones_confirmadas',false, ...
    'tol_abs_A',1e-3,'tol_rel_A',0.05,'tol_abs_polo',1e-3, ...
    'tol_rel_polo',0.05,'mostrar',true,'punto_pull_up',[], ...
    'punto_viraje_45g',[]);
names = fieldnames(opciones);
for k=1:numel(names)
    if ~isfield(cfg,names{k})
        error('validar_lewis:OpcionDesconocida','Opcion desconocida: %s.',names{k});
    end
    cfg.(names{k}) = opciones.(names{k});
end
for name={'altitud_m','tol_abs_A','tol_rel_A','tol_abs_polo','tol_rel_polo'}
    v=cfg.(name{1});
    if ~isnumeric(v) || ~isreal(v) || ~isscalar(v) || ~isfinite(v) || v<0
        error('validar_lewis:Valor','%s debe ser un numero finito no negativo.',name{1});
    end
end
for name={'condiciones_confirmadas','mostrar'}
    cfg.(name{1}) = booleano(cfg.(name{1}),name{1});
end
for name={'punto_pull_up','punto_viraje_45g'}
    punto=cfg.(name{1});
    if ~isempty(punto), validar_punto(punto); end
end
cfg.VT_ft_s = 502;
cfg.VT_mps = cfg.VT_ft_s*0.3048;
cfg.Xcg = 0.30;
end

function v = booleano(v,nombre)
if ~(islogical(v) || isnumeric(v)) || ~isreal(v) || ~isscalar(v) || ...
        ~isfinite(v) || ~(v==0 || v==1)
    error('validar_lewis:Booleano','%s debe ser true o false.',nombre);
end
v=logical(v);
end

function validar_punto(p)
if ~isstruct(p) || ~isscalar(p) || ~all(isfield(p,{'X15','U4','theta'}))
    error('validar_lewis:Punto','El punto requiere X15, U4 y theta.');
end
for name={'X15','U4','theta'}
    v=p.(name{1});
    if ~isnumeric(v) || ~isreal(v) || ~isvector(v) || any(~isfinite(v(:)))
        error('validar_lewis:Punto','%s debe ser un vector real finito.',name{1});
    end
end
if numel(p.X15)~=15 || numel(p.U4)~=4 || numel(p.theta)<17
    error('validar_lewis:Punto','Se requieren 15 estados, 4 controles y >=17 parametros.');
end
x=p.X15(:); u=p.U4(:);
if x(3)<=0 || abs(norm(x(9:12))-1)>1e-6 || ...
        abs(x(5))>=pi/2 || any(abs(u(1:3))>[25;21.5;30]) || u(4)<0 || u(4)>1
    error('validar_lewis:Punto','VT, beta, cuaternion o controles fuera de dominio.');
end
if p.theta(1)<=0 || p.theta(2)<=0 || p.theta(3)<=0
    error('validar_lewis:Punto','Masa, gravedad y superficie deben ser positivas.');
end
if isfield(p,'condiciones_confirmadas')
    booleano(p.condiciones_confirmadas,'punto.condiciones_confirmadas');
end
end

function theta = parametros_referencia()
% Mismos parametros SI que run_tests; no se modifica parametros.m.
g=9.80665; m=9295.44; S=27.87; b=9.144; cbar=3.45;
Xcgr=0.35; Xcg=0.30;
Ix=12874.8; Iy=75673.6; Iz=85552.1; Ixz=1331.4;
gamma=Ix*Iz-Ixz^2;
c1=((Iy-Iz)*Iz-Ixz^2)/gamma; c2=((Ix-Iy+Iz)*Ixz)/gamma;
c3=Iz/gamma; c4=Ixz/gamma; c5=(Iz-Ix)/Iy; c6=Ixz/Iy;
c7=1/Iy; c8=(Ix*(Ix-Iy)+Ixz^2)/gamma; c9=Ix/gamma;
theta=[m;g;S;cbar;b;Xcgr;Xcg;c1;c2;c3;c4;c5;c6;c7;c8;c9;216.9];
end

function Xe = a_euler(x)
q=x(9:12); q=q/norm(q);
phi=atan2(2*(q(1)*q(2)+q(3)*q(4)),q(1)^2-q(2)^2-q(3)^2+q(4)^2);
pitch=asin(max(-1,min(1,2*(q(1)*q(3)-q(2)*q(4)))));
psi=atan2(2*(q(2)*q(3)+q(1)*q(4)),q(1)^2+q(2)^2-q(3)^2-q(4)^2);
if abs(cos(pitch))<1e-6
    error('validar_lewis:Euler','Punto demasiado cerca de la singularidad Euler.');
end
Xe=[x(1:8);phi;pitch;psi;x(13:15)];
end

function ref = referencias_lewis()
% Transcripcion de las imagenes proporcionadas por el usuario; redondeadas.
ref.longitudinal.estados={'VT_ft_s','alfa','theta','q'};
ref.longitudinal.A=[-2.0244e-2 7.8761 -3.2169e1 -6.5020e-1; ...
    -2.5373e-4 -1.0189 0 9.0484e-1; 0 0 0 1; ...
    7.9472e-11 -2.4982 0 -1.3861];
ref.longitudinal.polos=[-1.2039+1.4922i;-1.2039-1.4922i; ...
    -0.0087297+0.073966i;-0.0087297-0.073966i];
ref.longitudinal.modos={'Periodo corto';'Periodo corto';'Fugoide';'Fugoide'};
ref.lateral.estados={'beta','phi','p','r'};
ref.lateral.A=[-3.2200e-1 6.4032e-2 3.8904e-2 -9.9156e-1; ...
    0 0 1 3.9385e-2; -3.0919e1 0 -3.6730 6.7425e-1; ...
    9.4724 0 -2.6358e-2 -4.9849e-1];
ref.lateral.polos=[-0.4399+3.220i;-0.4399-3.220i;-3.601;-0.0128];
ref.lateral.modos={'Dutch roll';'Dutch roll';'Rollido';'Espiral'};
estados={'VT_ft_s','alfa','theta','q','pow','beta','phi','p','r'};
ref.pull_up.estados=estados;
ref.pull_up.entradas={'dth','de','da','dr'};
ref.pull_up.A=[ ...
    -.127 -235 -32.2 -9.51 .314 -.0028 .00126 5e-5 2e-4; ...
    -7e-4 -.969 0 .908 -2e-4 1.5e-5 0 -4e-5 -1e-5; ...
    0 0 0 1 0 0 0 0 0; ...
    9e-4 -4.56 0 -1.58 0 9.2e-5 0 0 -.00287; ...
    0 0 0 0 -5 0 0 0 0; ...
    1e-8 2e-5 3e-6 8e-7 -3e-8 -.322 .0612 .298 -.948; ...
    0 0 0 0 0 0 .0930 1 .310; ...
    -3e-7 -.00248 0 3e-4 0 -62.5 0 -3 1.99; ...
    -3e-6 -.00188 0 .00254 0 7.67 0 -.262 -.629];
ref.pull_up.B=[0 -.244 6e-6 2e-5; 0 -.00209 0 0; 0 0 0 0; ...
    0 -.199 0 0; 1087 0 0 0; 0 2e-8 3e-4 8e-4; ...
    0 0 0 0; 0 0 -.645 .126; 0 0 -.0180 -.0657];
ref.pull_up.C=[.0208 15.2 0 1.45 0 -4.5e-4 0 0 0; ...
    0 0 0 1 0 0 0 0 0; 0 57.3 0 0 0 0 0 0 0];
ref.pull_up.D=[0 .0333 0 0;0 0 0 0;0 0 0 0];
ref.pull_up.salidas={'an (definicion pendiente)','q','alfa_deg'};
ref.viraje_45g.estados=estados;
ref.viraje_45g.A=[ ...
    -.090 -169 -31.2 -7.75 .318 31.4 -7.73 5e-4 2e-3; ...
    -5e-4 -1.05 .0151 .903 -2e-4 3e-4 -.0607 -5e-4 -1e-4; ...
    0 0 0 .203 0 0 -.300 0 -.979; ...
    1e-3 1.26 0 -1.66 0 1e-3 0 .0589 -.0157; ...
    0 0 0 0 -5 0 0 0 0; ...
    -1e-4 1.4e-4 -.0032 7e-6 -3e-7 -.322 .0130 .248 -.961; ...
    0 0 .300 .0508 0 0 0 1 .0105; ...
    -3e-4 .0578 0 -.0469 0 -59.4 0 -3.19 1.64; ...
    5e-5 .0617 0 .0123 0 8.88 0 -.299 -.564];
end

function c = comparar_caso(A,ref,cfg)
c.estados=ref.estados;
c.A_modelo=A;
c.A_referencia=ref.A;
c.matriz=errores_matriz(A,ref.A,cfg);
c.polos=errores_polos(eig(A),ref.polos,cfg);
c.polos.referencia_matriz=eig(ref.A);
c.polos.modos=ref.modos;
c.estado=estado(c.matriz.numero_fuera==0 && c.polos.numero_fuera==0, ...
    cfg.condiciones_confirmadas);
end

function m = errores_matriz(actual,ref,cfg)
m.error=actual-ref;
m.error_absoluto=abs(m.error);
m.limite=cfg.tol_abs_A+cfg.tol_rel_A*abs(ref);
m.fuera=m.error_absoluto>m.limite;
m.numero_fuera=nnz(m.fuera);
m.max_error_absoluto=max(m.error_absoluto(:));
m.error_frobenius_relativo=norm(m.error,'fro')/max(norm(ref,'fro'),eps);
% NaN donde Lewis imprime cero: no se inventa un porcentaje relativo.
m.error_porcentaje=nan(size(ref));
mask=ref~=0;
m.error_porcentaje(mask)=100*m.error_absoluto(mask)./abs(ref(mask));
end

function p = errores_polos(actual,ref,cfg)
% Emparejamiento global uno-a-uno (4! alternativas), no orden por real.
orders=perms(1:numel(ref)); cost=zeros(size(orders,1),1);
for k=1:size(orders,1)
    ordered=actual(orders(k,:));
    cost(k)=sum(abs(ordered(:)-ref(:)));
end
[~,best]=min(cost);
p.permutacion=orders(best,:);
p.modelo_sin_ordenar=actual;
p.modelo=actual(p.permutacion); p.modelo=p.modelo(:);
p.referencia=ref(:);
p.error_absoluto=abs(p.modelo-p.referencia);
p.limite=cfg.tol_abs_polo+cfg.tol_rel_polo*abs(p.referencia);
p.fuera=p.error_absoluto>p.limite;
p.numero_fuera=nnz(p.fuera);
p.max_error_absoluto=max(p.error_absoluto);
p.zeta=-real(p.modelo)./max(abs(p.modelo),eps);
p.periodo_s=inf(size(actual));
osc=abs(imag(p.modelo))>1e-10;
p.periodo_s(osc)=2*pi./abs(imag(p.modelo(osc)));
end

function s = estado(coincide,confirmado)
if ~coincide, s='NO_COINCIDE';
elseif ~confirmado, s='COINCIDENCIA_NUMERICA_PROVISIONAL';
else, s='COINCIDE'; end
end

function c = comparar_maniobra(p,ref,cfg)
c.estado='PENDIENTE';
c.motivo='Falta el punto de operacion completo de Lewis (X15, U4 y parametros equivalentes).';
if isfield(ref,'C')
    c.estado_CD='PENDIENTE';
    c.motivo_CD='Falta la definicion completa de an; C/D no se comparan.';
end
if isempty(p), return; end
Xe=a_euler(p.X15(:)); U=p.U4(:); theta=p.theta(:);
Ae=jacobiano_fd(@(x) funciones_euler(0,x,U,theta),Xe);
idx=[3 4 10 7 1 5 9 6 8];
S=diag([1/0.3048 ones(1,8)]);
c.A_modelo=S*Ae(idx,idx)/S;
c.matriz=errores_matriz(c.A_modelo,ref.A,cfg);
c.X15=p.X15(:); c.U4=U; c.theta=theta;
numeric=c.matriz.numero_fuera==0;
if isfield(ref,'B')
    Be=jacobiano_fd(@(u) funciones_euler(0,Xe,u,theta),U);
    c.B_modelo=S*Be(idx,[4 1 2 3]);
    c.entradas=errores_matriz(c.B_modelo,ref.B,cfg);
    numeric=numeric && c.entradas.numero_fuera==0;
end
confirmed=isfield(p,'condiciones_confirmadas') && p.condiciones_confirmadas;
c.estado=estado(numeric,confirmed);
c.motivo='A/B se evaluaron en el punto suministrado; los estados excluidos se congelaron.';
end

function imprimir(r)
fprintf('\n=== CONTRASTE CON LEWIS (referencias transcritas de imagenes) ===\n');
fprintf('VT = %.4f m/s = %.1f ft/s; h = %.1f m; Xcg = %.2f cbar\n', ...
    r.config.VT_mps,r.config.VT_ft_s,r.config.altitud_m,r.config.Xcg);
fprintf('Condiciones/variante del libro confirmadas por usuario: %d\n',r.config.condiciones_confirmadas);
fprintf('Trim: alfa %.5f deg; de %.5f deg; dth %.6f; residuo %.3e\n', ...
    r.trim.alfa_deg,r.trim.de_deg,r.Utrim(4),r.trim.residuo);
fprintf('A/B: |error| <= %.3g + %.3g*|referencia| (elemento a elemento)\n', ...
    r.config.tol_abs_A,r.config.tol_rel_A);
fprintf('Polos: |error| <= %.3g + %.3g*|referencia| [1/s]\n', ...
    r.config.tol_abs_polo,r.config.tol_rel_polo);
fprintf('A4: motor y filtro LEF congelados; aerodinamica actual del repo.\n');
for name={'longitudinal','lateral'}
    c=r.(name{1});
    fprintf('\n--- %s: %s ---\n',upper(name{1}),c.estado);
    fprintf('Orden: %s\n',strjoin(c.estados,', '));
    fprintf('A de Lewis:\n'); disp(c.A_referencia);
    fprintf('A del modelo (en unidades de Lewis):\n'); disp(c.A_modelo);
    fprintf('Diferencia modelo - Lewis:\n'); disp(c.matriz.error);
    fprintf('Fuera de tolerancia: %d/16; error Frobenius relativo: %.2f%%\n', ...
        c.matriz.numero_fuera,100*c.matriz.error_frobenius_relativo);
    [rows,cols]=find(c.matriz.fuera);
    for k=1:numel(rows)
        i=rows(k); j=cols(k);
        fprintf(' A(%d,%d) d(%s_dot)/d(%s): libro=% .6g modelo=% .6g |err|=%.3g lim=%.3g\n', ...
            i,j,c.estados{i},c.estados{j},c.A_referencia(i,j),c.A_modelo(i,j), ...
            c.matriz.error_absoluto(i,j),c.matriz.limite(i,j));
    end
    fprintf('Polos emparejados uno-a-uno (modo asignado por proximidad):\n');
    for k=1:4
        a=c.polos.referencia(k); b=c.polos.modelo(k);
        fprintf(' %-14s Lewis=% .6f%+.6fi modelo=% .6f%+.6fi err=%.4g fuera=%d\n', ...
            c.polos.modos{k},real(a),imag(a),real(b),imag(b), ...
            c.polos.error_absoluto(k),c.polos.fuera(k));
    end
end
for name={'pull_up','viraje_45g'}
    c=r.(name{1});
    fprintf('\n%s: %s. %s\n',upper(name{1}),c.estado,c.motivo);
    if isfield(c,'matriz')
        fprintf(' A: %d/81 elementos fuera; error relativo %.2f%%\n', ...
            c.matriz.numero_fuera,100*c.matriz.error_frobenius_relativo);
    end
    if isfield(c,'entradas')
        fprintf(' B: %d/36 elementos fuera; error relativo %.2f%%\n', ...
            c.entradas.numero_fuera,100*c.entradas.error_frobenius_relativo);
    end
    if isfield(c,'estado_CD'), fprintf(' C/D: %s. %s\n',c.estado_CD,c.motivo_CD); end
end
fprintf('\nLa coincidencia interna del repo no implica equivalencia con Lewis.\n');
if ~r.config.condiciones_confirmadas
    fprintf('Comparacion de vuelo nivelado PROVISIONAL: confirmar altitud y variante del modelo.\n');
end
end
