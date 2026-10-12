# Verificación local del candidato — 11 de octubre de 2026

## MATLAB
verificar_publicacion: PASS en la copia limpia, MATLAB R2024a/Windows.
Nueve pruebas del núcleo, 21 regresiones, trim, 6DOF, simulador, waypoints,
paso mitad, ruta de salida, JSON, bordes y video aprobados.
La corrección de cls se comprobó en la copia; el original no se sobrescribió.
Auditoría de tablas originales: NO EVALUADA, dato local opcional no incluido.

## Python
verificar_publicacion.py: 24 tests ejecutados, 23 aprobados, 1 omitido.
Omitida únicamente test_fuentes_locales_opcionales por ausencia del XLSX original.
Ninguna prueba de física, control, paridad, ruido ni visualización se omitió.
Referencias compactadas verificadas contra los cálculos, sin rutas privadas.
Python 3.12.6, NumPy 2.0.1, SciPy 1.14.1, Matplotlib 3.9.3 y Pillow 10.4.0.

## Publicación
READMEs idénticos en las dos copias.
Estado histórico de la copia del 11 de octubre: Git local en main, sin remoto.
Para la entrega del 12 de octubre y su publicación conjunta consultar
`../../docs/VERIFICACION_PUBLICACION.md` y `../../PUBLICAR_EN_GITHUB.md`.
Reglas de exclusión comprobadas: resultados, PDFs, XLSX, datos locales,
respaldos y cachés ignorados; referencias MAT de prueba permitidas.
Workflow preparado, no probado en GitHub.
No se realizó instalación limpia de dependencias en otra máquina/OS.
No se eligió licencia ni se verificó titularidad jurídica de todo material.
Actualización del 12 de octubre: el propietario autorizó código abierto y se añadió licencia MIT. La revisión de titularidad de material de terceros sigue siendo independiente.
