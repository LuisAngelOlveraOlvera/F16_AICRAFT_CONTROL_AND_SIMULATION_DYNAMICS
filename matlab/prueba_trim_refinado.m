function prueba_trim_refinado
% Reproduce el viraje que no convergia despues de corregir la fisica c5.
r=validar_lewis(struct('mostrar',false));
[x,u,info]=trim_vuelo(170,3000,0,3,r.theta);
assert(info.converge && info.residuo<1e-6,'prueba_trim:Convergencia','El trim de viraje debe converger sin relajar tolerancia.');
d=funciones(0,x,u,r.theta);
assert(max(abs(d(3:8)))<1e-7);
assert(all(abs(u(1:3))<=[25;21.5;30]) && u(4)>=0 && u(4)<=1);
[xl,ul,il]=trim_vuelo(170,3000,0,-3,r.theta);
assert(il.converge && il.residuo<1e-6);
dl=funciones(0,xl,ul,r.theta); assert(max(abs(dl(3:8)))<1e-7);
[xc,uc,ic]=trim_vuelo(170,3000,0,0,r.theta);
[xr,ur,ir]=trim_crucero(170,3000,r.theta);
assert(ic.converge && ir.converge && max(abs(xc-xr))<1e-7 && max(abs(uc-ur))<1e-7);
fprintf('PRUEBA_TRIM_REFINADO: PASS\n');
end
