/*
 * funciones.h
 *
 *  Created on: Sep 8, 2015
 *      Author: gbergero
 */



#ifndef FUNCIONES_H_
#define FUNCIONES_H_

/* #define enable_seed 				12 */
/* #define reset_numeros_aleatorios 	22 */

 //PARAMETROS

//-----------------------------DEFINICION DE FUNCIONES--------------------------------------
void set_pin(short int Value,short int desplazamiento);
void set_gpio(unsigned char data[]);
void read_ram_block32(int device);
//---------------------------------------------------------------------------------------


void set_pin(short int Value,short int desplazamiento)
{
	u32 valor_dato = (Value<<desplazamiento) ;
	u32 mascara=0xFFFFFFFF ^ (1<<desplazamiento);
	GPO_Value=valor_dato | (mascara & GPO_Value);
	XGpio_DiscreteWrite(&GpioOutput,1, (u32) GPO_Value);
}

void set_gpio(unsigned char data[]) // apola
{
    GPO_Value=data[3]<<24;
    GPO_Value|=data[2]<<16;
    GPO_Value|=data[1]<<8;
    GPO_Value|=data[0];
	XGpio_DiscreteWrite(&GpioOutput,1, (u32) GPO_Value);
	GPO_Value|=0x80 << 16;
	XGpio_DiscreteWrite(&GpioOutput,1, (u32) GPO_Value);
	GPO_Value|=0x00 << 16;
	XGpio_DiscreteWrite(&GpioOutput,1, (u32) GPO_Value);
}


void read_ram_block32(int device){
	u32 value;
    unsigned char datos_rec[4];

	const int tam=1024*4;
	unsigned char cabecera[4]={0xA0,0x00,0x00,0x00};
	unsigned char datos;
	unsigned char fin_trama[1]={0x40};

	cabecera[0]=cabecera[0] | 0x10;//TRAMA LARGA
	cabecera[1]=(0xFF00 & tam)>>8;
  cabecera[2]=0xFF & tam;
  cabecera[3]=def_LOG_READ_SRRC;

	fin_trama[0]=fin_trama[0] | 0x10;
	XUartLite_Send(&uart_module, cabecera,4);

    int i;
    for(i=0;i<1024;i++){

        datos_rec[3] = 0x07;
        datos_rec[2] = 0x07 & device;            // Sel Device
        datos_rec[1] = ((0x7F00 & i)>>8); // Addr
        datos_rec[0] = 0x00FF & i;             // Addr
        set_gpio(datos_rec);

        datos_rec[3]=0x00;
        datos_rec[2]=0x00;
        datos_rec[1]=0x00;
        datos_rec[0]=0x00;
        set_gpio(datos_rec);

        value = XGpio_DiscreteRead(&GpioInput, 1);

		datos=value&(0x000000FF);
		while(XUartLite_IsSending(&uart_module)){}
		XUartLite_Send(&uart_module, &(datos),1);
		datos=(value&(0x0000FF00))>>8;
		while(XUartLite_IsSending(&uart_module)){}
		XUartLite_Send(&uart_module, &(datos),1);
		datos=(value&(0x00FF0000))>>16;
		while(XUartLite_IsSending(&uart_module)){}
		XUartLite_Send(&uart_module, &(datos),1);
		datos=(value&(0xFF000000))>>24;
		while(XUartLite_IsSending(&uart_module)){}
		XUartLite_Send(&uart_module, &(datos),1);
    }
    while(XUartLite_IsSending(&uart_module)){}
	XUartLite_Send(&uart_module, fin_trama,1);
	
}

#endif /* FUNCIONES_H_ */
