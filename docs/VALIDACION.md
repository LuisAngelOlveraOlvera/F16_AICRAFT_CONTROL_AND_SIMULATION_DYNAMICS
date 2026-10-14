# Evidencia de validación
Modelo trabajado y contrastado en MATLAB R2024a y Python 3.12.6.
La paridad de diez escenarios completos dio una diferencia máxima de posición
de 2.926e-8 m y de mandos de 1.388e-10. PID y LQR longitudinal fueron
contrastados muestra a muestra, junto con la comparación de cuatro respuestas.
No se ajustaron coeficientes para forzar concordancia con Lewis.

Las referencias compactadas mantienen los valores numéricos y eliminan
metadatos de rutas personales y observaciones redundantes. Sus hashes de origen
y de paquete están registrados en [python/references/manifest_referencias.json](../python/references/manifest_referencias.json).

## Validación local de la entrega inicial, 12 de octubre de 2026
MATLAB R2024a/Windows: nueve pruebas del núcleo, 21 regresiones y pruebas
de trim, equivalencia 6 DOF, simulador, waypoints, paso, exportación y
visualización aprobadas el 12 de octubre de 2026.
Python 3.12/Windows: 24 pruebas, 23 aprobadas y una omitida por la ausencia
del XLSX original. Ninguna prueba de física, control o paridad se omitió.
En Python la prueba de tablas locales se omite si no se proporcionan esos datos.
La omisión no es una validación de las tablas y se informa expresamente.
La validación de GitHub Actions se consulta por commit en:
https://github.com/LuisAngelOlveraOlvera/F16_AICRAFT_CONTROL_AND_SIMULATION_DYNAMICS/actions
Las pruebas no certifican fidelidad al avión real.

## Repetir
MATLAB: verificar_publicacion
Python: python verificar_publicacion.py
Paridad nueva: python validar_paridad.py --salida resultados/validacion_nueva
Diez vuelos: python ejecutar_guia_f16.py; luego python validar_integral.py
CARPETA_GENERADA --salida resultados/contraste_nuevo.json.
El validador integral usa references/integral por defecto: no necesita un
repositorio MATLAB hermano ni resultados de otra computadora.

## Laboratorios visuales y proyecto común

La evidencia adicional de las interfaces se conserva en los informes [Python](RESULTADO_LABORATORIO.md) y [MATLAB](RESULTADO_LABORATORIO_MATLAB.md). Las comprobaciones GitHub Actions de ambas implementaciones pasaron para `54fc778`, publicado el 14 de octubre de 2026.

El README raíz es la guía única de ejecución; `matlab/` y `python/` conservan los puntos de entrada. La documentación, licencia, contribuciones y configuración GitHub son comunes. `python tools/verificar_documentacion.py`, desde la raíz, comprueba enlaces y ausencia de duplicados; el verificador de publicación Python incluye esta comprobación y acepta invocación desde la raíz o desde `python/`.

La consolidación conserva los 30 bloques de comandos originales y los 28 puntos de entrada en cada lenguaje. Los manifiestos históricos permanecen intactos. La revisión independiente de estas rutas, configuración y documentación no encontró defectos materiales.

Verificación local de la estructura consolidada, 14 de octubre: `python verificar_publicacion.py --pre-publicar` completó 45 pruebas en 354.620 s, sin fallos y con una omisión por la tabla aerodinámica local opcional. La documentación común y sus enlaces también pasaron. El cambio de organización conserva las ecuaciones, los controladores y los defaults.
