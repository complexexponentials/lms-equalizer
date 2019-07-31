##############  INICIALIZACION ####################
from __future__ import print_function

import serial
import time
import threading
import numpy
import math
#import DSPtools as DT
import sys
#import matplotlib.pylab as plt

# definicion de funciones de las tramas
Device_ID_Recv={'ACK':1,'LOG_READ_SRRC':17}

Device_ID={'SET_SIGMA':1,'START_RUIDO':2,'INIT':3,'LOG_VALUES':5,'START_DECODER':7,
           'RUN_LIBRE':8,'RUN_WORD':9,'READ_CW_ERROR':10,'PUENTEAR_DECODER':11,'GEN_CW_0':12,
           'SET_ITERACIONES':13,'LOG_ITER_RCV':14,'SET_RESOLUCIONES':15,'SOFT_RST':16,'ENABLE_MODULES':17,
           'BER_CTRL':18,'SIGMA':19,'LOG_BER_READ':20,'COEFF_CH':21,'ADAP_STEP':22,'LOG_RUN':23,'LOG_READ':24,
           'COEFF_FFE':25,'COEFF_DFFE':26}

# definiciones del sistema
class Valor_Logueado:
	def __init__(self, errores, bits):
		self.e = errores
		self.b = bits

class Reception_End:
        def __init__(self,state):
                self.s = state

def imprimir_opciones():
        print('\n')
        for key in Device_ID:
                print(key,"=",Device_ID[key])



#execfile("Dec2bin.py")

def send_enable(Valor,dev_id):
		time.sleep(0.2)
		cabecera=[0xA0,0x00,0x00,0x00]
		fin_trama=[0x40]
		tam=1
		dato_send=[0x00 for _ in range(0,tam)]
		cabecera[3]     = dev_id
		cabecera[0]     = cabecera[0] | int(tam)
		fin_trama[0]    = fin_trama[0] | int(tam)
		dato_send[0]    = (Valor & 0xFF)
		for A in cabecera:
			uart.write(chr(A))
		for A in dato_send:
			uart.write(chr(A))
		for A in fin_trama:
			uart.write(chr(A))


LOG_NAME       = raw_input('Log File Name: ')
LOG_WIDTH_RAM  = raw_input('Log Ram Width (8/16/32): ')
LOG_RESOLUTION = raw_input('Log NB,NBF (Ex: 8,7): ')
LOG_RESOLUTION = LOG_RESOLUTION.split(',')

def log_ram(reception_end,log_file,datos_recv,tamano_datos,id_name):
        print(tamano_datos)
        if(id_name==Device_ID_Recv['LOG_READ_SRRC']):
                resultados=[int(0) for _ in range(0,int(tamano_datos/4))]
                log_file0=open("./logs/%s.out"%LOG_NAME,"w")
        for i in range(0,int(len(resultados))):
                if(id_name==Device_ID_Recv['LOG_READ_SRRC']):
                        if(LOG_WIDTH_RAM=='8'):
                                resultados[i]  =  datos_recv[(i*4)+0];
                                resultados[i]=((((resultados[i])+2**(int(LOG_RESOLUTION[0])-1))&int(2**int(LOG_RESOLUTION[0])-1))-
                                               2**(int(LOG_RESOLUTION[0])-1))*(2**-int(LOG_RESOLUTION[1]))
                                log_file0.write("%e\t" % resultados[i])
                                resultados[i] = (datos_recv[(i*4)+1]);
                                resultados[i]=((((resultados[i])+2**(int(LOG_RESOLUTION[0])-1))&int(2**int(LOG_RESOLUTION[0])-1))-
                                               2**(int(LOG_RESOLUTION[0])-1))*(2**-int(LOG_RESOLUTION[1]))
                                log_file0.write("%e\t" % resultados[i])
                                resultados[i] = (datos_recv[(i*4)+2]);
                                resultados[i]=((((resultados[i])+2**(int(LOG_RESOLUTION[0])-1))&int(2**int(LOG_RESOLUTION[0])-1))-
                                               2**(int(LOG_RESOLUTION[0])-1))*(2**-int(LOG_RESOLUTION[1]))
                                log_file0.write("%e\t" % resultados[i])
                                resultados[i] = (datos_recv[(i*4)+3]);
                                resultados[i]=((((resultados[i])+2**(int(LOG_RESOLUTION[0])-1))&int(2**int(LOG_RESOLUTION[0])-1))-
                                               2**(int(LOG_RESOLUTION[0])-1))*(2**-int(LOG_RESOLUTION[1]))
                                log_file0.write("%e\n" % resultados[i])

                        elif(LOG_WIDTH_RAM=='16'):
                                resultados[i]  =  datos_recv[(i*4)+0];
                                resultados[i] |= (datos_recv[(i*4)+1])<<8;
                                resultados[i]=((((resultados[i])+2**(int(LOG_RESOLUTION[0])-1))&int(2**int(LOG_RESOLUTION[0])-1))-
                                               2**(int(LOG_RESOLUTION[0])-1))*(2**-int(LOG_RESOLUTION[1]))
                                log_file0.write("%e\t" % resultados[i])
                                resultados[i]  = (datos_recv[(i*4)+2]);
                                resultados[i] |= (datos_recv[(i*4)+3])<<8;
                                resultados[i]=((((resultados[i])+2**(int(LOG_RESOLUTION[0])-1))&int(2**int(LOG_RESOLUTION[0])-1))-
                                               2**(int(LOG_RESOLUTION[0])-1))*(2**-int(LOG_RESOLUTION[1]))
                                log_file0.write("%e\n" % resultados[i])
                        else:
                                resultados[i]  =  datos_recv[(i*4)+0];
                                resultados[i] |= (datos_recv[(i*4)+1])<<8;
                                resultados[i] |= (datos_recv[(i*4)+2])<<16;
                                resultados[i] |= (datos_recv[(i*4)+3])<<24;
                                resultados[i]=((((resultados[i])+2**(int(LOG_RESOLUTION[0])-1))&int(2**int(LOG_RESOLUTION[0])-1))-
                                               2**(int(LOG_RESOLUTION[0])-1))*(2**-int(LOG_RESOLUTION[1]))
                                log_file0.write("%e\n" % resultados[i])
                        #resultados[i]=((((resultados[i])+2**13)&0x3FFF)-2**13)*(2**-12)


        log_file0.close()
        reception_end.s=1

log_file=open("./logs/log_listen.log","a")

valores_read=Valor_Logueado(0,0)
reception_end=Reception_End(0)

portUSB = sys.argv[1]
uart=serial.Serial('/dev/ttyUSB%s'%int(portUSB),115200)


uart.timeout=None

#hilo de ejecucion que se encarga de recibir todas las tramas independiente de la transmision de datos
def escuchar():
		log_file.write("\n\n")
		log_file.write("START =>")
		log_file.write(time.strftime("%d %b %Y %H:%M:%S\n ", time.localtime()))
		log_file.flush()
		hilo_act = threading.currentThread()
		cab_recv=[0x00,0x00,0x00,0x00]
		while True:
				cab_recv[0]=ord(uart.read())
				if cab_recv[0]!=0xFF:
						if(((cab_recv[0]>>5)&0x07)==0x05):
								for jj in range(1,4):
										cab_recv[jj]=ord(uart.read())
								if((cab_recv[0] & 0x10)==0x10):
										#trama larga
										tamano_datos=cab_recv[1]<<8 | cab_recv[2]
								else:
										#trama corta
										tamano_datos=cab_recv[0]&0x0F

								datos_recv=[0x00 for _ in range(0,tamano_datos)]
								for jj in range(0,tamano_datos):
										datos_recv[jj]=ord(uart.read())#recibir los datos

								fin_trama=ord(uart.read())
                                                                #print cab_recv[3]
								if((((fin_trama>>5)&0x07)==0x2)and ((cab_recv[0]&0x10)==(fin_trama&0x10)) and ((cab_recv[0]&0xF)==(fin_trama&0xF))):
										#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
										if cab_recv[3]==Device_ID_Recv['ACK']:
											save_key='ID NO ENCONTRADO'
											for key in Device_ID:
												if Device_ID[key] == datos_recv[0]:
													save_key=key
											log_file.write("ACK de %s\n" %(save_key))
										elif ((cab_recv[3] == Device_ID_Recv['LOG_READ_SRRC'])):
											reception_end.s=0
											log_ram(reception_end,log_file,datos_recv,tamano_datos,cab_recv[3])

										log_file.flush()
										#%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
								else:
										for jj in range(0,4):
											log_file.write("%2X-" %(cab_recv[jj]))
										log_file.write(" <= cabecera\n")
										log_file.write("fin_trama recibido incorrecto=%X\n" %(fin_trama))
										#fin_trama incorrecto
										continue
						else:
								#cabecera incorrecta
								for jj in range(0,4):
										log_file.write("%X" %(cab_recv[jj]))
								log_file.write(" <= cabecera recibida incorrecta\n")
								continue
		return

hilo = threading.Thread(target=escuchar)
hilo.setDaemon(True)
hilo.start()


def log_all():
        print("LOG RUN OFF")
        send_enable(0x0,Device_ID['LOG_RUN'])
        time.sleep(3)
        print("LOG RUN ON")
        send_enable(0x1,Device_ID['LOG_RUN'])
        time.sleep(5)

        print("LOG READ")
        send_enable(0x1,Device_ID['LOG_READ'])
        while(reception_end.s==0):{}
        time.sleep(20)



print("RESET ON") 
send_enable(0x1,Device_ID['SOFT_RST'])
time.sleep(1)
print("MODULES OFF")
send_enable(0x0,Device_ID['ENABLE_MODULES'])
time.sleep(1)
print("LOG RUN OFF")
send_enable(0x0,Device_ID['LOG_RUN'])
time.sleep(1)
print("RESET OFF")
send_enable(0x0,Device_ID['SOFT_RST'])
time.sleep(1)	
print("ENB MODULES")
enables = raw_input('Value: ')
send_enable(int(enables),Device_ID['ENABLE_MODULES'])
time.sleep(5)
time.sleep(1)	
print("LOG")
log_all()

time.sleep(10)	
print("End Script")
#exit()


# dataS = plt.loadtxt('log_srrc.out')
# plt.figure()
# plt.plot(dataS[:,0])
# plt.plot(dataS[:,1])
# plt.grid()

# plt.show(block=False)
# raw_input('Press Enter to Continue')
# plt.close()
