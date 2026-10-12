# Contenido de esta publicación

Este repositorio reúne dos implementaciones en `matlab/` y `python/`. Para ejecutar una, entrar en su carpeta y seguir su README. Mantener ambas carpetas y las referencias numéricas incluidas.

Se publican código, pruebas, documentación, configuración y fixtures numéricos compactos MATLAB/Python. Se excluyen libros y manuales PDF, tablas XLSX, resultados de vuelo locales, videos, respaldos, historial legacy, entornos virtuales, cachés, credenciales y rutas personales.

No subir el directorio de trabajo completo ni las carpetas padre de preparación. Tampoco subir los archivos ZIP de entrega. Los datos opcionales se colocan localmente en `matlab/datos_locales/` o `python/datos_locales/`, que Git ignora.

Los archivos MAT de `python/references/` son excepciones deliberadas: las pruebas y algunos escenarios los necesitan. Su manifiesto documenta procedencia. La ausencia de las tablas originales limita la auditoría independiente de los ajustes.

El código se publica bajo licencia MIT por decisión del propietario: permite uso, modificación y redistribución conservando el aviso de copyright y la licencia. Los derechos de terceros conservan sus condiciones propias. No se incluyen secretos de MATLAB: cuando sea necesario, configurar `MLM_LICENSE_TOKEN` únicamente en GitHub Secrets.

Los flujos de CI ejecutables están en `.github/workflows/` de la raíz. Los archivos de workflow dentro de cada implementación se conservan como configuración de sus paquetes independientes; GitHub no los ejecuta desde esas ubicaciones.

Los manifiestos de cada implementación se regeneran para esta entrega. La validación local y la CI en GitHub se informan por separado; una prueba verde no certifica el comportamiento del avión real.
