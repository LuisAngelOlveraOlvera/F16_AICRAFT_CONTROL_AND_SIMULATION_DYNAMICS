# Laboratorio F-16 Python

Ejecutar desde esta carpeta:

```powershell
python laboratorio_f16.py
```

En Windows también se puede abrir `ABRIR_LABORATORIO.bat`. Utilizar el mismo Python y dependencias de `requirements-tested.txt`. Tkinter debe estar instalado; viene con el instalador Python habitual en Windows. En Linux puede requerir el paquete Tk de la distribución. Los comandos del README siguen siendo puntos de entrada independientes.

## Empezar con la configuración original

1. Elegir el experimento de la lista superior. Se cargan sus valores originales.
2. Mantener marcada **Configuración original README** y pulsar **Simular**.
3. El cálculo ocurre en un proceso independiente. **Cancelar** lo detiene conservando registros anteriores. Al terminar se abre **Estados**, con nueve gráficas simultáneas del ensayo.
4. En **Vuelo y resultados**, reproducir, mover el tiempo o cambiar la cámara. Arrastrar sobre el avión rota la vista; la barra de Matplotlib permite explorar las figuras.
5. En **Comparación**, guardar B como A. Desactivar el modo original, cambiar una opción habilitada y simular B. Ambos registros conservan sus condiciones; modificar un formulario no modifica un resultado ya calculado.
6. **Restaurar original** recupera el perfil seleccionado, no una configuración global.

| Perfil | Duración original | Condiciones especiales |
|---|---:|---|
| PID alfa | 15 s | Estado original fuera de trim; Kp=5, Ki=1.5, Kq=0.8, throttle=0.35 |
| LQR longitudinal | 20 s | Perturbación alfa +3° |
| LQR lateral | 15 s | Beta +2°, alabeo +10° |
| Comparación | 15 s | Euler/cuat y respuestas lineal/PID/LQR originales |
| Autopiloto | 40 s | Cambio h +100 m y rumbo +20° desde t=5 s |
| Dryden original | 30 s | Abierto y LQR; serie de ruido MATLAB existente |
| Trayectoria original | 180 s | Consignas de referencia existentes; tramos de 30 s |
| Waypoints | 180 s | Ruta original de cuatro puntos |

Todos los perfiles anteriores usan VT=170 m/s, altitud=3000 m y paso=0.002 s. El perfil **Escenarios del ejecutor académico** es personalizado y permite elegir escenarios adicionales, incluido mando manual. Los horizontes original Dryden y trayectoria no se extienden más allá de sus referencias; cambiar a personalizado permite nuevos experimentos.

## Pestañas

- **Avión:** masa, peso calculado, gravedad, superficie, envergadura, cuerda, CG y referencias relativas a la cuerda, Ix/Iy/Iz/Ixz y momento angular del motor. Lectura desde los parámetros de la planta. Geometría docente; longitud/altura reales no documentadas se identifican como no disponibles.
- **Simulación:** condiciones, duración, paso, semilla, intervalo de consignas y guardar/cargar configuración JSON.
- **Condiciones iniciales:** perturbaciones respecto al trim (o respecto al estado base del PID). En comparación solo alfa se aplica, por definición del experimento.
- **Control:** ganancias PID; factores positivos de los pesos originales Q/R de LQR/LQI; cambios y límites de referencia; ascenso/viraje; amplitudes aleatorias de trayectoria; mandos manuales con límites físicos actuales. Se habilitan únicamente campos aplicables.
- **Ruta:** tabla N/E/altitud positiva, añadir/actualizar/eliminar/ordenar puntos y plano editable por selección. Pulsar en el plano rellena N/E del editor; aplicar con Añadir o Actualizar. La altitud inicial debe coincidir con trim. Conversión a NED interna.
- **Turbulencia:** sigma por componente y longitudes de escala. La generación local sigue siendo Dryden simplificado. Para paridad futura MATLAB/Python se necesitan entradas de ruido comunes, no solamente una semilla idéntica.
- **Estados:** nueve paneles de altitud, velocidad, alfa/beta, alabeo/cabeceo, rumbo, p/q/r, potencia del motor, filtro/deflexión LEF y posición Norte/Este. Incluye referencias de h/VT/rumbo y alfa cuando el ensayo las registra. La actitud se presenta en Euler a partir del registro; no se muestran aquí las cuatro componentes del cuaternión ni los estados internos de actuadores. Cursor temporal compartido con el vuelo: reproducir, deslizar el tiempo o pulsar una gráfica. Seleccionar un ensayo en cualquiera de las dos pestañas actualiza ambas. Zoom y desplazamiento con la barra Matplotlib; al activar estas herramientas, pulsar la gráfica no cambia el tiempo. Las curvas largas se reducen a un máximo de 2500 puntos solo para visualización; el registro original permanece completo.
- **Comparación:** A/B, variables, referencias y métricas RMS respecto a la referencia de cada ensayo. Comparar mismas condiciones antes de atribuir diferencias a un controlador.
- **Vuelo y resultados:** trayectoria y actitud 3D calculadas, tiempo, velocidad de reproducción, cámara, telemetría y exportación.

**Guardar ensayo** crea una nueva subcarpeta con NPZ (sin pickle), CSV y métricas JSON. La configuración completa y hashes de fuentes quedan dentro del registro NPZ. **Guardar configuración** escribe un JSON nuevo y rechaza sobrescritura. Se pueden cargar registros NPZ como A o B sin recalcularlos.

## Alcance

El modo personalizado conserva aerodinámica, ecuaciones y RKF del proyecto; no permite modificar masa, geometría física, inercias ni ajustes aerodinámicos. Q/R se editan por factores longitudinales/laterales, no como matrices arbitrarias. No es pilotaje interactivo durante la integración: las opciones se fijan antes de calcular y la reproducción ocurre después. No se afirma fidelidad certificada al F-16 real.

Las pruebas de escritorio se omiten si no hay display Tk; el resto de la suite numérica sigue activo. Prueba del proceso real y capturas de la ventana propia:

```powershell
python tools/validar_laboratorio.py
python tools/validar_laboratorio.py --capturar
```

Las capturas y ensayos se generan dentro de `resultados/`, fuera de Git.
