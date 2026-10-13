# F-16 Aircraft Control and Simulation Dynamics

Simulador académico no lineal F-16 de 6 DOF, con implementaciones en MATLAB y Python. Incluye trim, linealización, análisis modal, control PID/LQR, autopiloto, turbulencia, seguimiento por waypoints, gráficas y animación 3D.

## Elegir una implementación

| Carpeta | Instrucciones completas | Requisitos |
|---|---|---|
| [matlab](matlab/) | [Orden de ejecución MATLAB y Python](matlab/README.md) | MATLAB R2024a y toolboxes indicados |
| [python](python/) | [Orden de ejecución MATLAB y Python](python/README.md) | Python 3.12; dependencias incluidas |

Los dos README conservan el mismo orden didáctico. Ejecutar los comandos desde la carpeta de la implementación elegida; los auxiliares reciben argumentos y los llaman los ejecutores.

## Inicio rápido

MATLAB, desde `matlab/`:
```matlab
verificar_publicacion
ejecutar_guia_f16
ejecutar_waypoints_f16
```

Python, desde `python/`, en un entorno virtual:
```console
python -m pip install -r requirements-tested.txt
python verificar_publicacion.py
python ejecutar_guia_f16.py
python ejecutar_waypoints_f16.py
```

- **Primera ejecución o después de modificar código:** ejecutar las pruebas del núcleo y adicionales, o el verificador de publicación.
- **Experimentación:** elegir PID, LQR, autopiloto, turbulencia o trayectoria en el README de cada implementación.
- **Ejecución completa con resultados guardados:** `ejecutar_guia_f16`; para seguimiento espacial, `ejecutar_waypoints_f16`, con extensión `.py` en Python.

Las instrucciones para reabrir registros y visualizar rutas/actitud 3D están en ambos README. Los resultados se generan localmente y quedan fuera del control de versiones.

## Alcance y evidencia

Ejes cuerpo x adelante, y derecha, z abajo; actitud ZYX y cuaternión escalar primero. Unidades SI, ángulos en radianes y superficies/LEF en grados. Modelo principal de 15 estados; con actuadores, 18. Véanse las convenciones completas en los README.

La comparación MATLAB/Python comprueba la reproducción del mismo modelo. No demuestra fidelidad al avión real ni coincidencia exacta con Lewis. Se conservan las diferencias de modelo, condiciones y ajustes documentadas: no se modificaron coeficientes para forzar polos de referencia.

Los datos originales XLSX y los PDF no están incluidos. La auditoría específica que los necesita se informa como no evaluada cuando faltan; las pruebas de dinámica y paridad siguen activas. `python/references/` contiene fixtures numéricos necesarios para reproducir pruebas y escenarios, no los libros ni las tablas originales.

Consulta [fuentes y datos](python/docs/DATOS_Y_FUENTES.md), [limitaciones](python/docs/LIMITACIONES.md) y [validación](python/docs/VALIDACION.md).

## Derechos y contribuciones

Código abierto bajo [licencia MIT](LICENSE): permite utilizar, modificar y redistribuir el código, incluso comercialmente, conservando el aviso de copyright y la licencia. Se entrega sin garantías. Los materiales de terceros conservan sus derechos propios; la licencia no resuelve su titularidad. No se distribuyen PDFs o tablas originales. Las referencias bibliográficas y condiciones de los datos se documentan en cada implementación.

Las pruebas automatizadas de GitHub Actions se encuentran en [Actions](https://github.com/LuisAngelOlveraOlvera/F16_AICRAFT_CONTROL_AND_SIMULATION_DYNAMICS/actions). Su resultado debe revisarse por separado de la validación local.

## Laboratorio visual Python

Interfaz de escritorio independiente con ocho pestañas: avión, simulación,
condiciones iniciales, control, ruta, turbulencia, comparación y vuelo/resultados.
Los puntos de entrada y configuraciones originales de ambos README se conservan.
Cada perfil abre sus valores originales; los ensayos personalizados son explícitos.

Desde `python/`:

```powershell
python laboratorio_f16.py
```

En Windows también se puede abrir `python/ABRIR_LABORATORIO.bat`.
Ver [guía del laboratorio](python/GUIA_LABORATORIO.md) y
[contrato común para MATLAB/Python](docs/CONTRATO_LABORATORIO.md).
Implementación inicial Python; el motor visual MATLAB se desarrollará por separado.
