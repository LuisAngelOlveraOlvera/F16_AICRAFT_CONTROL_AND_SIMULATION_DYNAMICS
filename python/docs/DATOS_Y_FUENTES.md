# Datos y fuentes
Se incluyen los ajustes utilizados por el simulador y referencias numéricas
generadas mediante sus ejecuciones MATLAB. Se conserva procedencia y SHA-256
en references/manifest_referencias.json (Python) y docs/MANIFIESTO_PAQUETE.json.
No se declara que los datos aerodinámicos completos estén certificados.

No se incluyen Tablas 2.xlsx, Matriz A.xlsx ni los PDFs del repositorio de trabajo.
La auditoría de doce hojas es opcional y requiere una copia local autorizada.
Para habilitarla, crear datos_locales en la raíz y colocar allí Tablas 2.xlsx.
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
independiente de exactitud frente al avión real. La licencia futura del código
no sustituye la revisión de derechos/procedencia de los ajustes derivados.
