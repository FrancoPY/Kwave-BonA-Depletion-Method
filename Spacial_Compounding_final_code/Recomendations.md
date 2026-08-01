## Instrucciones previas: generación de mapas de densidad

Antes de ejecutar los tres scripts de simulación (`simulateHomoBA6_AllAngles_v3.m`, `simulateIncBA9_AllAngles_v3.m`, `simulateIncBA11_AllAngles_v3.m`), es necesario generar los mapas de densidad correspondientes a cada phantom utilizando el script `generateDensityMap.m`.

- Ubicación de trabajo en MATLAB

Antes de ejecutar cualquier script (tanto `generateDensityMap.m` como los tres scripts de simulación), es indispensable que el directorio de trabajo actual de MATLAB (`pwd`) sea la **carpeta raíz del proyecto**, es decir, la carpeta que contiene tanto `generateDensityMap.m` como la subcarpeta `TAREA_v3` (como en mi caso).

Esto es necesario porque todos los scripts guardan y leen archivos usando rutas relativas a `pwd` (por ejemplo, `densityMaps/` y `TAREA_v3/`), independientemente de en qué subcarpeta esté guardado el archivo `.m` que se está ejecutando ni de cómo se llame esa carpeta raíz en cada computadora.

- Ejecución de generateDensityMap.m

El script generateDensityMap.m debe ejecutarse tres veces, una por cada phantom, cambiando manualmente el valor de la variable sample (línea 3 del script) antes de cada ejecución, de la siguiente manera:

Primera ejecución:
sample = 'Phantom_homo_BA6_v3';

Segunda ejecución:
sample = 'Phantom_inc_BA9_bg6_v3';

Tercera ejecución:
sample = 'Phantom_inc_BA11_bg6_v3';


- Número de frames

El script generateDensityMap.m tiene por defecto nFrames = 6. Los tres scripts de simulación en TAREA_v3 solo requieren nFrames = 4, así que es mejor cambiarlo
