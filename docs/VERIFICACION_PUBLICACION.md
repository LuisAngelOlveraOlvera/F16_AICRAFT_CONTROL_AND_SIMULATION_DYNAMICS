# Verificación de la entrega pública — 12 de octubre de 2026

Se preparó una copia nueva con dos implementaciones, conservando el área de trabajo y las entregas anteriores. Sólo se adaptó documentación y ubicación de los workflows para reunirlas en un repositorio; no se modificaron ecuaciones ni coeficientes.

MATLAB R2024a/Windows: `verificar_publicacion` finalizó con código de salida 0. Pasaron nueve pruebas del núcleo, 21 regresiones, trim, equivalencia 6 DOF, simulador, waypoints, sensibilidad al paso, ruta de salida, exportación JSON, bordes y visualización PNG/video. Las tablas originales no están incluidas: su auditoría se informa como NO EVALUADA.

Python 3.12/Windows: `verificar_publicacion.py` finalizó con código de salida 0: 24 pruebas, 23 aprobadas y una omitida únicamente por la ausencia deliberada del XLSX. Ninguna prueba de física, control, paridad o visualización se omitió. En la primera ejecución restringida hubo dos errores de permisos al escribir temporales; al repetir con acceso a temporales, la suite completa pasó sin cambiar el código.

Se revisó el contenido textual y los campos de texto de los archivos MAT para detectar rutas personales y patrones de credenciales. Se excluyeron PDFs, XLSX, resultados de trabajo, respaldos, archivos de video, entornos y cachés. Los fixtures numéricos necesarios se conservan. El commit emplea una dirección GitHub noreply, sin correo personal.

Las dos guías de ejecución son idénticas. Los manifiestos de archivos se regeneran para esta entrega. Espacios al final de líneas heredadas de algunos archivos MATLAB no se cambiaron; no afectan esta verificación dinámica.

La CI remota se verifica después de publicar. El propietario autorizó código abierto y se añadió licencia MIT el 12 de octubre de 2026. La titularidad de ajustes derivados se documenta por separado y no se declara verificada. Las pruebas no certifican fidelidad al avión real.
