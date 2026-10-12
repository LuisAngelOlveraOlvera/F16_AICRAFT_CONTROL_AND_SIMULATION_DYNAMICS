function verificar_publicacion
% Suite portable; no depende de PDFs, resultados previos ni carpeta hermana.
run_tests;assert(nfail==0,'publicacion:Core','Fallo en el nucleo.');
[nfail,~]=prueba_regresion_lewis;assert(nfail==0);
prueba_trim_refinado;prueba_6dof_estandarizado;
prueba_simulador_academico;prueba_waypoints_f16;prueba_paso_waypoints_f16;
prueba_ruta_salida_f16;prueba_exportacion_json_f16;prueba_bordes_guia_f16;
prueba_visualizacion_f16;
root=fileparts(mfilename('fullpath'));
if isfile(fullfile(root,'datos_locales','Tablas 2.xlsx')) || isfile(fullfile(root,'Tablas 2.xlsx'))
    validar_fuentes_aerodinamicas;
else
    fprintf('FUENTES AERODINAMICAS: NO EVALUADAS (datos locales opcionales no incluidos).\n');
end
fprintf('VERIFICAR_PUBLICACION: PASS (codigo; no certifica fidelidad ni derechos).\n');
end
