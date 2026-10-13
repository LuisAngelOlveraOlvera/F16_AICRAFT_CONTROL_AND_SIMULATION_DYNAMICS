# Plan de laboratorio MATLAB

Autorización: el usuario solicita proceder con MATLAB después de aprobar diseño, defaults y Estados. Se continúa en el checkout aislado actual, base 95f0d31; no se altera GitHub/main.

Objetivo: nueve pestañas equivalentes a Python mediante uifigure, controles comunes, ficha del modelo, estados simultáneos, comparación A/B, vuelo 3D, guardar/cargar, cálculo cancelable sin PCT ni Python.

Arquitectura: paquete +f16lab para perfiles/validación, ejecutor y observación, vistas y App. Las ecuaciones, ajustes, RKF y scripts README existentes permanecen intactos. Los experimentos originales se verifican frente a sus scripts, no se ejecutan dentro de la ventana porque usan clear/close all. Proceso MATLAB independiente con configuración MAT validada, resultado/errores persistidos y timer UI para seguimiento/cancelación. Las referencias y metadatos se congelan por ensayo.

Decisión documentada: MATLAB prueba_autopiloto dura 60 s y usa prefiltros exponenciales; Python perfil autopiloto 40 s llama el ejecutor académico con referencias limitadas en razón. Se conservan defaults nativos y se muestran procedencias; los perfiles personalizados usan el contrato común. No se fuerza paridad modificando scripts originales.

1. [x] Tests RED: perfiles, masas/inercias, validación, originales vs scripts y opciones avanzadas.
2. [x] Perfiles equivalentes, diseño/ejecutor auxiliar, observación y comparación; GREEN numérico, scripts originales sin cambios.
3. [x] Tests RED UI: nueve tabs, restauración, cursores y A/B, proceso/cancelar, exportación y errores.
4. [x] App nativa con selección informativa, campos aplicables y vistas; GREEN real y capturas.
5. [x] Comandos README/verificador, revisión independiente, documentación y entrega para commit local.

Ver evidencia detallada en docs/RESULTADO_LABORATORIO_MATLAB.md. Paridad adicional: cuatro configuraciones personalizadas Python/MATLAB sin viento pasan; se conservan las diferencias originales de autopiloto.

Evidencia de runtime: MATLAB R2024a instalado. Primer inicio sandbox falló por plugin de preferencias; se prueba MATLAB_PREFDIR/TEMP propios antes de cambiar permisos. Ninguna alteración del perfil MATLAB personal.
