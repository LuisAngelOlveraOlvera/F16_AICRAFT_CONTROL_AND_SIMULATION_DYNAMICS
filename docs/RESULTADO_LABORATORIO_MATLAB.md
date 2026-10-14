# Validación del laboratorio MATLAB — 13 octubre 2026

Implementación local sobre `95f0d31`, en `codex/laboratorio-python`, checkout `LABORATORIO_PYTHON_20261013`. MATLAB R2024a, Windows. No se realizó push ni merge. Python conserva su motor; MATLAB tiene aplicación y ejecutor propios.

## Evidencia

- `verificar_publicacion`: PASS, incluidos núcleo, trim, modelo estandarizado, simulador, waypoints, paso, rutas, exportación JSON, bordes, curvas, pose, PNG y video decodificado. Datos aerodinámicos locales opcionales: no evaluados. Registro local `matlab/baseline_matlab.log`.
- `prueba_laboratorio_originales`: PASS contra los siete scripts originales a su duración nativa. Estados PID error máximo 4.55e-13, longitudinal 0, lateral 1.78e-15, autopiloto 1.77e-9 y trayectoria 2.72e-9. Comparación valida Hq/He/Xl/Xp/Xk/up/uk; Dryden valida ambos historiales H; tolerancia absoluta 2e-7. Referencias nativas de trayectoria y prefijo al acortar a 60 s también pasan. Registro `matlab/originales_verificados.log`; X no se compara directamente para comparación/Dryden y aparece como NaN informativo en esas dos líneas del log.
- `prueba_laboratorio_f16`: PASS para nueve defaults, masa/inercias, perturbaciones, PID, viento nulo, manual, llegada inmediata, grupos incompletos, valores no aplicables, límites y saturación de comando bruto.
- `prueba_laboratorio_bordes`: PASS para resultado ausente y liberación del ejecutor, comparación cargada incompleta, cambios Dryden/manual/PID/nivelado conservando ediciones relevantes y reproducción a media velocidad de registros dispersos. El resultado ausente falló antes de la reparación (`bordes_red.log`).
- `prueba_laboratorio_visual`: PASS para nueve pestañas, restauración, estados y cursores sincronizados, último instante, A/B, rechazo de registros inválidos y guardado MAT sin sobrescritura. Nueve paneles de tamaño útil y sin superposición; captura inspeccionada.
- `prueba_laboratorio_proceso`: PASS con segundo proceso MATLAB real: Simular entrega registro y Cancelar detiene solo el cálculo iniciado por la aplicación, conservando el registro anterior. Estas cuatro pruebas comparten `matlab/laboratorio_final.log`.
- `prueba_laboratorio_pestanas`: PASS para los nueve perfiles, 28 variables de comparación, tamaño de la gráfica, botones y vistas 3D. Capturas de avión, simulación, control, ruta, comparación y vuelo inspeccionadas. Registro final `matlab/pestanas_distribucion.log`.
- `prueba_paridad_laboratorios`: PASS para cuatro ensayos personalizados con las mismas configuraciones que Python durante 0.2 s, sin viento. Máxima diferencia X 7.02e-11, mandos 2.64e-10, referencias 1.08e-19; tolerancias 2e-6, 1e-5 y 2e-8 respectivamente. PID, LQR lateral, autopiloto y manual. Fixture generada con `python/tools/exportar_paridad_laboratorios.py`; registro `matlab/paridad_laboratorios.log`.
- Revisión independiente: se corrigieron recuperación del proceso, validación de curvas de comparación, acumulación continua del tiempo de reproducción y valores deshabilitados al cambiar escenarios.
- Revisión final acotada sin defectos materiales pendientes en esas correcciones. Después de los últimos ajustes de distribución, `prueba_laboratorio_bordes` y `prueba_laboratorio_visual` volvieron a pasar (`matlab/interfaz_cierre.log`).

Los registros y capturas se generan localmente bajo `matlab/resultados/` y los logs quedan fuera del control de versiones. Los originales MATLAB, la dinámica Python y los dos README de implementaciones no se editaron. README raíz, contrato y guías incorporan el acceso a la aplicación nueva.

## Uso y límites

Desde `matlab/`: `lab_f16_app`, o el lanzador Windows `ABRIR_LABORATORIO.bat`. Ver [guía](LABORATORIO_MATLAB.md). La conservación de archivos README descrita en este informe corresponde a la entrega del 13 de octubre; desde el 14 sus instrucciones se reúnen en el README raíz, manteniendo los comandos y el cálculo.

Se preserva autopiloto MATLAB de 60 s con sus prefiltros nativos; Python original permanece en 40 s con su ejecutor académico. El modo personalizado y el contrato común permiten comparar condiciones idénticas. La prueba de cuatro casos cortos no acredita todos los vuelos largos ni igualdad de ruido usando solo una semilla. MAT/NPZ son formatos nativos distintos; JSON comparte configuración.

Se probó la interfaz en Windows/R2024a. No se verificaron otros sistemas, otras versiones ni GitHub Actions para esta rama. Los scripts originales ya usan las ecuaciones, aerodinámica y RKF que consume el laboratorio; las comparaciones anteriores verifican los adaptadores sin sustituir esos originales. La geometría es docente; longitud/altura reales no documentadas permanecen identificadas como tales.

El aislamiento bloqueó inicialmente preferencias y el servidor gráfico localhost de MATLAB. Se usaron preferencias/temporales propios bajo resultados y pruebas de ventana con permiso de ejecución ampliado, sin modificar preferencias personales.
