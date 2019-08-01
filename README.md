# lms-equalizer

Ecualizador LMS implementado en RTL

## Objetivo

Implementar en FPGA un ecualizador adaptativo utilizando los conocimientos adquiridos en el Curso de Diseño Digital Avanzado

## Estructura 

El trabajo se estructura en una serie de directorios listados a continuación:

* **cpp**: Software para el micro-procesador.
* **python**: Script para comunicar por el puerto UART la PC con la FPGA.
* **rtl**: Entorno de verificación.
* **sim**: Simulador en python que se utiliza para entender el comportamiento del filtro adaptivo.

En particular, el código del ecualizador se encuentra en el directorio [rtl/dsp](./rtl/dsp). En la siguiente figura vemos un diagrama del sistema a implementar:

![dsp]

En esta figura, se ven anchos de palabra no definidos. Por medio de los scripts de simulación provistos en el directorio [sim](./sim), se pudo estimar los anchos requeridos para cada bus:

* salida de FFE    : signed (9,7)
* salida de slicer : signed (8,7)
* señal de error   : signed (8,7)
* coeficientes     : signed (9,7) 

Se pudo ver en las simulaciones que:
* La salida del filtro siempre se encuentra dentro del rango [-2,2), por lo tanto con 2 bits de parte entera es suficiente.
* Tanto el error como la señal de slicer, nunca pueden superar el rango [-1,1), por lo tanto, con 1 bit de parte entera es suficiente.
* Los valores que van tomando los coeficientes, tampoco nunca superan  el rango [-2,2), por lo tanto, con 2 bits de parte entera es suficiente.

En cualquier caso, si por alguna condición numérica excepcional se supera el rango previsto, existe una lógica de saturación que previene el *wrapping*. 

## Descripción de FFE

La arquitectura del Feed Forward Equalizer (FFE) se puede ver en la siguiente figura:

![ffe]

En particular, se usó una forma directa para la estructura del filtro FIR y se implementó un árbol de sumas para que sea sencillo agregar registros de pipeline en una etapa subsecuente. A la salida, hay una lógica de saturación y truncado que ajusta la palabra de S(23,14) a S(9,7). Experimentalmente se encontró donde conviene hacer el corte para minimizar el error de precisión numérica.

## Descripción del LMS

La arquitectura del Least Mean Squares (LMS) se puede ver en la siguiente figura:

![lms]

## Simulación

La simulación se realizó con [cocotb](https://github.com/cocotb/cocotb) y se compararon los resultados con los de la simulación en Python. Para ejecutar los tests, posicionarse en el directorio [rtl/dsp/sim](./rtl/dsp/sim) y hacer

```
$ make
$ make gtkwave
```

Los siguientes gráficos muestran diferentes simulaciones para distintos canales y distintos pasos de adaptación.

**Aclaración**: las imágenes que dicen "HW", se refieren a RTL, mientras que las otras son simuladas con Python

### Canal 0 y mu = 2e-7

![hw-chan0-step1]
![py-chan0-step1]

### Canal 0 y mu = 2e-3

![hw-chan0-step16]
![py-chan0-step16]

### Canal 1 y mu = 2e-7

![hw-chan1-step1]
![py-chan1-step1]

### Canal 1 y mu = 2e-3

![hw-chan1-step16]
![py-chan1-step16]

### Canal 2 y mu = 2e-7

![hw-chan2-step1]
![py-chan2-step1]

### Canal 2 y mu = 2e-3

![hw-chan2-step16]


![py-chan2-step16]

### Canal 3 y mu = 2e-7

![hw-chan3-step1]
![py-chan3-step1]

### Canal 3 y mu = 2e-3

![hw-chan3-step16]
![py-chan3-step16]

Se puede ver que en general los resultados del hardware son coherentes con los simulados. En el caso del canal 3 y mu = 2e-3, la precisión numérica utilizada resulta insuficiente, por lo cual se ve como el error no logra converger adecuadamente. Una solución propuesta para este caso sería ampliar la precisión numérica de la salida del filtro.

### Evolución de coeficientes para canal 1 y mu = 2e-5

####Hardware
![hw-coefs-chan1-step2]

####Simulación
![py-coefs-chan1-step2]

## Síntesis

Una vez obtenidos los resultados deseados en simulación, se procedió a implementar el sistema completo en FPGA. Al no cumplir con el timing, como era previsible, se procedió a insertar registros en diferentes paths para que el sistema pueda correr con el clock esperado. En los siguientes gráficos se puede ver dónde fueron insertados los registros que finalmente permitieron cumplir con los constraints de timing.

![ffe_pipe]

![lms_pipe]

Al insertar dos registros en el árbol de sumas, la salida del FFE se atrasa 2 clocks, con lo cual debe atrasarse la entrada de datos del LMS. Por otro lado, al insertar un registro en el cálculo de error del LMS, también debe atrasarse la entrada de datos para mantener la coherencia. Es importante que se mantenga la coherencia entre el error y los valores presentes en los taps del filtro, que son los mismos que generan el mencionado error.
Al demorar la carga de los nuevos coeficientes en el filtro, tenemos una versión de LMS llamada "Delayed LMS" o DLMS, que posee como desventaja la pérdida de velocidad de adaptación frente a cambios rápidos de canal. La ventaja es que al agregar etapas de pipeline, se puede incrementar la frecuencia del clock del sistema.

### Resultados de implementación

#### Utilización de recursos

| Name                            | Slice LUTs | Slice Registers | F7 Muxes | F8 Muxes | Slice | LUT as Logic | LUT as Memory | Block RAM Tile | DSPs   |
|---------------------------------|------------|-----------------|----------|----------|-------|--------------|---------------|----------------|--------|
| fpga                            | 9.09%      | 4.93%           | 0.68%    | 0.00%    | 9.88% | 8.43%        | 1.43%         | 4.93%          | 72.00% |
| dsp_inst (dsp)                  | 1.38%      | 0.56%           | 0.00%    | 0.00%    | 1.79% | 1.38%        | 0.00%         | 0.56%          | 56.00% |
| u_fir_channel (fir_channel)     | 0.16%      | 0.10%           | 0.00%    | 0.00%    | 0.26% | 0.15%        | 0.01%         | 0.10%          | 0.00%  |
| u_micro (design_1)              | 7.42%      | 4.04%           | 0.68%    | 0.00%    | 7.69% | 6.77%        | 1.42%         | 4.04%          | 16.00% |
| u_prbsx (prbsx)                 | <0.01%     | 0.02%           | 0.00%    | 0.00%    | 0.04% | <0.01%       | 0.00%         | 0.02%          | 0.00%  |
| u_register_file (register_file) | 0.10%      | 0.19%           | 0.00%    | 0.00%    | 0.67% | 0.10%        | 0.00%         | 0.19%          | 0.00%  |

#### Timing

![timing]

#### Floorplan

![floorplan]

## Dificultades encontradas

Tuvimos dificultades en los siguientes puntos:

* No nos había quedado claro que podíamos retrasar los coeficientes para mejorar las prestaciones de timing del sistema. Esto nos ocasionó demoras, ya que empezamos probando el filtro en forma transpuesta, que tiene mejor desempeño en timing que el de forma directa. Lo que hay que tener en cuenta en ese caso, es que los coeficientes provenientes del LMS deben cargarse con un delay incremental para cada coeficiente. Es decir, el coeficiente 0 sin delay, el coeficiente 1 con un delay de 1, el coeficiente 2 con uno de 2, etc. Finalmente, optamos por un filtro en forma directa, que simplifica el desarrollo.

* En el enunciado, la fórmula del error dice e[n] = y[n] - ŷ[n]. Esto no es correcto, la señal de error se debe calcular como e[n] = ŷ[n] - y[n]. Esto causaba que el filtro arrancara bien, pero luego divergiera estupendamente, como es de suponer, ya que el signo del error está al revés.

* Sin el pipeline, no nos era posible cumplir con los timing constraints. Aunque fue una dificultad, no fue imprevista, ya que podía apreciarse que el lazo combinacional no era menor.

[dsp]: img/dsp.png
[ffe]: img/FFE.png
[ffe_pipe]: img/FFE_pipeline.png
[lms]: img/LMS.png
[lms_pipe]: img/LMS_pipeline.png

[hw-chan0-step1]: img/hw-chan0-step1.png
[hw-chan0-step16]: img/hw-chan0-step16.png
[hw-chan1-step1]: img/hw-chan1-step1.png
[hw-chan1-step16]: img/hw-chan1-step16.png
[hw-chan2-step1]: img/hw-chan2-step1.png
[hw-chan2-step16]: img/hw-chan2-step16.png
[hw-chan3-step1]: img/hw-chan3-step1.png
[hw-chan3-step16]: img/hw-chan3-step16.png
[py-chan0-step1]: img/py-chan0-step1.png
[py-chan0-step16]: img/py-chan0-step16.png
[py-chan1-step1]: img/py-chan1-step1.png
[py-chan1-step16]: img/py-chan1-step16.png
[py-chan2-step1]: img/py-chan2-step1.png
[py-chan2-step16]: img/py-chan2-step16.png
[py-chan3-step1]: img/py-chan3-step1.png
[py-chan3-step16]: img/py-chan3-step16.png

[hw-coefs-chan1-step2]: img/hw-coefs-chan1-step2.png
[py-coefs-chan1-step2]: img/py-coefs-chan1-step2.png

[floorplan]: reports/device.png
[timing]: reports/timing.png