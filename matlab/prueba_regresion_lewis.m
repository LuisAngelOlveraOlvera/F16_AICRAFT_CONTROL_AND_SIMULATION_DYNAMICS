function [nfail,detalle] = prueba_regresion_lewis
% Regresiones de referencia, transformacion ZYX y extraccion lateral.
% Se pueden ejecutar sin borrar el workspace ni modificar archivos.
r=validar_lewis(struct('mostrar',false)); nfail=0; detalle=struct('nombre',{},'pass',{});
check('Referencia A(4,4) = -0.49849',abs(r.lateral.A_referencia(4,4)+0.49849)<1e-12);
[A,~,~,~,~]=modelo_ss('lateral',r.config.VT_mps,r.config.altitud_m,r.theta);
A=A([1 4 2 3],[1 4 2 3]);
check('modelo_ss lateral coincide con Jacobiano Euler',max(abs(A-r.lateral.A_modelo),[],'all')<1e-8);
teta_tr=0.31; h=1e-6;
expected=(quaternion(h,teta_tr)-quaternion(-h,teta_tr))/(2*h);
files={'modelo_ss.m','prueba_lqr_lat.m','prueba_autopiloto.m','prueba_dryden.m','prueba_trayectoria.m'};
for k=1:numel(files)
    source=fileread(fullfile(fileparts(mfilename('fullpath')),files{k}));
    token=regexp(source,'dq_dfi\s*=\s*(\[[^\]]+\])','tokens','once');
    assert(~isempty(token),'prueba_lewis:Expression','No se encuentra dq_dfi en %s.',files{k});
    actual=eval(token{1}); % solo la expresion vectorial del archivo del repo
    check(['Cadena ZYX en ' files{k}],max(abs(actual-expected))<1e-9);
end
source=fileread(fullfile(fileparts(mfilename('fullpath')),'prueba_lqr_lat.m'));
token=regexp(source,'(?s)q0=cos\(0\.5\*fi0\).*?q3=[^;]+;','match','once');
assert(~isempty(token),'prueba_lewis:Expression','Falta bloque inicial de actitud.');
fi0=10*pi/180; teta_tr=0.31; %#ok<NASGU>
q0=0; q1=0; q2=0; q3=0; %#ok<NASGU>
eval(token);
actual=[q0;q1;q2;q3];
check('Condicion inicial lateral representa phi pedido y psi=0', ...
    max(abs(actual-quaternion(fi0,teta_tr)))<1e-12);
source=fileread(fullfile(fileparts(mfilename('fullpath')),'prueba_calc_ABCD.m'));
token=regexp(source,'q3\s*=\s*([^;]+);','tokens','once');
fi=0.23; teta=-0.31; psi=0.17; %#ok<NASGU>
expected3=cos(fi/2)*cos(teta/2)*sin(psi/2)-sin(fi/2)*sin(teta/2)*cos(psi/2);
check('Actitud ZYX combinada en prueba_calc_ABCD',abs(eval(token{1})-expected3)<1e-12);
% La ecuacion de tensor independiente requiere c5=(Iz-Ix)/Iy.
Ix=12874.8; Iy=75673.6; Iz=85552.1; Ixz=1331.4; %#ok<NASGU>
gama=Ix*Iz-Ixz^2; gamma=gama; %#ok<NASGU>
files={'pruebarkf.m','prueba_calc_ABCD.m','prueba_comparacion.m', ...
    'prueba_lqr.m','prueba_lqr_lat.m','prueba_autopiloto.m','prueba_dryden.m', ...
    'prueba_trayectoria.m','run_tests.m','validar_A.m','validar_lewis.m','verificar_simetria.m'};
for k=1:numel(files)
    source=fileread(fullfile(fileparts(mfilename('fullpath')),files{k}));
    token=regexp(source,'c5\s*=\s*([^;]+);','tokens','once');
    assert(~isempty(token),'prueba_lewis:Expression','Falta constructor c5.');
    check(['Acoplamiento inercial c5 en ' files{k}],abs(eval(token{1})-(Iz-Ix)/Iy)<1e-12);
end
fprintf('REGRESION_LEWIS: %d PASS, %d FAIL\n',numel(detalle)-nfail,nfail);

    function check(nombre,ok)
        detalle(end+1)=struct('nombre',nombre,'pass',logical(ok));
        if ok, fprintf('[PASS] %s\n',nombre);
        else, fprintf('[FAIL] %s\n',nombre); nfail=nfail+1; end
    end
end

function q=quaternion(phi,theta)
% ZYX (psi=0), misma orientacion que Rz(0)*Ry(theta)*Rx(phi).
q=[cos(phi/2)*cos(theta/2);sin(phi/2)*cos(theta/2); ...
   cos(phi/2)*sin(theta/2);-sin(phi/2)*sin(theta/2)];
end
