# Evidencia de validación
Modelo trabajado y contrastado en MATLAB R2024a y Python 3.12.6.
La paridad de diez escenarios completos dio una diferencia máxima de posición
de 2.926e-8 m y de mandos de 1.388e-10. PID y LQR longitudinal fueron
contrastados muestra a muestra, junto con la comparación de cuatro respuestas.
No se ajustaron coeficientes para forzar concordancia con Lewis.

Las referencias compactadas mantienen los valores numéricos y eliminan
metadatos de rutas personales y observaciones redundantes. Sus hashes de origen
y de paquete están registrados en references/manifest_referencias.json (Python).

## Validación de estas copias
Los resultados actuales se registrarán en docs/RESULTADO_VERIFICACION.md.
En Python la prueba de tablas locales se omite si no se proporcionan esos datos.
La omisión no es una validación de las tablas y se informa expresamente.
No se verifica GitHub Actions en la nube antes de existir un remoto.

## Repetir
MATLAB: verificar_publicacion
Python: python verificar_publicacion.py
Paridad nueva: python validar_paridad.py --salida resultados/validacion_nueva
Diez vuelos: python ejecutar_guia_f16.py; luego python validar_integral.py
CARPETA_GENERADA --salida resultados/contraste_nuevo.json.
El validador integral usa references/integral por defecto: no necesita un
repositorio MATLAB hermano ni resultados de otra computadora.
