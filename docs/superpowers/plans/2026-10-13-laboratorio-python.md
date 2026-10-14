# Laboratorio Python Implementation Plan

> **For agentic workers:** usar superpowers:executing-plans en esta sesión; revisión final independiente.

**Goal:** interfaz independiente por pestañas con defaults README intactos.
**Architecture:** perfiles + validación y servicio de experimentos, extensiones opcionales de control/simulación, interfaz Tkinter con proceso cancelable y visualización Matplotlib.
**Tech Stack:** Python 3.12, Tkinter, NumPy, SciPy, Matplotlib existentes.
**Spec:** ../specs/2026-10-13-laboratorio-python.md

## Global Constraints
- No cambiar comandos, orden ni comportamiento predeterminado de README.
- Valores del avión de solo lectura; geometría docente explícita.
- Guardado sin sobrescritura y sin red.
- MATLAB intacto; contrato común documentado.

## Review Focus
- Defaults de demos distintos de escenarios genéricos, ruido de referencia y targets originales.
- Cambios pendientes no contaminan A/B ni metadatos.
- Errores, cancelar, cerrar ventana durante cálculo y IPC de registros grandes.
- Entradas NaN, pasos no divisores, rutas degeneradas, peso vs masa y CG relativo.
- Pestañas accesibles y gráficas legibles en ventana normal; último instante incluido.

## Task 1: perfiles y servicio
Files: python/f16py/laboratory/{profiles,experiments}.py, python/tests/test_laboratory.py.
Produces: defaults(profile), run_experiment(profile, options=None), aircraft_data().
- [x] Tests RED: defaults de ocho perfiles, restauración por copia, equivalencia directa con horizontes cortos, errores y procedencia.
- [x] Implementar perfiles y dispatch a funciones originales. Baseline debe pasar.
- [x] GREEN: unittest discover -s tests -p test_laboratory.py.

## Task 2: opciones avanzadas compatibles
Files: python/f16py/{simulation,control,demonstrations}.py; laboratory/experiments.py; tests/test_laboratory.py.
Consumes defaults/run_experiment; produces ensayos personalizados con registro reproducible.
- [x] RED: perturbaciones, ganancias PID, Q/R, referencias, Dryden sigma/L, entradas inválidas.
- [x] Extensiones opcionales; ruta original sin cambios.
- [x] GREEN: tests de laboratorio y suite existente.

## Task 3: escritorio y resultados
Files: python/laboratorio_f16.py, laboratory/{app,views,worker}.py, python/tests/test_laboratory_ui.py.
Consumes run_experiment y registros; produces ocho pestañas, A/B, reproducir, exportar/cargar, cancelar.
- [x] RED: construcción, restauración, conversión de ruta, worker y reproducción con Tk real (skip solo si no hay display).
- [x] Implementar UI, proceso, ficha del avión y figuras.
- [x] GREEN: prueba real UI y render capturado; comprobar interacción, exportación y cancelación.

## Task 4: documentación y cierre
Files: python/GUIA_LABORATORIO.md, docs/CONTRATO_LABORATORIO.md, README.md raíz (solo apéndice), docs/RESULTADO_LABORATORIO.md.
- [x] Ejecutar suite y verificar_publicacion, smoke README y perfiles.
- [x] Revisar diff independiente, reparar hallazgos importantes y verificar.
- [x] Entregar lanzamiento local y límites verificados; sin push/merge.
