# lms-equalizer
Ecualizador LMS implementado en RTL

# Objetivo

Implementar en FPGA un ecualizador adaptativo utilizando los conocimientos adquiridos en el Curso de Diseño Digital Avanzado

# Estructura 

El trabajo se estructura en una serie de directorios listados a continuación:

* **cpp**: Software para el micro-procesador.
* **python**: Script para comunicar por el puerto UART la PC con la FPGA.
* **rtl**: Entorno de verificación.
* **sim**: Simulador en python que se utiliza para entender el comportamiento del filtro adaptivo.

En particular, el código del ecualizador se encuentra en el directorio `rtl/dsp`.
En la siguiente figura vemos un diagrama del sistema a implementar:

![dsp]

En esta figura, se ven anchos de palabra no definidos. Por medio de los scripts de simulación provistos en el directorio `sim`, se pudo estimar los anchos requeridos para cada bus:

* salida de FFE    : signed (9,7)
* salida de slicer : signed (8,7)
* señal de error   : signed (8,7)
* coeficientes     : signed (9,7) 

Se pudo ver en las simulaciones que:
* La salida del filtro siempre se encuentra dentro del rango [-2,2), por lo tanto con 2 bits de parte entera es suficiente.
* Tanto el error como la señal de slicer, nunca pueden superar el rango [-1,1), por lo tanto, con 1 bit de parte entera es suficiente
* Los valores que van tomando los coeficientes, tampoco nunca superan  el rango [-2,2), por lo tanto, con 2 bits de parte entera es suficiente.

En cualquier caso, si por alguna condición numérica excepcional se supera el rango previsto, existe una lógica de saturación que previene el *wrapping*. 

# Descripción de FFE

La arquitectura del Feed Forward Equalizer (FFE) se puede ver en la siguiente figura:

![ffe]

En particular, se usó una forma directa y un árbol de sumas para que sea sencillo agregar registros de pipeline en una etapa subsecuente. A la salida, hay una lógica de saturación y truncado que ajusta la palabra de S(23,14) a S(9,7). Experimentalmente se encontró donde conviene hacer el corte para no perder precisión.

# Descripción del LMS

La arquitectura del Least Mean Squares (LMS) se puede ver en la siguiente figura:

![lms]

# Simulación

La simulación se realizó con ![cocotb] y se compararon los resultados con los de la simulación en Python. Para ejecutar los tests, posicionarse en el directorio `rtl/dsp/sim` y hacer

```
$ make
$ make gtkwave
```

# Síntesis

Una vez obtenidos los resultados deseados en simulación, se procedió a implementar el sistema completo en FPGA. Al no cumplir con el timing, como era previsible, se procedió a insertar registros en diferentes paths para que el sistema pueda correr con el clock esperado. En los siguientes gráficos se puede ver donde fueron insertados los registros que permitieron cumplir con los constraints de timing.

![ffe_pipe]

![lms_pipe]



# Problemas encontrados



[dsp]: img/dsp.png
[ffe]: img/FFE.png
[ffe_pepi]: img/FFE_pipeline.png
[lms]: img/LMS.png
[lms_pipe]: img/LMS_pipeline.png
[cocotb]: https://github.com/cocotb/cocotb

