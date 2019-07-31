
#include <stdio.h>
#include <string.h>
#include "xparameters.h"
#include "xil_cache.h"
#include "xgpio.h"
#include "platform.h"

#include "xuartlite.h"
//#include "encender_led.h"
#include "microblaze_sleep.h"




//CANALES DE GPIO       XPAR_AXI_GPIO_1_DEVICE_ID
#define PORT_IN	 		XPAR_GPIO_0_DEVICE_ID
#define PORT_OUT 		XPAR_GPIO_0_DEVICE_ID
//#define PORT_OUT_PARAM 	XPAR_AXI_GPIO_2_DEVICE_ID

//Device_ID Operaciones
#define def_SOFT_RST            16
#define def_ENABLE_MODULES      17
#define def_LOG_RUN             23
#define def_LOG_READ            24

//Device_ID Respuestas
#define def_ACK 				1
#define def_ERROR 				2
#define def_ID_NOT_FOUND		4
#define def_LOG_READ_SRRC       17

void send_trama(int id);
void send_ack(int from_id);

XGpio GpioOutput;
XGpio GpioParameter;
XGpio GpioInput;
u32 GPO_Value;
u32 GPO_Param;
XUartLite uart_module;

short int num_ber;
#include "funciones.h"

//Funcion para recibir 1 byte bloqueante
//XUartLite_RecvByte((&uart_module)->RegBaseAddress)


int main()
{
	init_platform();
	int Status;
	XUartLite_Initialize(&uart_module, 0);

	GPO_Value=0x00000000;
	GPO_Param=0x00000000;
	unsigned char cabecera[4];
	u16 tamano_datos;
	Status=XGpio_Initialize(&GpioInput, PORT_IN);
	if(Status!=XST_SUCCESS){
        send_trama(def_ERROR);
        return XST_FAILURE;
    }
	Status=XGpio_Initialize(&GpioOutput, PORT_OUT);
	if(Status!=XST_SUCCESS){
		send_trama(def_ERROR);
		return XST_FAILURE;
	}
	XGpio_SetDataDirection(&GpioOutput, 1, 0x00000000);
	XGpio_SetDataDirection(&GpioInput, 1, 0xFFFFFFFF);

	while(1){
        read(stdin,&cabecera[0],1);
        if(cabecera[0]==0xFF)
            {continue;}
        if(((cabecera[0]>>5)&0x07)==0x05){
            read(stdin,&cabecera[1],3);
            //correcto
            if((cabecera[0]>>4 & 0x01)==0x01){
                //trama larga
                tamano_datos=cabecera[1]<<8 | cabecera[2];
            }
            else{
                //trama corta
                tamano_datos=cabecera[0]&0x0F;
            }

		   unsigned char datos_rec[tamano_datos];
		   short int i;
		   for(i=0;i<tamano_datos;i++){
			   datos_rec[i]=XUartLite_RecvByte((&uart_module)->RegBaseAddress);
		   }

		   unsigned char fin_trama;
		   read(stdin,&fin_trama,1);

		   if((((fin_trama>>5)&0x07)==0x2)				&&
              ((cabecera[0]&0x10)==(fin_trama&0x10))	&&
              ((cabecera[0]&0xF)==(fin_trama&0xF))
              ){}
           else{
               //encender(6,&GpioOutput);
               //incorrecto
               continue;
		   }
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// ACA es donde se escribe toda la funcionalidad
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

		   switch(cabecera[3]){
           case def_SOFT_RST:
               datos_rec[3]=0x01;
               datos_rec[2]=0x00;
               datos_rec[1]=0x00;
               set_gpio(datos_rec);
               send_ack(def_SOFT_RST);
               break;
           case def_ENABLE_MODULES:
               datos_rec[3]=0x02;
               datos_rec[2]=0x00;
               datos_rec[1]=0x00;
               set_gpio(datos_rec);
               send_ack(def_ENABLE_MODULES);
               break;
           case def_LOG_RUN:
               datos_rec[3]=0x06;
               datos_rec[2]=0x00;
               datos_rec[1]=0x00;
               set_gpio(datos_rec);
               send_ack(def_LOG_RUN);
               break;
           case def_LOG_READ:
        	     read_ram_block32(6);
               send_ack(def_LOG_READ);
               break;
           default:
               send_trama(def_ID_NOT_FOUND);
               break;
		   }
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
// FIN de toda la funcionalidad
//%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        }
        else{
            //incorrecto
            continue;
        }
	}
	cleanup_platform();
	return 0;
}


void send_ack(int from_id){
	unsigned char cabecera[4]={0xA1,0x00,0x00,0x00};
	unsigned char fin_trama[1]={0x41};
	unsigned char datos[1];
	datos[0]=from_id;
	cabecera[3]=def_ACK;
	XUartLite_Send(&uart_module, cabecera,4);
	while(XUartLite_IsSending(&uart_module)){}
	XUartLite_Send(&uart_module, datos,1);
	XUartLite_Send(&uart_module, fin_trama,1);
}

void send_trama(int id){
	unsigned char cabecera[4]={0xA0,0x00,0x00,0x00};
	unsigned char fin_trama[1]={0x40};
	cabecera[3]=id;
	XUartLite_Send(&uart_module, cabecera,4);
	while(XUartLite_IsSending(&uart_module)){}
	XUartLite_Send(&uart_module, fin_trama,1);
}
