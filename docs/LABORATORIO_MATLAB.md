# Laboratorio visual F-16 MATLAB

Componente MATLAB del [proyecto F-16](../README.md). Desde `matlab/`, en MATLAB R2024a:

```matlab
lab_f16_app
```

También puede abrirse en Windows mediante [matlab/ABRIR_LABORATORIO.bat](../matlab/ABRIR_LABORATORIO.bat). No requiere Python, MATLAB Engine, App Designer binario ni Parallel Computing Toolbox. La aplicación es código MATLAB base y utiliza un segundo proceso MATLAB para calcular sin bloquear la ventana. El ejecutor de procesos se verificó para Windows.

## Uso

1. Seleccionar una práctica en el menú superior. Sus valores se cargan en las pestañas y se muestra cuál está seleccionada y pendiente de simular.
2. Mantener **Configuración original README** para reproducir la práctica nativa. **Restaurar original** recupera sus propios defaults.
3. Pulsar **Simular**. El cálculo ocurre en un proceso independiente; **Cancelar** conserva los registros anteriores.
4. Al terminar se abre **Estados**: nueve gráficas simultáneas, referencias y cursor. Reproducir, desplazar el tiempo o pulsar una gráfica actualiza también la vista del avión.
5. **Vuelo y resultados** muestra trayectoria, actitud, cámara y telemetría. Ambos selectores de registro y controles de reproducción están sincronizados.
6. **Comparación** permite guardar B como A y superponer variables; la práctica comparación incorpora las curvas originales Euler/cuat, lineal/PID/LQR.
7. Desactivar el modo original para editar un ensayo. Solo se habilitan campos aplicables al escenario. En perfil genérico se puede elegir escenario y mando manual.

## Pestañas

- **Avión:** geometría docente y datos de consulta del modelo: masa, peso=m×g, gravedad, superficie, envergadura, cuerda, CG, inercias y momento angular del motor. Longitud/altura reales ausentes identificadas como no documentadas.
- **Simulación:** escenario, duración, paso, velocidad, altitud, semilla, intervalo y guardar/cargar configuración JSON.
- **Condiciones iniciales:** perturbaciones alfa/beta, actitud y tasas de giro. PID parte del estado base original fuera de trim.
- **Control:** Kp/Ki/Kq, factores Q/R longitudinales y laterales, referencias, amplitudes de trayectoria, ascenso/viraje y mandos manuales.
- **Ruta:** tabla N/E/altitud positiva editable, añadir/actualizar/eliminar/ordenar puntos, anticipación, radio y posición inicial. Pulsar el plano rellena N/E del editor; aplicar con Añadir/Actualizar. Conversión NED interna.
- **Turbulencia:** sigma y escalas por componente. Entradas reproducibles locales. La semilla no basta para igualar generadores MATLAB/Python.
- **Estados:** altitud, VT, alfa/beta, phi/theta, rumbo, p/q/r, P3, filtro/LEF y N/E. Actitud derivada de cuaterniones; no se muestran como curvas separadas las cuatro componentes del cuaternión ni los actuadores internos. Máximo 2500 puntos por curva solo para visualizar; el registro completo se conserva.
- **Comparación:** A/B congelados, condiciones y métricas RMS frente a la referencia de cada ensayo.
- **Vuelo y resultados:** avión 3D, ruta, cámara, tiempo compartido, velocidad de reproducción, telemetría y exportar MAT/CSV/JSON.

Guardar genera una nueva carpeta y rechaza sobrescritura. Cargar acepta registros MAT con variable `r` y valida su estructura antes de reemplazar resultados. Se conservan configuración y hashes de fuentes. Las configuraciones JSON usan el contrato común; para comparar implementaciones elegir modo personalizado y las mismas entradas.

## Defaults y diferencias nativas

| Práctica | MATLAB original | Python actual |
|---|---:|---:|
| PID alfa | 15 s | 15 s |
| LQR longitudinal | 20 s | 20 s |
| LQR lateral | 15 s | 15 s |
| Comparación | 15 s | 15 s |
| Autopiloto | **60 s, prefiltros exponenciales desde t=0** | **40 s, ejecutor común con cambio desde t=5** |
| Dryden | 30 s, práctica original MATLAB | 30 s, reproducción de esa práctica con entrada común |
| Trayectoria | 180 s, script nativo | 180 s, ejecutor con objetivos de referencia |
| Waypoints | 180 s, ejecutor común | 180 s, ejecutor común |

VT=170 m/s, altitud=3000 m y paso=.002 s en todas las prácticas originales. El README común reúne los comandos existentes; sus scripts y defaults se conservan. Las interfaces comparten organización, variables y contrato, y los ensayos personalizados permiten igualdad de condiciones. Los scripts nativos autopiloto/trayectoria tienen diferencias de prefiltros/registro frente al ejecutor común; su procedencia queda identificada.

Dryden original mantiene paso=.002 y horizonte<=30 s. Trayectoria original mantiene seis objetivos nativos antes de truncar el horizonte, evitando cambiar rumbo por consumir menos números aleatorios. En modo original conserva referencias de `ref_hist`; `referencia_aplicada` registra adicionalmente las usadas por el control. Las saturaciones distinguen comando bruto de mando aplicado.

## Comprobaciones adicionales

```matlab
prueba_laboratorio_f16
prueba_laboratorio_originales
prueba_laboratorio_visual
prueba_laboratorio_proceso
prueba_laboratorio_bordes
prueba_laboratorio_pestanas
```

Las pruebas visuales crean y capturan su propia ventana; ejecutarlas después de guardar el trabajo personal. Las originales utilizan scripts que hacen `clear`/`close all`: el laboratorio no los ejecuta dentro de la ventana de usuario. En Windows el lanzador usa preferencias/temporales propios bajo `resultados/`, sin reemplazar las preferencias personales de MATLAB.

Prueba opcional de condiciones comunes con Python: desde `matlab/`, generar un archivo nuevo con `python ../python/tools/exportar_paridad_laboratorios.py --salida resultados/paridad_laboratorios.mat`, y ejecutar `prueba_paridad_laboratorios('resultados/paridad_laboratorios.mat')`. Comprueba PID, LQR lateral, autopiloto y mandos manuales durante 0.2 s, sin viento; tolerancias absolutas X<2e-6, mandos<1e-5, referencias<2e-8. No sustituye una comparación de vuelos largos ni prueba igualdad entre generadores de ruido.
