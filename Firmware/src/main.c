/**
  ******************************************************************************
  * @file    main.c
  * @author  Ac6
  * @version V1.0
  * @date    01-December-2013
  * @brief   Default main function.
  ******************************************************************************
*/


#include "stm32f10x.h"
volatile uint32_t millis=0;
#include "board.h"
//#include "myFont.h"
#include "ssd1306.h"
#include "si5351.h"
Framebuffer display_buffer;
volatile Board_ReflectometerStateTypeDef Board_ReflectometerState;
volatile CalibrationState Board_CalibrationState;

int main(void)
{
	SSD1306_ConfigTypeDef SSD1306_ConfigStruct;
	Si5351_ConfigTypeDef Si5351_ConfigStruct;
	//uint16_t i=0;
	uint32_t last_millis=millis;

	Init_Board(&Si5351_ConfigStruct, &SSD1306_ConfigStruct, &display_buffer, &Board_ReflectometerState);

	while(1){__asm volatile ("NOP");}
	while(1)
	{
		uint8_t data=0;
		data=Si5351_ReadRegister(&Si5351_ConfigStruct, REG_DEV_STATUS);
		(data & DEV_SYS_INIT_MASK)?dispError(&SSD1306_ConfigStruct,0):dispOK(&SSD1306_ConfigStruct,0);
		(data & DEV_LOS_XTAL_MASK)?dispError(&SSD1306_ConfigStruct,1):dispOK(&SSD1306_ConfigStruct,1);
		(data & DEV_LOL_A_MASK)?dispError(&SSD1306_ConfigStruct,2):dispOK(&SSD1306_ConfigStruct,2);
		(data & DEV_LOL_B_MASK)?dispError(&SSD1306_ConfigStruct,3):dispOK(&SSD1306_ConfigStruct,3);

		SSD1306_StopProgressBar(&SSD1306_ConfigStruct);
		SSD1306_DrawPartialBuffer(&SSD1306_ConfigStruct,0,4);
		SSD1306_StartProgressBar(&SSD1306_ConfigStruct);

		Delay_ms(250);

		if(!(data & (DEV_STKY_SYS_INIT_MASK | DEV_STKY_LOS_XTAL_MASK | DEV_STKY_LOL_A_MASK | DEV_STKY_LOL_B_MASK)))
		{
			last_millis=millis;
			GPIO_WriteBit(LED_PORT, LED_NOT_RDY, Bit_SET);
			GPIO_WriteBit(LED_PORT, LED_RDY,    Bit_RESET);
		} else {
			GPIO_WriteBit(LED_PORT, LED_NOT_RDY, Bit_RESET);
			GPIO_WriteBit(LED_PORT, LED_RDY,    Bit_SET);
		}

		if(millis-last_millis>3000)
		{
			last_millis=millis;
			Si5351_ClearStickyBits(&Si5351_ConfigStruct);
		}
	}

	while(1)
	{
		uint8_t data=0;
		char str[9]={0,0,0,0,0,0,0,0,0};

		data=Si5351_ReadRegister(&Si5351_ConfigStruct, REG_DEV_STATUS);
		getbits(data, str);
		SSD1306_DrawStringToBuffer(&SSD1306_ConfigStruct, 0, 1, str);

		data=Si5351_ReadRegister(&Si5351_ConfigStruct, REG_DEV_STICKY);
		getbits(data, str);
		SSD1306_DrawStringToBuffer(&SSD1306_ConfigStruct, 0, 2, str);

		data=Si5351_ReadRegister(&Si5351_ConfigStruct, REG_INT_MASK);
		getbits(data, str);
		SSD1306_DrawStringToBuffer(&SSD1306_ConfigStruct, 0, 3, str);

		SSD1306_ConfigStruct.Scroll_State=OFF;
		SSD1306_ScrollInit(&SSD1306_ConfigStruct);
		SSD1306_DrawBuffer(&SSD1306_ConfigStruct);
		SSD1306_ConfigStruct.Scroll_State=ON;
		SSD1306_ScrollInit(&SSD1306_ConfigStruct);

		if(GPIO_ReadInputDataBit(nPLL_INT_PORT, nPLL_INT))
		{
			GPIO_WriteBit(LED_PORT, LED_NOT_RDY, Bit_RESET);
		} else {
			GPIO_WriteBit(LED_PORT, LED_NOT_RDY, Bit_SET);
		}
		Delay_ms(5);
	}
}
