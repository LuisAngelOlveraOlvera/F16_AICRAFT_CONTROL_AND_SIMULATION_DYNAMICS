# Ledger — plan: 2026-10-13-laboratorio-python.md

Base: 55b7587; branch codex/laboratorio-python; copia aislada desde repositorio publicado limpio.
Autorización: el usuario aprobó diseño/defaults y pidió proceder primero Python; ejecución continua en esta sesión.
Pre-flight: Task 1 entrega perfiles y registros consumidos por Tasks 2/3. Defaults originales y avanzados separados.
Decisión: Tkinter + Matplotlib existentes; interfaz nativa independiente, sin Dash/servicio web ni dependencias nuevas.
La herramienta nativa de worktrees apunta al repo MATLAB exterior, no al repo público anidado. Se creó worktree Git en LABORATORIO_PYTHON_20261013 para trabajar sobre el commit público correcto.

Task 1: complete — 3 pruebas perfiles/dispatch/ficha GREEN; comparación exacta de registros cortos en los ocho perfiles contra funciones originales.
Task 2: complete — 9 pruebas iniciales GREEN; opciones avanzadas, mando manual y validación. Baseline 24 tests: dos errores de permisos de Temp sandbox; test_features 10/10 GREEN con TEMP bajo resultados/test_tmp. No se editaron tests originales para ocultar errores.
Task 3: complete — UI real Tk construida; proceso spawn, A/B, slider, NPZ y cancelar comprobados con tools/validar_laboratorio.py; capturas revisadas visualmente. Full suite inicial 36 tests OK, skipped=1 (tabla local opcional).
Revisión independiente: tres hallazgos importantes: campos no aplicables ignorados; validación/atomicidad de registros importados; controles ocultos al tamaño mínimo. Se escribieron reproducciones RED y reparaciones GREEN. También se admite captura de waypoint t=0 (registro de una muestra). Se valida alfa de referencia, navegación y tipo numérico de métricas/condiciones.
Decisión: conservar idénticos los README de matlab/python y añadir acceso al laboratorio solo en README raíz y GUIA_LABORATORIO. No se altera código MATLAB ni archivos de datos/fixtures.
Task 4: in progress — verificador publicación y suite definitiva con las reparaciones; QA visual final y comandos README representativos.

Task 4: complete — verificar_publicacion ESTRUCTURA PASS; 42 pruebas OK, skipped=1, 212.821 s. Laboratorio 18 pruebas GREEN. run_tests T1–T9, verificar_simetria y validar_A ejecutados. QA real final PASS y capturas revisadas. Diff sin cambios en MATLAB, README de implementaciones, ecuaciones, ajustes, ejecutores o fixtures. Informe docs/RESULTADO_LABORATORIO.md.
Final review: independiente, sin hallazgos importantes pendientes tras correcciones verificadas. Se conserva rama local y worktree para que el usuario pueda ejecutar y revisar, sin publicación ni modificación de main.
