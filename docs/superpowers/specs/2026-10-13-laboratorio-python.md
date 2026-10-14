# Laboratorio académico Python

Autorizado en la conversación: implementar primero Python, con motor visual independiente y paridad funcional futura con MATLAB. Los README existentes siguen funcionando y cada experimento inicia con su configuración original, no con un default global.

Aplicación de escritorio Tkinter/Matplotlib, sin servicios externos ni nuevas dependencias. Pestañas Avión, Simulación, Condiciones iniciales, Control, Ruta, Turbulencia, Comparación y Vuelo/resultados. Los parámetros del avión son de consulta; se muestran valores del modelo y datos ausentes explícitamente. Geometría docente no se presenta como dimensiones certificadas.

Los perfiles README ejecutan las funciones originales con sus entradas originales: PID 15 s, LQR longitudinal 20 s, LQR lateral 15 s, comparación 15 s, autopiloto 40 s, Dryden original 30 s (ruido de referencia), trayectoria original 180 s (consignas de referencia), waypoints 180 s. Perfil editable adicional para escenarios genéricos. Restaurar recupera cada perfil, incluidos modo original, parámetros y fuentes de ruido/consignas.

Opciones avanzadas se aplican únicamente a ensayos personalizados; ecuaciones, aerodinámica y RKF existentes siguen siendo autoridad. PID configurable Kp/Ki/Kq; LQR/LQI factores positivos Q/R; perturbaciones respecto al trim; referencias autopiloto; Dryden sigma/L/semilla; waypoints N/E/altitud positiva convertidos a NED. Sin cambios de masa/inercia.

Simulación en proceso secundario cancelable, UI sensible, resultados A/B con metadatos y exportación NPZ/CSV/JSON sin sobrescritura. Reproducción 3D y gráficas en el hilo principal, selección temporal y cámaras. Los errores no sustituyen resultados válidos. Cambiar configuración no altera un registro calculado.

Validación: suite previa y posterior, igualdad directa/interfaz para todos los perfiles, opciones inválidas, cancelación y errores, restauración, exportación, ejecución real de interfaz con prueba de interacción. GitHub no se modifica ni publica automáticamente.
