# Validación del laboratorio Python — 13 octubre 2026

Informe histórico de esa entrega. El 14 de octubre se consolidaron las instrucciones en el README raíz y la guía se trasladó a [LABORATORIO_PYTHON.md](LABORATORIO_PYTHON.md); los comandos y motores conservan su comportamiento. La interfaz MATLAB se implementó después de esta validación inicial: ver [informe MATLAB](RESULTADO_LABORATORIO_MATLAB.md).

Base pública: `55b7587`. Implementación en rama local `codex/laboratorio-python`, checkout `LABORATORIO_PYTHON_20261013`. No se realizó push ni merge.

## Resultado

- `python verificar_publicacion.py`: ESTRUCTURA PASS y **42 pruebas, sin fallos, 1 omitida**. La omisión corresponde a la tabla aerodinámica local opcional que no se distribuye en el repositorio. Tiempo de la suite final: 212.821 s.
- Las 18 pruebas nuevas del laboratorio cubren perfiles originales, igualdad directa/interfaz para ocho experimentos cortos, perturbaciones, PID, pesos Q/R, mandos manuales, ruido reproducible, entradas inválidas/no aplicables, ficha del avión, registro capturado en t=0, validación de carga, ocho pestañas, restauración, A/B, cancelación, último instante, tamaño mínimo y curvas originales de comparación.
- Los tests existentes contrastan también PID, LQR longitudinal y comparación con sus referencias MATLAB a duración original, además de matrices, ajustes, trim, ecuaciones, viento y actuadores.
- Comandos README ejecutados adicionalmente: `python run_tests.py` (T1–T9 PASS), `python verificar_simetria.py` y `python validar_A.py`, completos sin errores.
- `python tools/validar_laboratorio.py --capturar`: proceso spawn real, ensayo original y modificado, A/B congelados, último instante, guardado/carga NPZ, rechazo de sobrescritura y cancelar: PASS. Capturas de avión, simulación, control, comparación, vuelo y ruta inspeccionadas.
- Revisión independiente realizada; se corrigieron opciones ignoradas, validación/atomicidad de registros y controles ocultos en tamaño mínimo. Reproducciones fallaron antes de las reparaciones y pasaron después.
- `git diff --check`: sin errores. MATLAB, ambos README de implementaciones, dinámica, aerodinámica, ajustes, ejecutores y fixtures no presentan modificaciones. Los dos README continúan idénticos. El README raíz tiene un acceso adicional a la interfaz.

## Reproducción

En este equipo: Python 3.12.6, NumPy 2.0.1, SciPy 1.14.1, Matplotlib 3.9.3, Tk 8.6; Windows. El sandbox impidió escribir/limpiar ciertos temporales predeterminados en el primer baseline; se repitieron las pruebas afectadas y la suite final con TEMP/TMP en `python/resultados/test_tmp`. No se cambiaron las pruebas originales ni los cálculos para ocultar ese problema.

```powershell
cd "C:\Users\User\Documents\MATLAB\Ecuaciones versión 8\Ecuaciones versión 8\LABORATORIO_PYTHON_20261013\python"
python laboratorio_f16.py
```

Usar el mismo intérprete de las dependencias comprobadas. El lanzador Windows prueba primero Python312 en LocalAppData y utiliza `python` como alternativa.

## Límites de la evidencia

Se verificó escritorio Windows; no se ejecutó la interfaz nativa en Linux/macOS ni GitHub Actions para esta rama. La suite permite omitir pruebas Tk cuando no hay display. No se repitieron todos los vuelos largos y videos de cada paso del README: la evidencia de compatibilidad consiste en defaults, llamadas directas, referencias numéricas, suite existente y comandos representativos. La geometría del avión es docente y los datos físicos corresponden al modelo; no constituyen certificación del avión real. La interfaz MATLAB todavía no está implementada.

El manifiesto de la entrega 20261012 conserva su carácter histórico. Cada nuevo ensayo registra hashes de sus fuentes y de los fixtures de referencia utilizados; no se presenta el manifiesto histórico como hash vigente de esta ampliación.

## Ampliación posterior: pestaña Estados

Se añadió una novena pestaña con nueve paneles físicos y referencias, selección temporal por gráfica, controles de reproducción propios y cursor/selección de ensayo compartidos con la vista 3D. Se abre automáticamente después del cálculo. Los defaults y el motor numérico no se modificaron.

Validación de esta ampliación: 19 pruebas de laboratorio/UI y 2 de gráficas de estados, todas correctas; verificador de estructura PASS. La prueba real de proceso, A/B, exportación, cancelación y capturas volvió a pasar. Se inspeccionó la captura de Estados. No se repitió la suite numérica larga, pues el cambio solo añade presentación y la lógica de cálculo no tiene diferencias contra el commit anterior. La cifra 42 de arriba corresponde a la entrega inicial.
