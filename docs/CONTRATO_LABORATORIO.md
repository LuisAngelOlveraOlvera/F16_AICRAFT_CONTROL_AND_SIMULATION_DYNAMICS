# Contrato del laboratorio académico, versión 1

Python y MATLAB tienen motores visuales independientes, con la misma organización y entradas equivalentes. No se utiliza MATLAB Engine ni una interfaz compartida de cálculo. Puntos de entrada: `python/laboratorio_f16.py` y `matlab/lab_f16_app.m`.

La pestaña Estados presenta nueve paneles físicos con referencias y selección temporal compartida con el vuelo. Ambas vistas consumen registros calculados y mantienen los defaults de sus implementaciones originales.

## Entrada

JSON con `contrato: 1`, `perfil` y `opciones`. Perfiles: pid, lqr_longitudinal, lqr_lateral, comparacion, autopiloto, dryden_original, trayectoria_original, waypoints, generico. Valores originales definidos por experimento en `python/f16py/laboratory/profiles.py` y `matlab/+f16lab/defaults.m`, documentados en sus respectivas GUIA_LABORATORIO.

Se conserva una diferencia previa: autopiloto MATLAB original dura 60 s y usa prefiltros exponenciales desde t=0; Python usa 40 s y referencias del ejecutor académico desde t=5. La trayectoria original MATLAB conserva el registro `ref_hist`, además de la referencia realmente aplicada. Para comparar usar modo personalizado con las mismas entradas; cargar una configuración original de otra implementación puede ser rechazado si sus defaults nativos difieren. Compartir una semilla no iguala generadores de ruido diferentes.

Opciones comunes: original (booleano), escenario, duracion/paso [s], VT [m/s], altitud [m], semilla, tramo [s], anticipacion_m, radio_captura_m, waypoints [[N,E,h]] [m] y posicion_inicial [N,E,h] opcional. La presentación usa altitud positiva; la planta mantiene D=-h.

Grupos avanzados:
- initial: alpha_deg/beta_deg/phi_deg/theta_deg/psi_deg y p_deg_s/q_deg_s/r_deg_s, perturbaciones.
- pid: kp/ki/kq, alpha_ref_deg/alpha_initial_deg, throttle.
- weights: q_lon/r_lon/q_lat/r_lat, factores positivos de matrices originales.
- reference: delta_h_m/delta_v_m_s/delta_psi_deg/time_s; h_rate_m_s/v_rate_m_s2/psi_rate_deg_s; gamma_deg/turn_deg_s; trayectoria_h_m/trayectoria_rumbo_deg.
- turbulence: sigma_u/v/w [m/s] y length_u/v/w [m].
- manual: elevador_deg/aleron_deg/timon_deg/throttle/time_s.

Campos ajenos al escenario no aceptan cambios. Original conserva el cálculo y los parámetros de cada práctica de README; MATLAB utiliza adaptadores verificados contra sus scripts para evitar que `clear`/`close all` destruyan la ventana. Solo horizonte/paso se admiten como ajustes y las fuentes de referencia fijan restricciones adicionales. Límites actuales VT 100–200, h 0–10000, 0<dt<=0.02, duración múltiplo de dt. Máximo UI 500000 pasos para limitar consumo local, no límite físico del modelo.

## Salida

Registros nativos existentes `t`, `X` (15/18 estados), mandos, referencias, fuerzas, momentos, métricas y navegación. Se añade `laboratorio` con perfil, modo, opciones completas, implementación, versión de contrato y hashes de fuentes/refencias utilizadas. Datos calculados independientes de formularios y de A/B.

Comparar MATLAB/Python usando magnitudes físicas, convenciones de ejes y unidades comunes, tolerancias documentadas y entradas de ruido/consignas idénticas. La igualdad de interfaces no exige igualdad bit a bit de solucionadores distintos.

MATLAB guarda resultados en MAT, CSV y JSON; Python en NPZ, CSV y JSON. Los archivos de resultados son nativos, no se cargan cruzadamente desde las ventanas. Las configuraciones personalizadas JSON comparten esquema y unidades.
