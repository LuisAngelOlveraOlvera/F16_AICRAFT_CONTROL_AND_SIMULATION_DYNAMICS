# Datos y fuentes
Se incluyen los ajustes utilizados por el simulador y referencias numéricas
generadas mediante sus ejecuciones MATLAB. Se conserva procedencia y SHA-256
en [python/references/manifest_referencias.json](../python/references/manifest_referencias.json) y los manifiestos históricos [MATLAB](historial/MANIFIESTO_MATLAB_20261012.json) y [Python](historial/MANIFIESTO_PYTHON_20261012.json).
No se declara que los datos aerodinámicos completos estén certificados.

No se incluyen Tablas 2.xlsx, Matriz A.xlsx ni los PDFs del repositorio de trabajo.
La auditoría de doce hojas es opcional y requiere una copia local autorizada.
Para habilitarla, colocar Tablas 2.xlsx en `matlab/datos_locales/` o `python/datos_locales/`, según el componente que ejecuta la auditoría.
Esa carpeta está ignorada por Git. No subirla manualmente por la web.

MATLAB: validar_fuentes_aerodinamicas
Python: python validar_fuentes_aerodinamicas.py
Sin tabla, el comando informa su ausencia y la prueba específica se marca
NO EVALUADA/omitida; las pruebas de física y paridad numérica siguen activas.

Fuentes bibliográficas:
- Stevens, B. L.; Lewis, F. L.; Johnson, E. N. Aircraft Control and Simulation,
  tercera edición, Wiley, 2015. Citar el libro; no redistribuir su PDF sin permiso.
- Nguyen et al. NASA TP-1538, diciembre de 1979.
  https://ntrs.nasa.gov/citations/19800005879
- El manual F-16 local y las tablas requieren confirmar autoría, versión,
  configuración LEF/CG y términos de redistribución antes de adjuntarlos.

Las referencias generadas son una validación de implementación, no prueba
independiente de exactitud frente al avión real. La licencia MIT del código
no sustituye la revisión de derechos/procedencia de los ajustes derivados.

Los manifiestos del 12 de octubre se preservan sin cambiar sus hashes. Sus rutas son relativas a los paquetes originales de esa fecha; no describen la organización ni los hashes vigentes después de incorporar las interfaces y consolidar la documentación. Cada ensayo del laboratorio registra sus propias fuentes actuales.
