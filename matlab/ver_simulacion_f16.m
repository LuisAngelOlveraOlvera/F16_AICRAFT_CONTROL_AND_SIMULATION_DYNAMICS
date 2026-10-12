function [r,figuras,animacion] = ver_simulacion_f16(archivo)
% VER_SIMULACION_F16  Abre graficas y reproduce el MAT de un ensayo.
% ver_simulacion_f16('resultados_f16/.../trayectoria/registro.mat')
assert(isfile(archivo),'ver_f16:Archivo','No existe el registro solicitado.');
data=load(archivo,'r');assert(isfield(data,'r'),'ver_f16:Formato','Falta registro r.');
r=data.r;
figuras=graficar_f16_academico(r,'on');
animacion=animar_f16_academico(r,struct('visible','on','tiempo_real',true,'velocidad',6));
end
