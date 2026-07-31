## Orden de ejecución

Para reproducir las simulaciones, los siguientes scripts deben ejecutarse en el orden indicado, ya que cada uno depende de los archivos generados por el anterior:

1. **`generateDensityMap.m`**
   Genera los mapas de densidad (speckle) utilizados como medio de fondo en las simulaciones. Los resultados se almacenan en `densityMaps/<nombre_phantom>/`.

2. **`simulateBgnd6_copia.m`**
   Simula el phantom homogéneo de referencia (sin inclusión) mediante k-Wave, incluyendo angulación de haz (steering). El RF crudo generado se guarda en `TAREA_v2/<nombre_phantom>/.../rf/`.

3. **`simulateInc9_copia.m`**
   Simula el phantom con inclusión (muestra), también con angulación de haz. El RF crudo generado se guarda en `TAREA_v2/<nombre_phantom>/.../rf/`.

4. **`beamform_to_bf.m`**
   Aplica beamforming DAS (mediante la función `bfPlaneWaveSimu.m`) sobre el RF crudo generado en los pasos 2 y 3, y guarda los resultados beamformados en las subcarpetas `bf/` correspondientes.

5. **`BA_COMPUTE_DM_FINAL.m`**
   Calcula el mapa de B/A (no linealidad acústica) mediante el Método de Depleción a partir de los datos beamformados, y genera las visualizaciones correspondientes (mapa de B/A y B-mode).

## Consideraciones antes de ejecutar

Es necesario tener instalado el [k-Wave Toolbox](http://www.k-wave.org/) y agregado al path de MATLAB.

Las rutas de las carpetas están definidas según la estructura de carpetas de mi computadora, por lo que **es necesario cambiarlas manualmente en cada script** antes de ejecutar el código. Los lugares donde hay que hacer el cambio son:

**En `generateDensityMap.m`:**
```matlab
outputDir = fullfile(pwd, 'densityMaps', sample);
pwd toma automáticamente la carpeta desde donde se ejecuta el script en MATLAB, por lo que basta con ubicarse (cd) en la carpeta del proyecto antes de correrlo.
```
En simulateBgnd6_copia.m y simulateInc9_copia.m:
```densityDir = fullfile(pwd, 'densityMaps', sample);
outputDir  = fullfile(pwd, 'TAREA_v2', sample, probe, freqStr, 'rf');
Igual que el caso anterior, dependen de pwd, así que solo hay que asegurarse de correr el script desde la carpeta raíz del proyecto.
```
En beamform_to_bf.m:
```baseDir = 'C:\Users\FRANCO PERALTA\Documents\MATLAB\LIM\TAREA_v2';
Esta ruta es absoluta y debe reemplazarse por la ruta local de cada computadora, por ejemplo:
baseDir = 'C:\Users\NombreDeUsuario\Ruta\Del\Proyecto\TAREA_v2';
```
En BA_COMPUTE_DM_FINAL.m:
```refDir = 'C:\Users\FRANCO PERALTA\Documents\MATLAB\LIM\TAREA_v2\Phantom_homo_BA6_Steering15_v2\L14-5u\7MHz\bf';
samDir = 'C:\Users\FRANCO PERALTA\Documents\MATLAB\LIM\TAREA_v2\Phantom_inc_BA11_Steering15_v2\L14-5u\7MHz\bf';
Estas dos rutas también son absolutas y deben actualizarse según la ubicación del proyecto en cada computadora, por ejemplo:
refDir = 'C:\Users\NombreDeUsuario\Ruta\Del\Proyecto\TAREA_v2\Phantom_homo_BA6_Steering15_v2\L14-5u\7MHz\bf';
samDir = 'C:\Users\NombreDeUsuario\Ruta\Del\Proyecto\TAREA_v2\Phantom_inc_BA11_Steering15_v2\L14-5u\7MHz\bf';
```
## Nota sobre GPU

Los scripts de simulación (`simulateBgnd6_copia.m`, `simulateInc9_copia.m`) utilizan por defecto:

```matlab
dataCast = 'gpuArray-single';

lo cual acelera la simulación mediante una GPU NVIDIA compatible con CUDA. Si la computadora en la que se ejecutará el código no cuenta con GPU NVIDIA, esta línea debe modificarse a:

dataCast = 'single';

para que la simulación se ejecute en CPU (el tiempo de cómputo será considerablemente mayor).
```