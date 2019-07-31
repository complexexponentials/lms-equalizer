

import numpy as np
import matplotlib.pyplot as plt

Nsymb     = 1000 ## Numero de Simbolos
step_sel  = 3    ## Paso
ch_sel    = 3    ## Canal

## Canales
channel   = [[0,0,0,0.9921875,0,0,0],
             [0,0,0.2421875,0.96875,0,0,0],
             [0,0,0.2421875,0.96875,0.09375,0,0],
             [0,0.171875,0.4375,0.875,0.0859375,0,0]]

## Pasos de adaptacion
steps     = [0,2**-7,2**-5,2**-3]

## Inicializacion de los coeficientes del FFE
ffe_coeff = [0,0,0,0.9921875,0,0,0]  ## s(9,7)

## Generador de bits +/-1
symbols   = 2*(np.random.uniform(-1,1,Nsymb)>0.0)-1

## Convolucion entre los simbolos y el canal
ch_out    = np.convolve(channel[ch_sel],symbols,'same')

## Inicializacion de variables
ffe_shiftR   = np.zeros(len(ffe_coeff))  ## ShiftRegister (SR) de FIR
ffe_outv     = []
errorv       = []
ffe_coeffv   = []

## Operacion de filtrado
for ptr in range(len(ch_out)):
    ffe_shiftR    = np.roll(ffe_shiftR,1)        ## Desplazamiento del SR
    ffe_shiftR[0] = ch_out[ptr]                  ## Carga del nuevo valor

    ffe_out       = np.dot(ffe_shiftR,ffe_coeff) ## Filtrado

    dec           = 2*(ffe_out>0.0)-1            ## Decision (Slicer)
    error         = dec - ffe_out                ## Error

    ## Adaptacion de los coeficientes
    ffe_coeff     = ffe_coeff + steps[step_sel] * error * ffe_shiftR

    ## Logueo de senales
    ffe_outv.append(ffe_out)
    errorv.append(error)
    ffe_coeffv.append(ffe_coeff)


plt.figure()
plt.subplot(2,1,1)
plt.stem(symbols[0:100])
plt.grid()
plt.ylim((np.min(symbols)-0.5,np.max(symbols)+0.5))
plt.ylabel('Amplitude')
plt.title('Symbols and Channel Output')
plt.subplot(2,1,2)
plt.stem(ch_out[0:100])
plt.grid()
plt.ylim((np.min(ch_out)-0.5,np.max(ch_out)+0.5))
plt.ylabel('Amplitude')
plt.xlabel('Samples')

plt.figure()
plt.subplot(2,1,1)
plt.stem(ffe_outv[0:100])
plt.grid()
plt.ylim((np.min(ffe_outv)-0.5,np.max(ffe_outv)+0.5))
plt.ylabel('Amplitude')
plt.xlabel('Samples')
plt.title('FFE Output and Error')
plt.subplot(2,1,2)
plt.plot(errorv)
plt.grid()
plt.ylim((np.min(errorv)-0.5,np.max(errorv)+0.5))
plt.ylabel('Amplitude')
plt.xlabel('Samples')

plt.figure()
plt.subplot(3,1,1)
plt.plot(ffe_coeffv)
plt.grid()
plt.ylim((min(ffe_coeffv[len(ffe_coeffv)-1])-0.5,max(ffe_coeffv[len(ffe_coeffv)-1])+0.5))
plt.ylabel('Amplitude')
plt.title('Taps of FFE')
plt.subplot(3,1,2)
plt.stem(ffe_coeffv[len(ffe_coeffv)-1])
plt.grid()
plt.ylim((min(ffe_coeffv[len(ffe_coeffv)-1])-0.5,max(ffe_coeffv[len(ffe_coeffv)-1])+0.5))
plt.ylabel('Amplitude')
plt.subplot(3,1,3)
plt.stem(np.convolve(channel[ch_sel],ffe_coeffv[len(ffe_coeffv)-1]))
plt.grid()
plt.ylim((min(ffe_coeffv[len(ffe_coeffv)-1])-0.5,max(ffe_coeffv[len(ffe_coeffv)-1])+0.5))
plt.ylabel('Conv.Ch.Taps')
plt.xlabel('Samples')

plt.show(block=False)
input('Press Enter to Continue')
plt.close()

