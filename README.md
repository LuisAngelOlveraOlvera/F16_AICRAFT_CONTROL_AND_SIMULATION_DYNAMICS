# F-16 Aircraft Control and Simulation Dynamics

Un proyecto académico de dinámica, control y simulación no lineal del F-16, con dos implementaciones paralelas: **MATLAB y Python**. Este README es el punto de entrada común para instalar, abrir las interfaces, ejecutar las prácticas y consultar resultados.

Incluye trim, linealización, análisis modal, PID/LQR/LQI, autopiloto, turbulencia Dryden, seguimiento por waypoints, gráficas de estados y vuelo 3D. Los motores de cálculo y visualización son nativos de cada lenguaje; comparten organización, variables y contrato académico.

## Organización del proyecto

```text
README.md          Guía común de uso y orden completo de las prácticas
LICENSE            Licencia MIT del proyecto
CONTRIBUTING.md    Reglas comunes para contribuir
docs/              Guías, fuentes, límites, contrato y validación
matlab/            Implementación MATLAB, aplicación y pruebas
python/            Implementación Python, aplicación, pruebas y referencias
.github/           Configuración común de issues y pruebas automáticas
```

Se clona el repositorio una sola vez. Las carpetas `matlab/` y `python/` son componentes del mismo proyecto. Las instrucciones siguientes indican el directorio desde el que se ejecuta cada comando; no se mezclan intérpretes ni dependencias.

## Abrir el laboratorio visual

| | MATLAB | Python |
|---|---|---|
| Requisito | MATLAB base, probado con R2024a | Python 3.12 y `python/requirements-tested.txt`; Tkinter |
| Carpeta de trabajo | `matlab/` | `python/` |
| Abrir | `lab_f16_app` | `python laboratorio_f16.py` |
| Lanzador Windows | [matlab/ABRIR_LABORATORIO.bat](matlab/ABRIR_LABORATORIO.bat) | [python/ABRIR_LABORATORIO.bat](python/ABRIR_LABORATORIO.bat) |
| Guía específica de interfaz | [Laboratorio MATLAB](docs/LABORATORIO_MATLAB.md) | [Laboratorio Python](docs/LABORATORIO_PYTHON.md) |

Desde la raíz del repositorio, en MATLAB:

```matlab
cd('matlab')
lab_f16_app
```

Desde la raíz, en PowerShell con Python ya configurado:

```powershell
cd python
python -m pip install -r requirements-tested.txt
python laboratorio_f16.py
```

Para preparar un entorno Python nuevo, consultar el paso 0 antes de abrir la interfaz. MATLAB no requiere Control System Toolbox, Parallel Computing Toolbox ni MATLAB Engine. Python calcula sin MATLAB. FFmpeg se requiere para exportar video desde Python, no para simular.

### Interacción común

1. Elegir una práctica: el menú carga sus defaults y deja el ensayo pendiente de simular.
2. Mantener **Configuración original README** para reproducir la práctica. **Restaurar original** recupera los valores de ese perfil.
3. Pulsar **Simular**. El cálculo ocurre en otro proceso; **Cancelar** conserva los resultados anteriores.
4. Al terminar se abre **Estados**: nueve paneles físicos con referencias y selección temporal compartida con el avión.
5. En **Vuelo y resultados**, reproducir o desplazar el tiempo para explorar trayectoria, actitud, cámara y telemetría.
6. En **Comparación**, guardar B como A, cambiar parámetros y volver a simular B. Las condiciones de los registros calculados permanecen congeladas.
7. Desactivar el modo original para editar campos habilitados; el perfil genérico permite cambiar escenario. Guardar/cargar configuración JSON o resultados nativos.

| Pestaña | Contenido compartido |
|---|---|
| Avión | Masa, peso, superficie, envergadura, cuerda, CG, inercias y momento angular del motor; datos de consulta |
| Simulación | Escenario, duración, paso, velocidad, altitud, semilla e intervalo de consignas |
| Condiciones iniciales | Perturbaciones alfa/beta, actitud y tasas de giro |
| Control | PID, factores Q/R, referencias, ascenso/viraje y mandos manuales |
| Ruta | Waypoints Norte/Este/altitud, orden, anticipación, radio de captura y posición inicial |
| Turbulencia | Intensidades y escalas u/v/w |
| Estados | Altitud, velocidad, alfa/beta, actitud, rumbo, p/q/r, P3, filtro/LEF y N/E |
| Comparación | Variables físicas y métricas A/B; respuestas originales Euler/cuat y lineal/PID/LQR |
| Vuelo y resultados | Trayectoria y avión 3D, reproducción sincronizada, telemetría y exportación |

### Defaults y comparación entre lenguajes

Las prácticas originales mantienen sus valores actuales: VT=170 m/s, altitud=3000 m y paso=.002 s. PID dura 15 s, LQR longitudinal 20 s, lateral 15 s, comparación 15 s, Dryden 30 s, trayectoria y waypoints 180 s.

Se conserva una diferencia previa: **autopiloto original MATLAB dura 60 s con prefiltros exponenciales desde t=0; Python dura 40 s con referencias del ejecutor académico desde t=5**. La trayectoria MATLAB conserva el registro nativo de referencias. Para comparar utilizar el modo personalizado con las mismas condiciones; compartir una semilla no iguala los generadores de ruido.

El [contrato común](docs/CONTRATO_LABORATORIO.md) define las entradas, unidades, campos aplicables y límites. La configuración personalizada JSON se comparte; los resultados permanecen nativos: MATLAB MAT, Python NPZ, ambos con CSV/JSON. La silueta del avión es docente; longitud y altura reales no documentadas se identifican expresamente.

## Prácticas y comandos originales

Los puntos de entrada y sus cálculos permanecen disponibles. **Todos los bloques MATLAB siguientes se ejecutan desde `matlab/`; todos los bloques Python desde `python/`**, después de entrar a esas carpetas en el paso 0. El orden académico se conserva completo.

Para comprobar la instalación completa, desde `matlab/`:

```matlab
verificar_publicacion
```

Desde `python/`:

```powershell
python verificar_publicacion.py
```

El verificador Python comprueba también la documentación y configuración comunes en la raíz.

## Leyenda: qué ejecutar según el objetivo

- **Primera ejecución o después de modificar código:** pruebas del núcleo y pruebas adicionales. Revisar los PASS/FAIL; detener la interpretación de resultados si hay errores.
- **Experimentación:** elegir PID, LQR, autopiloto, turbulencia o trayectoria y abrir sus gráficas. No hace falta repetir toda la suite para visualizar un vuelo validado.
- **Ejecución completa con resultados guardados:** `ejecutar_guia_f16`; para seguimiento espacial, `ejecutar_waypoints_f16`.

Las demostraciones MATLAB originales pueden limpiar variables y cerrar
figuras anteriores. Ejecutar cada bloque por separado y guardar primero
los resultados propios. Las funciones auxiliares no se ejecutan como pasos.

## 0. Entrar a la carpeta correcta

En MATLAB:

```matlab
% Desde la raíz del repositorio, entrar al componente MATLAB.
cd('matlab')
pwd
```

En PowerShell, para Python:

```powershell
# Desde la raíz del repositorio, entrar al componente Python.
cd python
pwd
```

MATLAB base, probado con R2024a; no se requiere Control System Toolbox.
Python 3.12, NumPy, SciPy, Matplotlib y Pillow: versiones probadas en
`requirements-tested.txt` del componente Python. Los comandos suponen que
`python` resuelve tu intérprete Python 3.12 con esas dependencias.
MP4 Python requiere FFmpeg; la simulación no requiere MATLAB Engine.

Preparar un entorno Python separado (opcional si ya está configurado):

```powershell
python -m venv .venv
# Windows PowerShell:
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements-tested.txt
```

En Linux/macOS activar con `source .venv/bin/activate`.
Verificar el paquete limpio: MATLAB `verificar_publicacion`; Python
`python verificar_publicacion.py`. La auditoría de tablas se informa como
no evaluada/omitida si no existe el archivo local opcional, sin afirmar fidelidad.

## 1. Núcleo: trim, simetría y linealización

```matlab
run_tests;
verificar_simetria;
validar_A;
```

```powershell
python run_tests.py
python verificar_simetria.py
python validar_A.py
```

`run_tests` verifica nueve condiciones: trim nivelado/general, viraje,
simetría, Jacobiano, Euler/cuat, modos locales, sostenimiento de trim y
motor/atmósfera. MATLAB `validar_A` contrasta `matriz_A` con FD; Python
contrasta FD centrada de orden 2/4 del cuerpo auxiliar y su física validada
contra MATLAB. No se traducen las derivadas históricas de `legacy`.

## 2. Correcciones, formulaciones y ejecutor no lineal

```matlab
prueba_trim_refinado;
prueba_regresion_lewis;
prueba_6dof_estandarizado;
prueba_simulador_academico;
```

```powershell
python prueba_trim_refinado.py
python prueba_regresion_lewis.py
python prueba_6dof_estandarizado.py
python prueba_simulador_academico.py
```

Los nombres comunes son puntos de entrada. Las implementaciones de pruebas
son propias de cada lenguaje; Python agrupa algunas comprobaciones de su
suite. La comparación estandarizada verifica identidades físicas,
transformaciones y matrices 15/14/13/18 sin comparar coordenadas incompatibles.

## 3. Matrices, Lewis, auditoría lateral y fuentes

```matlab
prueba_calc_ABCD;
resultado = validar_lewis;
audit = auditar_lateral_lewis;
comparacion = comparar_f16_estandarizado;
sensibilidad = sensibilidad_jacobiano_6dof(comparacion);
% Opcional: requiere datos_locales/Tablas 2.xlsx con uso autorizado.
% evidencia = validar_fuentes_aerodinamicas;
```

```powershell
python prueba_calc_ABCD.py
python validar_lewis.py
python auditar_lateral_lewis.py
python comparar_f16_estandarizado.py
python sensibilidad_jacobiano_6dof.py
# Opcional: requiere datos_locales/Tablas 2.xlsx con uso autorizado.
# python validar_fuentes_aerodinamicas.py
```

El nombre histórico `prueba_calc_ABCD` imprime/calcula principalmente A13
en su punto original u=1 m/s; ese punto no es trim ni condición de vuelo
sostenido. Para A/B/C/D y el contrato común usar la auditoría estandarizada.
La auditoría lateral descompone fuerzas, momentos, inercias, CG y LEF,
evalúa tamaños de perturbación, extracción ZYX y signo del modo espiral.
La reconstrucción reducida de Lewis es un diagnóstico; no reemplaza los fits.

Los puntos publicados que no son equilibrio en el modelo local se etiquetan
como snapshots, no como modos sostenidos. El pull-up con throttle 1.023 queda
fuera del dominio [0,1]. El descenso de -5 grados puede no converger y se
conserva como diagnóstico con residuo. La frontera h=0 no posee una derivada
bilateral única del empuje. Las hojas aerodinámicas mantienen la clasificación
de fidelidad NO_VERIFICADA cuando falta procedencia/configuración.

## 4. PID de ángulo de ataque

```matlab
pruebarkf;
```

```powershell
python pruebarkf.py --mostrar --sin-video
```

El PID está en `ctrl_PID.m` / `f16py.control.pid_alpha`: elevador, realimentación
de q, saturación y anti-windup. Esta demostración reproduce el estado inicial
original: VT=170 m/s, h=3000 m, alpha/pitch=2 grados, P3=0 y throttle=0.35;
no arranca desde trim. Muestra referencia alpha, respuesta y mandos.

## 5. LQR longitudinal y lateral

```matlab
prueba_lqr;
prueba_lqr_lat;
```

```powershell
python prueba_lqr.py --mostrar --sin-video
python prueba_lqr_lat.py --mostrar --sin-video
```

Longitudinal: perturbación alpha +3 grados, elevador y throttle. Lateral:
beta +2 grados, alabeo +10 grados, con ambos lazos activos. Misma condición
de diseño y pesos; ganancias locales aplicadas sobre la planta no lineal.

## 6. Comparación de formulaciones y PID/LQR

```matlab
prueba_comparacion;
```

```powershell
python prueba_comparacion.py --mostrar --sin-video
```

Dos grupos de curvas: Euler frente a cuaterniones; no lineal abierto,
lineal abierto, lineal+PID y lineal+LQR frente a la misma perturbación.
Se conserva RK4 para la planta lineal y RKF de paso fijo para la no lineal.

## 7. Autopiloto y turbulencia

```matlab
prueba_autopiloto;
prueba_dryden;
```

```powershell
python prueba_autopiloto.py --mostrar --sin-video
python prueba_dryden.py --mostrar --sin-video
```

El autopiloto LQI sigue altitud, velocidad y rumbo con actuadores. Dryden
original contrasta abierto/LQR usando la misma realización de ruido MATLAB
exportada como entrada, no resultados precalculados como simulación. El
integrador Python recalcula ambos vuelos. La suite documenta la diferencia
entre esta demostración y los escenarios genéricos Dryden del ejecutor.

## 8. Trayectoria previa a waypoints

```matlab
prueba_trayectoria;
```

```powershell
python prueba_trayectoria.py --mostrar --sin-video
```

180 s, seis tramos de 30 s, las consignas de la semilla MATLAB 11. Python
reutiliza esas consignas como entradas y recalcula el vuelo; no asume que
NumPy y MATLAB producen el mismo ruido con el mismo número de semilla.
La ruta punteada es una referencia cinemática de h/VT/rumbo; este ensayo
no cierra directamente posición x/y.

## 9. Verificación de rutas de salida y visualización

```matlab
prueba_ruta_salida_f16;
prueba_exportacion_json_f16;
prueba_bordes_guia_f16;
prueba_visualizacion_f16;
```

```powershell
python prueba_ruta_salida_f16.py
python prueba_exportacion_json_f16.py
python prueba_bordes_guia_f16.py
python prueba_visualizacion_f16.py
```

Verifican rutas, preservación de datos, cambios de tramo, gráficas y
exportación. Estas pruebas crean archivos temporales; no borran resultados.

## 10. Ruta y avión 3D en dos vistas

```matlab
r = simular_f16_academico(struct('escenario','trayectoria', ...
    'duracion',180,'tramo',30,'semilla',11));
graficar_f16_academico(r);
animar_f16_academico(r,struct('tiempo_real',true,'velocidad',6));
```

```powershell
python prueba_trayectoria.py --mostrar
```

Vista global: ENU en kilómetros, azul vuelo integrado y punteada referencia.
Vista local: geometría docente en metros, actitud y telemetría. La geometría
no modifica la dinámica. Python guarda también la animación MP4.

## 11. Seguimiento espacial por waypoints

```matlab
prueba_waypoints_f16;
prueba_paso_waypoints_f16;
r_waypoints = ejecutar_waypoints_f16;
graficar_f16_academico(r_waypoints);
animar_f16_academico(r_waypoints,struct('tiempo_real',true,'velocidad',6));
```

```powershell
python prueba_waypoints_f16.py
python prueba_paso_waypoints_f16.py
python ejecutar_waypoints_f16.py --mostrar
```

Waypoints NED [Norte,Este,Abajo] en metros; h=-Abajo. El guiado produce
rumbo/altitud/velocidad para el autopiloto. Captura final a 250 m; no significa
que el avión se detenga ni aterrice. No se garantiza cualquier ruta arbitraria.

## 12. Corrida integral con resultados guardados

```matlab
resumen = ejecutar_guia_f16;
```

```powershell
python ejecutar_guia_f16.py
```

Validaciones, cuatro demostraciones originales y diez escenarios:
nivelado, lateral_abierto, longitudinal_abierto, lateral_lqr, viraje,
ascenso, autopiloto, trayectoria, dryden_abierto y dryden_lqr. Waypoints
se ejecuta aparte. Esta corrida repite varios pasos anteriores; es una
alternativa para exportar el conjunto, no un requisito antes de ver 3D.

Python permite listar exactamente los 28 puntos de entrada:

```powershell
python pasos.py --listar
```

## Resultados guardados y reapertura

| Acción | MATLAB | Python |
|---|---|---|
| Corrida integral | Carpeta nueva, MAT/CSV/JSON/PNG/MP4 | Carpeta nueva, NPZ/CSV/JSON/PNG/MP4 |
| Waypoints | `ejecutar_waypoints_f16` exporta | `python ejecutar_waypoints_f16.py` exporta |
| Demostraciones originales | Abren figuras; guía integral guarda copias legacy | Cada entrada `.py` exporta registro estandarizado y gráficas |
| Auditorías | Sin carpeta, calculan en memoria; con carpeta, exportan | Entradas `.py` exportan JSON en carpeta nueva |
| Simular desde API | `simular_f16_academico` devuelve `r` | `simulate` devuelve `r` |
| Gráficas desde API | `graficar_f16_academico(r)` | `plots(r)` |
| Animar desde API | `animar_f16_academico(r,op)` | `animate(r,show=True)` |

Para reabrir el registro estandarizado, sustituye por tu ruta real:

```matlab
ver_simulacion_f16('ruta_del_ensayo/registro.mat');
```

```powershell
python ver_simulacion_f16.py "ruta_del_ensayo/registro.npz"
```

MATLAB `original_prueba_*/registro.mat` contiene `d` (demostración legacy),
no el registro `r` esperado por el visor. Usa `lateral_lqr/registro.mat`,
`autopiloto/registro.mat`, etc. Python genera `r` estandarizado también para
sus demostraciones originales. El visor Python lee NPZ, no MAT legacy.
No incluyas comillas dobles dentro de una cadena MATLAB entre comillas simples.

Para guardar una corrida manual MATLAB:

```matlab
carpeta = ['mi_vuelo_' datestr(now,'yyyymmdd_HHMMSS')];
assert(~exist(carpeta,'file'),'La carpeta ya existe.');mkdir(carpeta);
save(fullfile(carpeta,'registro.mat'),'r','-v7.3');
```

En Python puede elegirse `--salida carpeta_nueva`. Se rechaza una carpeta
existente. `--sin-video` evita exportar MP4; `--mostrar` abre figuras.
Las demostraciones admiten `--duracion` para ensayos cortos; la validación
de paridad usa los horizontes originales. No sobrescribir evidencia previa.

## Funciones auxiliares y convenciones

Los módulos `Cx/Cy/Cz/Cl/Cm/Cn`, incrementos, `hu/fa/fm/flef`, integrador,
trim, linealización, PID/LQR, guiado, pose y exportación reciben argumentos:
los llaman los ejecutores. Equivalentes Python: `f16py/fits.py`,
`aerodynamics.py`, `dynamics.py`, `control.py`, `guidance.py`, `audit.py`,
`demonstrations.py`, `io.py` y `visualization.py`. No se ejecutan en secuencia.
`legacy/`, respaldos y auxiliares de exportación de referencias son historial
y herramientas de desarrollo, no pasos de vuelo.

15 estados: P3,alfaf,VT,alpha,beta,p,q,r,q0,q1,q2,q3,N,E,D.
Euler: 14; cuerpo auxiliar: 13 sin empuje/motor y alfaf congelado;
con actuadores: 18 (añade de_real,da_real,dr_real). Cuerpo completo de auditoría
reincorpora explícitamente motor/LEF/empuje para verificar la misma física.
SI; ángulos rad, tasas rad/s; superficies/alfaf/LEF en grados. Cuerpo x
adelante,y derecha,z abajo; actitud ZYX, cuaternión escalar primero.
Controles [de,da,dr,dth]; límites ±25,±21.5,±30 grados, throttle [0,1], LEF [0,25].
Python indexa desde cero; registros nuevos tienen muestras en filas.

## Validación de paridad y alcance

```powershell
python -m unittest discover -s tests -v
python validar_paridad.py --salida validacion_paridad_nueva
python validar_replica.py --salida validacion_vuelos_nueva --video
```

Las referencias nuevas se obtuvieron ejecutando MATLAB: PID, longitudinal,
comparación, Dryden, auditorías y hojas. Las anteriores contrastan ajustes,
20 casos combinados, matrices y tres vuelos. Las tolerancias y resultados
se resumen en [docs/VALIDACION.md](docs/VALIDACION.md). Las tablas originales
quedan como auditoría local opcional, separada de las referencias generadas.
El algoritmo de trim es SciPy least_squares frente al solver MATLAB;
Riccati usa SciPy frente a MATLAB. No se promete identidad bit a bit.

La planta conserva los ajustes aerodinámicos del proyecto y sus discrepancias
con la versión reducida de Lewis. El error normalizado cercano al 20% de
las hojas auditadas no es el error de trayectoria ni de toda la planta.
Uso académico: dinámica, linealización, diseño preliminar, sensibilidad y
visualización. No es validación empírica del F-16 real ni certificación.

## Documentación y contribuciones

- [Fuentes y datos locales](docs/DATOS_Y_FUENTES.md), [alcance y limitaciones](docs/LIMITACIONES.md) y [cómo citar](docs/CITACION.md).
- [Validación común](docs/VALIDACION.md), evidencia de los laboratorios [Python](docs/RESULTADO_LABORATORIO.md) y [MATLAB](docs/RESULTADO_LABORATORIO_MATLAB.md).
- [Referencias numéricas](docs/REFERENCIAS_NUMERICAS.md) y [contrato del laboratorio](docs/CONTRATO_LABORATORIO.md).
- [Contribuir](CONTRIBUTING.md) y [licencia MIT](LICENSE), comunes para el proyecto.

Las [pruebas de GitHub Actions](https://github.com/LuisAngelOlveraOlvera/F16_AICRAFT_CONTROL_AND_SIMULATION_DYNAMICS/actions) comprueban Python y MATLAB. Sus resultados se revisan por commit y se distinguen de la validación local. No se distribuyen libros, PDFs, tablas originales ni resultados personales.
