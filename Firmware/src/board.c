/*
 * board.c
 *
 *  Created on: Dec 24, 2017
 *      Author: msboss
 */

#define INT_DIVIDER 46
#define NUMBER_OF_POINTS 100000
#define DRAMATIC_PAUSE 250
#define SAMPLE_MEMORY_SIZE	4096
#define DEVICE_NAME "TDR5351_CORE"

#include <stm32f10x_rcc.h>
#include "board.h"
//#include <stm32f10x_misc.h>
#include "ssd1306.h"
#include "stdlib.h"
#include "si5351.h"

bool I2C_Initialised = FALSE;
extern volatile uint32_t millis;
extern volatile Board_ReflectometerStateTypeDef Board_ReflectometerState;
extern volatile CalibrationState Board_CalibrationState;
volatile bool Remote_Mode = FALSE;

#define COMMAND_REMOTE 0
#define COMMAND_DEVICE 1
#define COMMAND_STATE  2
#define COMMAND_ACTION 3
#define COMMAND_SEND_DATA	4
#define COMMAND_GET_AVG	5
const char commands[6][15]={"REM!","DEV?","STATE?","CONTINUE!","SEND_DATA!", "AVG?"};

#define NO_RESPONSE_PENDING		255
#define	RESPONSE_CARRIAGE_RETURN 254
#define RESPONSE_LINE_FEED 		253
#define RESPONSE_BLOCKING_TRANSFER_PENDING 252
#define RESPONSE_SEND_DATA		251
#define RESPONSE_REMOTE 				0
#define RESPONSE_DEVICE 				1
#define RESPONSE_BOARD_INIT 			2
#define RESPONSE_WAIT_EDGE 				3
#define RESPONSE_CALIBRATING_SAMPLER 	4
#define RESPONSE_NOISE_ESTIMATION	 	5
#define RESPONSE_FINDING_EDGE		 	6
#define RESPONSE_FINDING_REFERENCE_PLANE	7
#define RESPONSE_READY					8
#define RESPONSE_WAIT_OPEN				9
#define RESPONSE_WAIT_SHORT				10
#define RESPONSE_WAIT_LOAD				11
#define RESPONSE_NORMAL_CAL_RUNNING		12
#define RESPONSE_WAIT_REFERENCE_PLANE 	13
#define RESPONSE_WAIT_DUT				14
#define RESPONSE_MEASUREMENT_RUNNING	15
#define RESPONSE_READY_TO_SEND			16
#define RESPONSE_SENDING_DATA			17
#define RESPONSE_AVG					18
#define RESPONSE_AVG_NUMBER				19
uint8_t responses[20][48]={"REM.",DEVICE_NAME" "__DATE__" "__TIME__,"STATE BOARD_INIT","STATE WAIT_EDGE",
			"STATE CALIBRATING_SAMPLER","STATE NOISE_ESTIMATION","STATE FINDING_EDGE","STATE FINDING_REFERENCE_PLANE",
			"STATE READY","STATE WAIT_OPEN","STATE WAIT_SHORT","STATE WAIT_LOAD","STATE NORMAL_CAL_RUNNING",
			"STATE WAIT_REFERENCE_PLANE","STATE WAIT_DUT","STATE MEASUREMENT_RUNNING", "STATE READY_TO_SEND",
			"STATE SENDING_DATA", "AVG ", "0"};
volatile uint8_t global_response_pending=NO_RESPONSE_PENDING;

volatile bool remote_user_action=FALSE;

void Wait_For_User_Action(void)
{
	while((GPIO_ReadInputDataBit(BTN_PORT,BTN)==SET)&(remote_user_action==FALSE)){}
	remote_user_action=FALSE;
}

void SysTick_Handler(void)
{
	static uint32_t TX_position = 0;
	millis++;

	if (USART_GetFlagStatus(USART1, USART_FLAG_TXE) != RESET) // Serial port TX handler
	{
		if (global_response_pending==RESPONSE_BLOCKING_TRANSFER_PENDING) return;

		if (global_response_pending!=NO_RESPONSE_PENDING)
		{

			if (global_response_pending==RESPONSE_SEND_DATA)
			{
				uint16_t i16;
				for(i16=0; i16<SAMPLE_MEMORY_SIZE; i16++)
				{
					while (USART_GetFlagStatus(USART1, USART_FLAG_TXE)!=SET){}
					USART_SendData(USART1,(uint8_t)Board_ReflectometerState.sampled_data[i16]);
					while (USART_GetFlagStatus(USART1, USART_FLAG_TXE)!=SET){}
					USART_SendData(USART1,(uint8_t)(Board_ReflectometerState.sampled_data[i16]>>8));
				}
				global_response_pending=NO_RESPONSE_PENDING;
			}

			if (global_response_pending==RESPONSE_CARRIAGE_RETURN)
			{
				USART_SendData(USART1, '\r');
				global_response_pending=RESPONSE_LINE_FEED;
				return;
			}

			if (global_response_pending==RESPONSE_LINE_FEED)
			{
				USART_SendData(USART1, '\n');
				global_response_pending=NO_RESPONSE_PENDING;
				return;
			}

			if (responses[global_response_pending][TX_position]==0)
			{
				if (global_response_pending==RESPONSE_AVG)
				{
					global_response_pending=RESPONSE_AVG_NUMBER;
				} else {
					global_response_pending=RESPONSE_CARRIAGE_RETURN;
				}
				TX_position=0;
			} else {
				USART_SendData(USART1, responses[global_response_pending][TX_position]);
				TX_position++;
			}
		}
	}
}

void Delay_ms(uint32_t Wait)
{
	uint32_t temp=millis;
	while((millis-temp) < Wait) asm volatile ("nop");
}

void getnum(uint16_t num, char str[6])
{
	EnableState zero_suppression=TRUE;

	str[0]=(uint8_t)(num/10000);
	num=num%10000;
	str[0]+=48;
	if ((str[0]==48) & (zero_suppression==ON))
	{
		str[0]=32;
	} else {
		zero_suppression=FALSE;
	}

	str[1]=(uint8_t)(num/1000);
	num=num%1000;
	str[1]+=48;
	if ((str[1]==48) & (zero_suppression==ON))
	{
		str[1]=32;
	} else {
		zero_suppression=FALSE;
	}

	str[2]=(uint8_t)(num/100);
	num=num%100;
	str[2]+=48;
	if ((str[2]==48) & (zero_suppression==ON))
	{
		str[2]=32;
	} else {
		zero_suppression=FALSE;
	}

	str[3]=(uint8_t)(num/10);
	num=num%10;
	str[3]+=48;
	if ((str[3]==48) & (zero_suppression==ON))
	{
		str[3]=32;
	} else {
		zero_suppression=FALSE;
	}

	str[4]=(uint8_t)num+48;

	str[5]=0;
}

void getnum32(uint32_t num, char str[11])
{
	EnableState zero_suppression=TRUE;

	str[0]=(uint8_t)(num/1000000000);
	num=num%1000000000;
	str[0]+=48;
	if ((str[0]==48) & (zero_suppression==ON))
	{
		str[0]=32;
	} else {
		zero_suppression=FALSE;
	}

	str[1]=(uint8_t)(num/100000000);
	num=num%100000000;
	str[1]+=48;
	if ((str[1]==48) & (zero_suppression==ON))
	{
		str[1]=32;
	} else {
		zero_suppression=FALSE;
	}

	str[2]=(uint8_t)(num/10000000);
	num=num%10000000;
	str[2]+=48;
	if ((str[2]==48) & (zero_suppression==ON))
	{
		str[2]=32;
	} else {
		zero_suppression=FALSE;
	}

	str[3]=(uint8_t)(num/1000000);
	num=num%1000000;
	str[3]+=48;
	if ((str[3]==48) & (zero_suppression==ON))
	{
		str[3]=32;
	} else {
		zero_suppression=FALSE;
	}

	str[4]=(uint8_t)(num/100000);
	num=num%100000;
	str[4]+=48;
	if ((str[4]==48) & (zero_suppression==ON))
	{
		str[4]=32;
	} else {
		zero_suppression=FALSE;
	}

	str[5]=(uint8_t)(num/10000);
	num=num%10000;
	str[5]+=48;
	if ((str[5]==48) & (zero_suppression==ON))
	{
		str[5]=32;
	} else {
		zero_suppression=FALSE;
	}

	str[6]=(uint8_t)(num/1000);
	num=num%1000;
	str[6]+=48;
	if ((str[6]==48) & (zero_suppression==ON))
	{
		str[6]=32;
	} else {
		zero_suppression=FALSE;
	}

	str[7]=(uint8_t)(num/100);
	num=num%100;
	str[7]+=48;
	if ((str[7]==48) & (zero_suppression==ON))
	{
		str[7]=32;
	} else {
		zero_suppression=FALSE;
	}

	str[8]=(uint8_t)(num/10);
	num=num%10;
	str[8]+=48;
	if ((str[8]==48) & (zero_suppression==ON))
	{
		str[8]=32;
	} else {
		zero_suppression=FALSE;
	}

	str[9]=(uint8_t)num+48;

	str[10]=0;
}

void getbits(uint8_t bits, char str[9])
{
	uint8_t i=0;
	for(i=0; i<8; i++)
	{
		str[i]=bits&(1<<(7-i))?49:48;
	}
	str[9]=0;
}

void Si5351_ClearStickyBits(Si5351_ConfigTypeDef *Si5351_ConfigStruct)
{
	Si5351_ClearStickyBit(Si5351_ConfigStruct, StatusBit_CLKIN | StatusBit_PLLA | StatusBit_PLLB | StatusBit_SysInit | StatusBit_XTAL);
}

void dispOK(SSD1306_ConfigTypeDef *SSD1306_ConfigStruct, uint8_t y)
{
	SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, SSD1306_COLUMNS-6*3, y, "OK ");
}

void dispError(SSD1306_ConfigTypeDef *SSD1306_ConfigStruct, uint8_t y)
{
	SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, SSD1306_COLUMNS-6*3, y, "ERR");
}

void Init_Board(Si5351_ConfigTypeDef *Si5351_ConfigStruct, SSD1306_ConfigTypeDef *SSD1306_ConfigStruct, Framebuffer *display_buffer, Board_ReflectometerStateTypeDef *Board_ReflectometerState)
{
	uint8_t i8;
	uint16_t i16;

	Board_CalibrationState=CAL_BOARD_INIT;

	RCC_SYSCLKConfig(RCC_SYSCLKSource_HSI);	//select HSI as SYSCLK source during setup
	RCC_HSEConfig(RCC_HSE_ON);				//enable HSE
	while (RCC_GetFlagStatus(RCC_FLAG_HSERDY)==RESET) asm volatile ("nop");
											//wait for HSE to get ready
	RCC_ClockSecuritySystemCmd(ENABLE);		//enable CSS
	RCC_PLLConfig(RCC_PLLSource_HSE_Div1, RCC_PLLMul_7); //select HSE as PLL source, multiply to 7*HSE
	RCC_PLLCmd(ENABLE);						//enable PLL
	while (RCC_GetFlagStatus(RCC_FLAG_PLLRDY)==RESET) asm volatile ("nop");
											//wait for PLL to get ready
	RCC_HCLKConfig(RCC_SYSCLK_Div1);		//set HCLK to SYSCLK/1
	RCC_PCLK1Config(RCC_HCLK_Div2);			//set PCLK1 to SYSCLK/2
	RCC_PCLK2Config(RCC_HCLK_Div1);			//set PCLK2 to SYSCLK/1
	RCC_ADCCLKConfig(RCC_PCLK2_Div4);		//set ADCCLK to SYSCLK/4

	FLASH_SetLatency(FLASH_Latency_2);
	FLASH_PrefetchBufferCmd(FLASH_PrefetchBuffer_Enable);

	RCC_SYSCLKConfig(RCC_SYSCLKSource_PLLCLK);		//set SYSCLK to PLLCLK
	while(RCC_GetSYSCLKSource() != 0x08) asm volatile ("nop");
											//wait for PLL to be set as SYSCLK

	//current settings: SYSCLK=HCLK=PCLK2= 9*HSE/1 = 9*HSE = 56 MHZ
	//					CSS ON - backs up SYSCLK with HSI if HSE fails
	//TODO: add RTC clock select

	SysTick_CLKSourceConfig(SysTick_CLKSource_HCLK);
	SystemCoreClockUpdate();
	SysTick_Config(SystemCoreClock/1000);

	Button_Init();
	I2C_Board_Init(DISABLED);
	LED_Init();
	OLED_Init(SSD1306_ConfigStruct, display_buffer);
	SERIAL_Init();

	SSD1306_ConfigStruct->Display_Contrast=0;
	SSD1306_SetContrast(SSD1306_ConfigStruct);

	SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 40, 0, "TDR v1.0");
	SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 5, __DATE__);
	SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 80, 5, __TIME__);
	SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 28, 2, "Initialising");
    SSD1306_DrawProgressBar(SSD1306_ConfigStruct);
	SSD1306_DrawBuffer(SSD1306_ConfigStruct);
	SSD1306_StartProgressBar(SSD1306_ConfigStruct);

	for(i8=0; i8<128; i8++)
	{
		SSD1306_ConfigStruct->Display_Contrast=i8;
		SSD1306_SetContrast(SSD1306_ConfigStruct);
		Delay_ms(10-i8/15);
	}

	Delay_ms(DRAMATIC_PAUSE);

	Calibrate_Si5351(Si5351_ConfigStruct, SSD1306_ConfigStruct, display_buffer, Board_ReflectometerState, ON);

	SY54020_Init();
	MCP4725_Init();
	ADC_BoardInit();

	Board_CalibrationState=CAL_WAIT_EDGE;
	Calibrate_Sampler_Offset(Si5351_ConfigStruct, SSD1306_ConfigStruct, display_buffer, Board_ReflectometerState, ON);
	Board_CalibrationState=CAL_NOISE_ESTIMATION;
	Calibrate_Logic_Levels(Si5351_ConfigStruct, SSD1306_ConfigStruct, display_buffer, Board_ReflectometerState, CAL_OPEN, ON);
	Board_CalibrationState=CAL_FINDING_EDGE;
	Calibrate_Rising_Edge_Position_Guess(Si5351_ConfigStruct, SSD1306_ConfigStruct, display_buffer, Board_ReflectometerState, ON);

	while(0){
	Calibrate_Get_Calibration_Normal_Response(Si5351_ConfigStruct, SSD1306_ConfigStruct, display_buffer, Board_ReflectometerState, CAL_OPEN, ON);

	SSD1306_ClearPartialDisplayBuffer(SSD1306_ConfigStruct, 0,5);
	SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 0, "Please connect short");
	SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 1, "      standard.");
	SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 4, "    Press button");
	SSD1306_StopProgressBar(SSD1306_ConfigStruct);
	SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,0,5);
	Wait_For_User_Action();
	SSD1306_StartProgressBar(SSD1306_ConfigStruct);

	Calibrate_Logic_Levels(Si5351_ConfigStruct, SSD1306_ConfigStruct, display_buffer, Board_ReflectometerState, CAL_SHORT, ON);
	Calibrate_Get_Calibration_Normal_Response(Si5351_ConfigStruct, SSD1306_ConfigStruct, display_buffer, Board_ReflectometerState, CAL_SHORT, ON);

	SSD1306_ClearPartialDisplayBuffer(SSD1306_ConfigStruct, 0,5);
	SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 0, " Please connect load");
	SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 1, "      standard.");
	SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 4, "    Press button");
	SSD1306_StopProgressBar(SSD1306_ConfigStruct);
	SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,0,5);
	Wait_For_User_Action();
	SSD1306_StartProgressBar(SSD1306_ConfigStruct);

	Calibrate_Logic_Levels(Si5351_ConfigStruct, SSD1306_ConfigStruct, display_buffer, Board_ReflectometerState, CAL_LOAD, ON);
	Calibrate_Get_Calibration_Normal_Response(Si5351_ConfigStruct, SSD1306_ConfigStruct, display_buffer, Board_ReflectometerState, CAL_LOAD, ON);
	}

	Board_ReflectometerState->open_low_variation=Board_ReflectometerState->calibration[CAL_OPEN].low_variance;
	Board_ReflectometerState->open_high_variation=Board_ReflectometerState->calibration[CAL_OPEN].high_variance;

	for(i16=0;i16<=48;i16++)
	{
		Board_ReflectometerState->ideal_averaging=i16;
		if((i16*i16>Board_ReflectometerState->open_low_variation) & (i16*i16>Board_ReflectometerState->open_high_variation)) break;
	}

	getnum(Board_ReflectometerState->ideal_averaging,responses[RESPONSE_AVG_NUMBER]);

	SSD1306_ClearDisplayBuffer(SSD1306_ConfigStruct);
	SSD1306_StopProgressBar(SSD1306_ConfigStruct);
	SSD1306_DrawBuffer(SSD1306_ConfigStruct);

	#define NPOINTS 32
	Board_ReflectometerState->start_sample_index=Board_ReflectometerState->rising_edge_start_index;
	Board_ReflectometerState->enable_sampling=OFF;
	Board_ReflectometerState->average_count=0;

	GPIO_WriteBit(LED_PORT, LED_RDY, Bit_SET);
	GPIO_WriteBit(LED_PORT, LED_NOT_RDY, Bit_RESET);

	while(1)
	{
		Board_CalibrationState=CAL_WAIT_DUT;
		SSD1306_ClearDisplayBuffer(SSD1306_ConfigStruct);
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 0, "  Please connect DUT");
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 4, "    Press button");
		SSD1306_DrawProgressBar(SSD1306_ConfigStruct);
		SSD1306_DrawBuffer(SSD1306_ConfigStruct);
		Board_ReflectometerState->average_count=0;
		Wait_For_User_Action();
		GPIO_WriteBit(LED_PORT, LED_RDY, Bit_RESET);
		GPIO_WriteBit(LED_PORT, LED_NOT_RDY, Bit_SET);
		SSD1306_ClearPartialDisplayBuffer(SSD1306_ConfigStruct, 0,5);
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 1, " Measurement running");
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 2, "   Please wait for");
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 3, "    first average");
		SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,0,5);

		Board_CalibrationState=CAL_MEASUREMENT_RUNNING;
		Board_ReflectometerState->enable_sampling=ON;
		while(Board_ReflectometerState->is_running==OFF)
		{
			uint8_t progress=(255*((Board_ReflectometerState->current_sample_index + NUMBER_OF_POINTS - Board_ReflectometerState->start_sample_index) % NUMBER_OF_POINTS))/NUMBER_OF_POINTS;
			SSD1306_DrawMeasurementProgressIndicator(SSD1306_ConfigStruct, progress, Board_ReflectometerState->average_count, Board_ReflectometerState->ideal_averaging);
			SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,6,7);
		}

		while(Board_ReflectometerState->average_count!=Board_ReflectometerState->ideal_averaging)
		{
			while(Board_ReflectometerState->is_running==ON)
			{
				uint8_t progress=(255*((Board_ReflectometerState->current_sample_index + NUMBER_OF_POINTS - Board_ReflectometerState->start_sample_index) % NUMBER_OF_POINTS))/NUMBER_OF_POINTS;
				SSD1306_DrawMeasurementProgressIndicator(SSD1306_ConfigStruct, progress, Board_ReflectometerState->average_count, Board_ReflectometerState->ideal_averaging);
				SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,6,7);
			}
			Board_ReflectometerState->enable_sampling=OFF;

			Board_CalibrationState=CAL_READY_TO_SEND;

			SSD1306_ClearPartialDisplayBuffer(SSD1306_ConfigStruct, 0, 6);

			for(i16=0;i16<=128*NPOINTS;i16++)
			{
				if ((Board_ReflectometerState->sample_cycle_max-Board_ReflectometerState->sample_cycle_min)>=53)
				{
					SSD1306_DrawPixelToBuffer(SSD1306_ConfigStruct, i16/NPOINTS, (Board_ReflectometerState->sampled_data[i16]-Board_ReflectometerState->sample_window_min)/((Board_ReflectometerState->sample_window_max-Board_ReflectometerState->sample_window_min)/52));
				} else {
					SSD1306_DrawPixelToBuffer(SSD1306_ConfigStruct, i16/NPOINTS, (Board_ReflectometerState->sampled_data[i16]-Board_ReflectometerState->sample_window_min));
				}
			}
			SSD1306_DrawBuffer(SSD1306_ConfigStruct);

			if((GPIO_ReadInputDataBit(BTN_PORT,BTN)==RESET)|(remote_user_action==TRUE))
			{
				while(GPIO_ReadInputDataBit(BTN_PORT,BTN)==RESET){}
				remote_user_action=FALSE;
				if(global_response_pending==RESPONSE_SEND_DATA) global_response_pending=NO_RESPONSE_PENDING;
				Board_CalibrationState=CAL_MEASUREMENT_RUNNING;
				Board_ReflectometerState->enable_sampling=OFF;
				Board_ReflectometerState->average_count=0;
				break;
			}

			Board_ReflectometerState->enable_sampling=ON;

			while(Board_ReflectometerState->is_running==OFF)
			{
				uint8_t progress=(255*((Board_ReflectometerState->current_sample_index + NUMBER_OF_POINTS - Board_ReflectometerState->start_sample_index) % NUMBER_OF_POINTS))/NUMBER_OF_POINTS;
				SSD1306_DrawMeasurementProgressIndicator(SSD1306_ConfigStruct, progress, Board_ReflectometerState->average_count, Board_ReflectometerState->ideal_averaging);
				SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,6,7);
				/*if((Remote_Mode==TRUE)&(global_response_pending==RESPONSE_SEND_DATA))
				{
					global_response_pending=RESPONSE_BLOCKING_TRANSFER_PENDING;
					for(i16=0; i16<SAMPLE_MEMORY_SIZE; i16++)
					{
						while (USART_GetFlagStatus(USART1, USART_FLAG_TXE)!=SET){}
						USART_SendData(USART1,(uint8_t)Board_ReflectometerState->sampled_data[i16]);
						while (USART_GetFlagStatus(USART1, USART_FLAG_TXE)!=SET){}
						USART_SendData(USART1,(uint8_t)(Board_ReflectometerState->sampled_data[i16]>>8));
					}
					global_response_pending=NO_RESPONSE_PENDING;
					Board_CalibrationState=CAL_MEASUREMENT_RUNNING;
				}*/
			}
		}

		Board_ReflectometerState->enable_sampling=OFF;

		Board_ReflectometerState->average_count=0;
		GPIO_WriteBit(LED_PORT, LED_RDY, Bit_SET);
		GPIO_WriteBit(LED_PORT, LED_NOT_RDY, Bit_RESET);

		SSD1306_ClearDisplayBuffer(SSD1306_ConfigStruct);
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 1, " Measurement complete");
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 2, "   Please wait for");
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 3, "   data to be sent");
		SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,0,5);
	}
}

void I2C_Board_Init(ForceState Force_Init)
{
	GPIO_InitTypeDef GPIO_Initstruct;
	I2C_InitTypeDef I2C_InitStruct;

	if((I2C_Initialised==FALSE) | (Force_Init==ENABLED))
	{
		I2C_Initialised=TRUE;

		GPIO_Initstruct.GPIO_Pin = SDA | SCL;
		GPIO_Initstruct.GPIO_Mode = GPIO_Mode_AF_OD;
		GPIO_Initstruct.GPIO_Speed = GPIO_Speed_50MHz;

		I2C_StructInit(&I2C_InitStruct);
		I2C_InitStruct.I2C_Ack = I2C_Ack_Disable;
		I2C_InitStruct.I2C_AcknowledgedAddress = I2C_AcknowledgedAddress_7bit;
		I2C_InitStruct.I2C_ClockSpeed = 400000;
		I2C_InitStruct.I2C_DutyCycle = I2C_DutyCycle_2;
		I2C_InitStruct.I2C_Mode = I2C_Mode_I2C;
		I2C_InitStruct.I2C_OwnAddress1 = 0x039;

		RCC_APB1PeriphClockCmd(RCC_APB1Periph_I2C1,  DISABLE);	//reset I2C1
		RCC_APB2PeriphClockCmd(I2C_PERIPH, ENABLE); 			//enable GPIOB clock
		RCC_APB1PeriphClockCmd(RCC_APB1Periph_I2C1,  ENABLE);	//enable I2C1
		GPIO_Init(I2C_PORT, &GPIO_Initstruct);

		I2C_Init(I2C1, &I2C_InitStruct);						//initialize I2C
		I2C_Cmd(I2C1, ENABLE);
	}
}

void I2C_Board_Deinit(ForceState Force_Deinit)
{
	GPIO_InitTypeDef GPIO_InitStruct;
	GPIO_StructInit(&GPIO_InitStruct);

	if((I2C_Initialised==TRUE) | (Force_Deinit==ENABLED))
	{
		I2C_Initialised=FALSE;
		I2C_Cmd(I2C1, DISABLE);
		I2C_DeInit(I2C1);
		RCC_APB1PeriphResetCmd(RCC_APB1Periph_I2C1, ENABLE);
		RCC_APB1PeriphResetCmd(RCC_APB1Periph_I2C1, DISABLE);
		RCC_APB1PeriphClockCmd(RCC_APB1Periph_I2C1, DISABLE);

		GPIO_InitStruct.GPIO_Mode = GPIO_Mode_AIN;
		GPIO_InitStruct.GPIO_Pin = SCL | SDA ;
		GPIO_InitStruct.GPIO_Speed = GPIO_Speed_2MHz;

		GPIO_Init(I2C_PORT, &GPIO_InitStruct);
	}
}

void Button_Init(void)
{
	GPIO_InitTypeDef GPIO_InitStruct;

	GPIO_StructInit(&GPIO_InitStruct);
	RCC_APB2PeriphClockCmd(BTN_PERIPH, ENABLE); //enable GPIOA clock

	GPIO_InitStruct.GPIO_Pin = BTN;
	GPIO_InitStruct.GPIO_Mode = GPIO_Mode_IPU;
	GPIO_InitStruct.GPIO_Speed = GPIO_Speed_2MHz;
	GPIO_Init(BTN_PORT, &GPIO_InitStruct);
	GPIO_WriteBit(BTN_PORT, BTN, Bit_SET);
}

void LED_Init(void)
{
	GPIO_InitTypeDef GPIO_InitStruct;

	GPIO_StructInit(&GPIO_InitStruct);
	RCC_APB2PeriphClockCmd(LED_PERIPH, ENABLE); //enable GPIOA clock

	GPIO_InitStruct.GPIO_Pin = LED_BUSY | LED_RDY | LED_NOT_RDY;
	GPIO_InitStruct.GPIO_Mode = GPIO_Mode_Out_PP;
	GPIO_InitStruct.GPIO_Speed = GPIO_Speed_2MHz;
	GPIO_Init(LED_PORT, &GPIO_InitStruct);
	GPIO_WriteBit(LED_PORT, LED_BUSY, Bit_SET);
	GPIO_WriteBit(LED_PORT, LED_NOT_RDY, Bit_RESET);
	GPIO_WriteBit(LED_PORT, LED_RDY, Bit_SET);
}

void OLED_Init(SSD1306_ConfigTypeDef *SSD1306_ConfigStruct, Framebuffer *display_buffer)
{
	GPIO_InitTypeDef GPIO_InitStruct;
	RCC_APB2PeriphClockCmd(nOLED_RESET_PERIPH, ENABLE); //enable GPIOA clock

	GPIO_InitStruct.GPIO_Pin = nOLED_RESET;
	GPIO_InitStruct.GPIO_Mode = GPIO_Mode_Out_PP;
	GPIO_InitStruct.GPIO_Speed = GPIO_Speed_2MHz;

	GPIO_Init(nOLED_RESET_PORT, &GPIO_InitStruct);

	I2C_Board_Init(DISABLED);

	OLED_Reset();

	GPIO_WriteBit(nPLL_OE_PORT, nPLL_OE, Bit_RESET);

	SSD1306_StructInit(SSD1306_ConfigStruct, DisplayModel_UG2864KSWEG01);
	SSD1306_ConfigStruct->SSD1306_Framebuffer=display_buffer;
	SSD1306_ConfigStruct->Display_Polarity=DisplayPolarity_Normal;
	SSD1306_ConfigStruct->Display_Contrast = 128;
	SSD1306_ConfigStruct->HW_VCOMHLevel=VCOMHLevel_065;

	SSD1306_Init(SSD1306_ConfigStruct);
			//start OLED
	SSD1306_ClearDisplayBuffer(SSD1306_ConfigStruct);
	SSD1306_DrawBuffer(SSD1306_ConfigStruct);
}

void OLED_Reset(void)
{
	GPIO_WriteBit(nOLED_RESET_PORT, nOLED_RESET, Bit_RESET);
	Delay_ms(2);
	GPIO_WriteBit(nOLED_RESET_PORT, nOLED_RESET, Bit_SET);
}

void Si5351_Board_Init(Si5351_ConfigTypeDef *Si5351_ConfigStruct)
{
	GPIO_InitTypeDef GPIO_InitStruct;
	RCC_APB2PeriphClockCmd(nPLL_OE_PERIPH, ENABLE); //enable GPIOB clock
	RCC_APB2PeriphClockCmd(nPLL_INT_PERIPH, ENABLE); //enable GPIOB clock

	GPIO_InitStruct.GPIO_Pin = nPLL_OE;
	GPIO_InitStruct.GPIO_Mode = GPIO_Mode_Out_PP;
	GPIO_InitStruct.GPIO_Speed = GPIO_Speed_2MHz;

	GPIO_Init(nPLL_OE_PORT, &GPIO_InitStruct);

	GPIO_InitStruct.GPIO_Pin = nPLL_INT;
	GPIO_InitStruct.GPIO_Mode = GPIO_Mode_IPU;
	GPIO_InitStruct.GPIO_Speed = GPIO_Speed_2MHz;

	GPIO_Init(nPLL_INT_PORT, &GPIO_InitStruct);


	Si5351_StructInit(Si5351_ConfigStruct);
	/*---------------------------------------------------------------------------------------*/
	Si5351_ConfigStruct->Interrupt_Mask_CLKIN = ON;
	Si5351_ConfigStruct->Interrupt_Mask_PLLA = OFF;
	Si5351_ConfigStruct->Interrupt_Mask_PLLB = OFF;
	Si5351_ConfigStruct->Interrupt_Mask_SysInit = OFF;
	Si5351_ConfigStruct->Interrupt_Mask_XTAL = OFF;

	Si5351_ConfigStruct->OSC.OSC_XTAL_Load = XTAL_Load_8_pF;
	/*---------------------------------------------------------------------------------------*/
	Si5351_ConfigStruct->PLL[PLL_A].PLL_Multiplier_Integer = 24;
	Si5351_ConfigStruct->PLL[PLL_A].PLL_Multiplier_Numerator = 24 >> 3;
	Si5351_ConfigStruct->PLL[PLL_A].PLL_Multiplier_Denominator = NUMBER_OF_POINTS >> 3;
	Si5351_ConfigStruct->PLL[PLL_A].PLL_Capacitive_Load = PLL_Capacitive_Load_0;

	Si5351_ConfigStruct->PLL[PLL_B].PLL_Multiplier_Integer = Si5351_ConfigStruct->PLL[PLL_A].PLL_Multiplier_Integer;
	Si5351_ConfigStruct->PLL[PLL_B].PLL_Multiplier_Numerator = 0;
	Si5351_ConfigStruct->PLL[PLL_B].PLL_Multiplier_Denominator = 1;
	Si5351_ConfigStruct->PLL[PLL_B].PLL_Capacitive_Load = Si5351_ConfigStruct->PLL[PLL_A].PLL_Capacitive_Load ;
	/*---------------------------------------------------------------------------------------*/
	Si5351_ConfigStruct->MS[CH_MAINSAMP_P].MS_Clock_Source = MS_Clock_Source_PLLB;
	Si5351_ConfigStruct->MS[CH_MAINSAMP_P].MS_Divider_Integer = INT_DIVIDER;
	Si5351_ConfigStruct->MS[CH_MAINSAMP_P].MS_Divider_Numerator = 0;
	Si5351_ConfigStruct->MS[CH_MAINSAMP_P].MS_Divider_Denominator = 1;

	Si5351_ConfigStruct->CLK[CH_MAINSAMP_P].CLK_Clock_Source = CLK_Clock_Source_MS_Own;
	Si5351_ConfigStruct->CLK[CH_MAINSAMP_P].CLK_Disable_State = CLK_Disable_State_LOW;
	Si5351_ConfigStruct->CLK[CH_MAINSAMP_P].CLK_Enable = OFF;
	Si5351_ConfigStruct->CLK[CH_MAINSAMP_P].CLK_I_Drv = CLK_I_Drv_8mA;
	Si5351_ConfigStruct->CLK[CH_MAINSAMP_P].CLK_Invert = OFF;
	Si5351_ConfigStruct->CLK[CH_MAINSAMP_P].CLK_QuarterPeriod_Offset = 127;
	Si5351_ConfigStruct->CLK[CH_MAINSAMP_P].CLK_R_Div = CLK_R_Div128;
	Si5351_ConfigStruct->CLK[CH_MAINSAMP_P].CLK_Use_OEB_Pin = OFF;

	Si5351_ConfigStruct->MS[CH_MAINSAMP_N].MS_Clock_Source = Si5351_ConfigStruct->MS[CH_MAINSAMP_P].MS_Clock_Source;
	Si5351_ConfigStruct->MS[CH_MAINSAMP_N].MS_Divider_Integer = Si5351_ConfigStruct->MS[CH_MAINSAMP_P].MS_Divider_Integer;
	Si5351_ConfigStruct->MS[CH_MAINSAMP_N].MS_Divider_Numerator = Si5351_ConfigStruct->MS[CH_MAINSAMP_P].MS_Divider_Numerator;
	Si5351_ConfigStruct->MS[CH_MAINSAMP_N].MS_Divider_Denominator = Si5351_ConfigStruct->MS[CH_MAINSAMP_P].MS_Divider_Denominator;

	Si5351_ConfigStruct->CLK[CH_MAINSAMP_N].CLK_Clock_Source = Si5351_ConfigStruct->CLK[CH_MAINSAMP_P].CLK_Clock_Source;
	Si5351_ConfigStruct->CLK[CH_MAINSAMP_N].CLK_Disable_State = (Si5351_ConfigStruct->CLK[CH_MAINSAMP_P].CLK_Disable_State == CLK_Disable_State_HIGH) ? CLK_Disable_State_LOW : CLK_Disable_State_HIGH;
	Si5351_ConfigStruct->CLK[CH_MAINSAMP_N].CLK_Enable = Si5351_ConfigStruct->CLK[CH_MAINSAMP_P].CLK_Enable;
	Si5351_ConfigStruct->CLK[CH_MAINSAMP_N].CLK_I_Drv = Si5351_ConfigStruct->CLK[CH_MAINSAMP_P].CLK_I_Drv;
	Si5351_ConfigStruct->CLK[CH_MAINSAMP_N].CLK_Invert = (Si5351_ConfigStruct->CLK[CH_MAINSAMP_P].CLK_Invert == OFF)?ON:OFF;
	Si5351_ConfigStruct->CLK[CH_MAINSAMP_N].CLK_QuarterPeriod_Offset = Si5351_ConfigStruct->CLK[CH_MAINSAMP_P].CLK_QuarterPeriod_Offset;
	Si5351_ConfigStruct->CLK[CH_MAINSAMP_N].CLK_R_Div = Si5351_ConfigStruct->CLK[CH_MAINSAMP_P].CLK_R_Div;
	Si5351_ConfigStruct->CLK[CH_MAINSAMP_N].CLK_Use_OEB_Pin = Si5351_ConfigStruct->CLK[CH_MAINSAMP_P].CLK_Use_OEB_Pin;
	/*---------------------------------------------------------------------------------------*/

	Si5351_ConfigStruct->MS[CH_SLAVESAMP_P].MS_Clock_Source = MS_Clock_Source_PLLB;
	Si5351_ConfigStruct->MS[CH_SLAVESAMP_P].MS_Divider_Integer = INT_DIVIDER;
	Si5351_ConfigStruct->MS[CH_SLAVESAMP_P].MS_Divider_Numerator = 0;
	Si5351_ConfigStruct->MS[CH_SLAVESAMP_P].MS_Divider_Denominator = 1;

	Si5351_ConfigStruct->CLK[CH_SLAVESAMP_P].CLK_Clock_Source = CLK_Clock_Source_MS_Own;
	Si5351_ConfigStruct->CLK[CH_SLAVESAMP_P].CLK_Disable_State = CLK_Disable_State_LOW;
	Si5351_ConfigStruct->CLK[CH_SLAVESAMP_P].CLK_Enable = OFF;
	Si5351_ConfigStruct->CLK[CH_SLAVESAMP_P].CLK_I_Drv = CLK_I_Drv_8mA;
	Si5351_ConfigStruct->CLK[CH_SLAVESAMP_P].CLK_Invert = ON;
	Si5351_ConfigStruct->CLK[CH_SLAVESAMP_P].CLK_QuarterPeriod_Offset = 0;
	Si5351_ConfigStruct->CLK[CH_SLAVESAMP_P].CLK_R_Div = CLK_R_Div128;
	Si5351_ConfigStruct->CLK[CH_SLAVESAMP_P].CLK_Use_OEB_Pin = OFF;

	Si5351_ConfigStruct->MS[CH_SLAVESAMP_N].MS_Clock_Source = Si5351_ConfigStruct->MS[CH_SLAVESAMP_P].MS_Clock_Source;
	Si5351_ConfigStruct->MS[CH_SLAVESAMP_N].MS_Divider_Integer = Si5351_ConfigStruct->MS[CH_SLAVESAMP_P].MS_Divider_Integer;
	Si5351_ConfigStruct->MS[CH_SLAVESAMP_N].MS_Divider_Numerator = Si5351_ConfigStruct->MS[CH_SLAVESAMP_P].MS_Divider_Numerator;
	Si5351_ConfigStruct->MS[CH_SLAVESAMP_N].MS_Divider_Denominator = Si5351_ConfigStruct->MS[CH_SLAVESAMP_P].MS_Divider_Denominator;

	Si5351_ConfigStruct->CLK[CH_SLAVESAMP_N].CLK_Clock_Source = Si5351_ConfigStruct->CLK[CH_SLAVESAMP_P].CLK_Clock_Source;
	Si5351_ConfigStruct->CLK[CH_SLAVESAMP_N].CLK_Disable_State = (Si5351_ConfigStruct->CLK[CH_SLAVESAMP_P].CLK_Disable_State == CLK_Disable_State_HIGH) ? CLK_Disable_State_LOW : CLK_Disable_State_HIGH;
	Si5351_ConfigStruct->CLK[CH_SLAVESAMP_N].CLK_Enable = Si5351_ConfigStruct->CLK[CH_SLAVESAMP_P].CLK_Enable;
	Si5351_ConfigStruct->CLK[CH_SLAVESAMP_N].CLK_I_Drv = Si5351_ConfigStruct->CLK[CH_SLAVESAMP_P].CLK_I_Drv;
	Si5351_ConfigStruct->CLK[CH_SLAVESAMP_N].CLK_Invert = (Si5351_ConfigStruct->CLK[CH_SLAVESAMP_P].CLK_Invert == OFF)?ON:OFF;
	Si5351_ConfigStruct->CLK[CH_SLAVESAMP_N].CLK_QuarterPeriod_Offset = Si5351_ConfigStruct->CLK[CH_SLAVESAMP_P].CLK_QuarterPeriod_Offset;
	Si5351_ConfigStruct->CLK[CH_SLAVESAMP_N].CLK_R_Div = Si5351_ConfigStruct->CLK[CH_SLAVESAMP_P].CLK_R_Div;
	Si5351_ConfigStruct->CLK[CH_SLAVESAMP_N].CLK_Use_OEB_Pin = Si5351_ConfigStruct->CLK[CH_SLAVESAMP_P].CLK_Use_OEB_Pin;
	/*---------------------------------------------------------------------------------------*/

	Si5351_ConfigStruct->MS[CH_nCML_OE].MS_Clock_Source = MS_Clock_Source_PLLA;
	Si5351_ConfigStruct->MS[CH_nCML_OE].MS_Divider_Integer = INT_DIVIDER;
	Si5351_ConfigStruct->MS[CH_nCML_OE].MS_Divider_Numerator = 0;
	Si5351_ConfigStruct->MS[CH_nCML_OE].MS_Divider_Denominator = 1;

	Si5351_ConfigStruct->CLK[CH_nCML_OE].CLK_Clock_Source = CLK_Clock_Source_MS_Own;
	Si5351_ConfigStruct->CLK[CH_nCML_OE].CLK_Disable_State = CLK_Disable_State_HIGH;
	Si5351_ConfigStruct->CLK[CH_nCML_OE].CLK_Enable = OFF;
	Si5351_ConfigStruct->CLK[CH_nCML_OE].CLK_I_Drv = CLK_I_Drv_8mA;
	Si5351_ConfigStruct->CLK[CH_nCML_OE].CLK_Invert = OFF;
	Si5351_ConfigStruct->CLK[CH_nCML_OE].CLK_QuarterPeriod_Offset = 0;
	Si5351_ConfigStruct->CLK[CH_nCML_OE].CLK_R_Div = CLK_R_Div128;
	Si5351_ConfigStruct->CLK[CH_nCML_OE].CLK_Use_OEB_Pin = ON;
	/*---------------------------------------------------------------------------------------*/

	Si5351_ConfigStruct->MS[CH_PULSE_P].MS_Clock_Source = MS_Clock_Source_PLLA;
	Si5351_ConfigStruct->MS[CH_PULSE_P].MS_Divider_Integer = INT_DIVIDER;
	Si5351_ConfigStruct->MS[CH_PULSE_P].MS_Divider_Numerator = 0;
	Si5351_ConfigStruct->MS[CH_PULSE_P].MS_Divider_Denominator = 1;

	Si5351_ConfigStruct->CLK[CH_PULSE_P].CLK_Clock_Source = CLK_Clock_Source_MS_Own;
	Si5351_ConfigStruct->CLK[CH_PULSE_P].CLK_Disable_State = CLK_Disable_State_HIGH;
	Si5351_ConfigStruct->CLK[CH_PULSE_P].CLK_Enable = OFF;
	Si5351_ConfigStruct->CLK[CH_PULSE_P].CLK_I_Drv = CLK_I_Drv_8mA;
	Si5351_ConfigStruct->CLK[CH_PULSE_P].CLK_Invert = OFF;
	Si5351_ConfigStruct->CLK[CH_PULSE_P].CLK_QuarterPeriod_Offset = 0;
	Si5351_ConfigStruct->CLK[CH_PULSE_P].CLK_R_Div = CLK_R_Div128;
	Si5351_ConfigStruct->CLK[CH_PULSE_P].CLK_Use_OEB_Pin = OFF;

	Si5351_ConfigStruct->MS[CH_PULSE_N].MS_Clock_Source = Si5351_ConfigStruct->MS[CH_PULSE_P].MS_Clock_Source;
	Si5351_ConfigStruct->MS[CH_PULSE_N].MS_Divider_Integer = Si5351_ConfigStruct->MS[CH_PULSE_P].MS_Divider_Integer;
	Si5351_ConfigStruct->MS[CH_PULSE_N].MS_Divider_Numerator = Si5351_ConfigStruct->MS[CH_PULSE_P].MS_Divider_Numerator;
	Si5351_ConfigStruct->MS[CH_PULSE_N].MS_Divider_Denominator = Si5351_ConfigStruct->MS[CH_PULSE_P].MS_Divider_Denominator;

	Si5351_ConfigStruct->CLK[CH_PULSE_N].CLK_Clock_Source = Si5351_ConfigStruct->CLK[CH_PULSE_P].CLK_Clock_Source;
	Si5351_ConfigStruct->CLK[CH_PULSE_N].CLK_Disable_State = (Si5351_ConfigStruct->CLK[CH_PULSE_P].CLK_Disable_State == CLK_Disable_State_HIGH) ? CLK_Disable_State_LOW : CLK_Disable_State_HIGH;
	Si5351_ConfigStruct->CLK[CH_PULSE_N].CLK_Enable = Si5351_ConfigStruct->CLK[CH_PULSE_P].CLK_Enable;
	Si5351_ConfigStruct->CLK[CH_PULSE_N].CLK_I_Drv = Si5351_ConfigStruct->CLK[CH_PULSE_P].CLK_I_Drv;
	Si5351_ConfigStruct->CLK[CH_PULSE_N].CLK_Invert = (Si5351_ConfigStruct->CLK[CH_PULSE_P].CLK_Invert == OFF)?ON:OFF;
	Si5351_ConfigStruct->CLK[CH_PULSE_N].CLK_QuarterPeriod_Offset = Si5351_ConfigStruct->CLK[CH_PULSE_P].CLK_QuarterPeriod_Offset;
	Si5351_ConfigStruct->CLK[CH_PULSE_N].CLK_R_Div = Si5351_ConfigStruct->CLK[CH_PULSE_P].CLK_R_Div;
	Si5351_ConfigStruct->CLK[CH_PULSE_N].CLK_Use_OEB_Pin = Si5351_ConfigStruct->CLK[CH_PULSE_P].CLK_Use_OEB_Pin;
	/*---------------------------------------------------------------------------------------*/

	Si5351_ConfigStruct->MS[CH_ADC_TRIGGER].MS_Clock_Source = MS_Clock_Source_PLLB;
	Si5351_ConfigStruct->MS[CH_ADC_TRIGGER].MS_Divider_Integer = INT_DIVIDER;
	Si5351_ConfigStruct->MS[CH_ADC_TRIGGER].MS_Divider_Numerator = 0;
	Si5351_ConfigStruct->MS[CH_ADC_TRIGGER].MS_Divider_Denominator = 1;

	Si5351_ConfigStruct->CLK[CH_ADC_TRIGGER].CLK_Clock_Source = CLK_Clock_Source_MS_Own;
	Si5351_ConfigStruct->CLK[CH_ADC_TRIGGER].CLK_Disable_State = CLK_Disable_State_HIGH_Z;
	Si5351_ConfigStruct->CLK[CH_ADC_TRIGGER].CLK_Enable = OFF;
	Si5351_ConfigStruct->CLK[CH_ADC_TRIGGER].CLK_I_Drv = CLK_I_Drv_2mA;
	Si5351_ConfigStruct->CLK[CH_ADC_TRIGGER].CLK_Invert = ON;
	Si5351_ConfigStruct->CLK[CH_ADC_TRIGGER].CLK_QuarterPeriod_Offset = 0;
	Si5351_ConfigStruct->CLK[CH_ADC_TRIGGER].CLK_R_Div = CLK_R_Div128;
	Si5351_ConfigStruct->CLK[CH_ADC_TRIGGER].CLK_Use_OEB_Pin = OFF;

	Si5351_Init(Si5351_ConfigStruct);
	Delay_ms(50);
	Si5351_PLLSimultaneousReset(Si5351_ConfigStruct);
}

void SY54020_Init(void)
{

}

void MCP4725_Init(void)
{
	MCP4725_SetVoltage(0x0800);
}

void ReflectometerMode_Init(Si5351_ConfigTypeDef *Si5351_ConfigStruct, Board_ReflectometerModeTypeDef mode)
{
	uint8_t i;

	//default "Run mode settings"
	Si5351_ConfigStruct->CLK[CH_MAINSAMP_P].CLK_Disable_State = CLK_Disable_State_LOW;
	Si5351_ConfigStruct->CLK[CH_MAINSAMP_P].CLK_Enable = ON;
	Si5351_ConfigStruct->CLK[CH_MAINSAMP_P].CLK_Use_OEB_Pin = ON;

	Si5351_ConfigStruct->CLK[CH_SLAVESAMP_P].CLK_Disable_State = CLK_Disable_State_LOW;
	Si5351_ConfigStruct->CLK[CH_SLAVESAMP_P].CLK_Enable = ON;
	Si5351_ConfigStruct->CLK[CH_SLAVESAMP_P].CLK_Use_OEB_Pin = ON;

	Si5351_ConfigStruct->CLK[CH_PULSE_P].CLK_Disable_State = CLK_Disable_State_LOW;
	Si5351_ConfigStruct->CLK[CH_PULSE_P].CLK_Enable = ON;
	Si5351_ConfigStruct->CLK[CH_PULSE_P].CLK_Use_OEB_Pin = ON;

	Si5351_ConfigStruct->CLK[CH_nCML_OE].CLK_Disable_State = CLK_Disable_State_HIGH;
	Si5351_ConfigStruct->CLK[CH_nCML_OE].CLK_Enable = OFF;	//it is used as general-purpose output
	Si5351_ConfigStruct->CLK[CH_nCML_OE].CLK_Use_OEB_Pin = ON;

	Si5351_ConfigStruct->CLK[CH_ADC_TRIGGER].CLK_Disable_State = CLK_Disable_State_HIGH;
	Si5351_ConfigStruct->CLK[CH_ADC_TRIGGER].CLK_Enable = ON;
	Si5351_ConfigStruct->CLK[CH_ADC_TRIGGER].CLK_Use_OEB_Pin = OFF;

	switch(mode)
	{
		case ReflectometerMode_Run:
			break;

		case ReflectometerMode_Test_Risetime_Disconnected_Sampler:
			Si5351_ConfigStruct->CLK[CH_MAINSAMP_P].CLK_Enable = OFF;
			Si5351_ConfigStruct->CLK[CH_MAINSAMP_P].CLK_Disable_State = CLK_Disable_State_HIGH;
			break;

		case ReflectometerMode_Test_Risetime_Connected_Sampler:
			Si5351_ConfigStruct->CLK[CH_MAINSAMP_P].CLK_Enable = OFF;
			Si5351_ConfigStruct->CLK[CH_MAINSAMP_P].CLK_Disable_State = CLK_Disable_State_LOW;
			break;

		case ReflectometerMode_Test_ReturnLoss_Disconnected_Sampler:
			Si5351_ConfigStruct->CLK[CH_MAINSAMP_P].CLK_Enable = OFF;
			Si5351_ConfigStruct->CLK[CH_PULSE_P].CLK_Enable = OFF;
			Si5351_ConfigStruct->CLK[CH_MAINSAMP_P].CLK_Disable_State = CLK_Disable_State_HIGH;
			Si5351_ConfigStruct->CLK[CH_PULSE_P].CLK_Disable_State = CLK_Disable_State_LOW;
			break;

		case ReflectometerMode_Test_ReturnLoss_Connected_Sampler:
			Si5351_ConfigStruct->CLK[CH_MAINSAMP_P].CLK_Enable = OFF;
			Si5351_ConfigStruct->CLK[CH_SLAVESAMP_P].CLK_Enable = OFF;
			Si5351_ConfigStruct->CLK[CH_PULSE_P].CLK_Enable = OFF;
			Si5351_ConfigStruct->CLK[CH_MAINSAMP_P].CLK_Disable_State = CLK_Disable_State_LOW;
			Si5351_ConfigStruct->CLK[CH_SLAVESAMP_P].CLK_Disable_State = CLK_Disable_State_LOW;
			Si5351_ConfigStruct->CLK[CH_PULSE_P].CLK_Disable_State = CLK_Disable_State_LOW;
			break;

		case ReflectometerMode_Calibrate_Sampler_HIGH:
		case ReflectometerMode_Calibrate_Log_Detector:
			Si5351_ConfigStruct->CLK[CH_PULSE_P].CLK_Enable = OFF;
			Si5351_ConfigStruct->CLK[CH_PULSE_P].CLK_Disable_State = CLK_Disable_State_LOW;
			break;

		case ReflectometerMode_Calibrate_Sampler_LOW:
			Si5351_ConfigStruct->CLK[CH_PULSE_P].CLK_Enable = OFF;
			Si5351_ConfigStruct->CLK[CH_PULSE_P].CLK_Disable_State = CLK_Disable_State_HIGH;
			break;

		case ReflectometerMode_Stop:
			Si5351_ConfigStruct->CLK[CH_MAINSAMP_P].CLK_Enable = OFF;
			Si5351_ConfigStruct->CLK[CH_SLAVESAMP_P].CLK_Enable = OFF;
			Si5351_ConfigStruct->CLK[CH_PULSE_P].CLK_Enable = OFF;
			Si5351_ConfigStruct->CLK[CH_ADC_TRIGGER].CLK_Enable = OFF;
			Si5351_ConfigStruct->CLK[CH_MAINSAMP_P].CLK_Disable_State = CLK_Disable_State_HIGH_Z;
			Si5351_ConfigStruct->CLK[CH_SLAVESAMP_P].CLK_Disable_State = CLK_Disable_State_HIGH_Z;
			Si5351_ConfigStruct->CLK[CH_PULSE_P].CLK_Disable_State = CLK_Disable_State_HIGH_Z;
			Si5351_ConfigStruct->CLK[CH_ADC_TRIGGER].CLK_Disable_State = CLK_Disable_State_HIGH_Z;
			break;
	}

	Si5351_ConfigStruct->CLK[CH_MAINSAMP_N].CLK_Disable_State = (Si5351_ConfigStruct->CLK[CH_MAINSAMP_P].CLK_Disable_State == CLK_Disable_State_HIGH) ? CLK_Disable_State_LOW : CLK_Disable_State_HIGH;;
	Si5351_ConfigStruct->CLK[CH_MAINSAMP_N].CLK_Enable = Si5351_ConfigStruct->CLK[CH_MAINSAMP_P].CLK_Enable;
	Si5351_ConfigStruct->CLK[CH_MAINSAMP_N].CLK_Use_OEB_Pin = Si5351_ConfigStruct->CLK[CH_MAINSAMP_P].CLK_Use_OEB_Pin;

	Si5351_ConfigStruct->CLK[CH_SLAVESAMP_N].CLK_Disable_State = (Si5351_ConfigStruct->CLK[CH_SLAVESAMP_P].CLK_Disable_State == CLK_Disable_State_HIGH) ? CLK_Disable_State_LOW : CLK_Disable_State_HIGH;;
	Si5351_ConfigStruct->CLK[CH_SLAVESAMP_N].CLK_Enable = Si5351_ConfigStruct->CLK[CH_SLAVESAMP_P].CLK_Enable;
	Si5351_ConfigStruct->CLK[CH_SLAVESAMP_N].CLK_Use_OEB_Pin = Si5351_ConfigStruct->CLK[CH_SLAVESAMP_P].CLK_Use_OEB_Pin;

	Si5351_ConfigStruct->CLK[CH_PULSE_N].CLK_Disable_State = (Si5351_ConfigStruct->CLK[CH_PULSE_P].CLK_Disable_State == CLK_Disable_State_HIGH) ? CLK_Disable_State_LOW : CLK_Disable_State_HIGH;;
	Si5351_ConfigStruct->CLK[CH_PULSE_N].CLK_Enable = Si5351_ConfigStruct->CLK[CH_PULSE_P].CLK_Enable;
	Si5351_ConfigStruct->CLK[CH_PULSE_N].CLK_Use_OEB_Pin = Si5351_ConfigStruct->CLK[CH_PULSE_P].CLK_Use_OEB_Pin;

	if (mode == ReflectometerMode_Stop)
	{
		Si5351_ConfigStruct->CLK[CH_MAINSAMP_N].CLK_Enable = OFF;
		Si5351_ConfigStruct->CLK[CH_SLAVESAMP_N].CLK_Enable = OFF;
		Si5351_ConfigStruct->CLK[CH_PULSE_N].CLK_Enable = OFF;
		Si5351_ConfigStruct->CLK[CH_MAINSAMP_N].CLK_Disable_State = CLK_Disable_State_HIGH_Z;
		Si5351_ConfigStruct->CLK[CH_SLAVESAMP_N].CLK_Disable_State = CLK_Disable_State_HIGH_Z;
		Si5351_ConfigStruct->CLK[CH_PULSE_N].CLK_Disable_State = CLK_Disable_State_HIGH_Z;
	}

	for(i=0; i<=7; i++)
	{
		Si5351_CLKPowerCmd(Si5351_ConfigStruct,i);
	}
}

void SSD1306_DrawProgressBar(SSD1306_ConfigTypeDef *SSD1306_ConfigStruct)
{
	uint8_t i,i2;
	uint8_t start_row=54, stop_row=63, border_thickness=1, border_separation=1;

	SSD1306_ConfigStruct->Scroll_Fixed_Rows=0;
	SSD1306_ConfigStruct->Scroll_Scrolling_Rows=63;
	SSD1306_ConfigStruct->Scroll_Frameskip=7;
	SSD1306_ConfigStruct->Scroll_Mode=ScrollMode_Horizontal_Right;
	SSD1306_ConfigStruct->Scroll_Start_Page=6;
	SSD1306_ConfigStruct->Scroll_Stop_Page=7;
	SSD1306_ConfigStruct->Scroll_Vertical_Offset=0;
	SSD1306_ConfigStruct->Scroll_State=OFF;

	for (i=start_row+border_thickness+border_separation; i<=stop_row-border_thickness-border_separation; i++) SSD1306_DrawLine(SSD1306_ConfigStruct, 0,i,127,i);

	SSD1306_ConfigStruct->GR_DrawMethod=DrawMethod_OFF;
	#define N_DIV 8
	for (i=0; i<=N_DIV; i++)
		{
			for(i2=0; i2<=3; i2++)
			{
				SSD1306_DrawLine(SSD1306_ConfigStruct, (128/N_DIV)*i+i2+3,start_row+border_thickness+border_separation,(128/N_DIV)*i+i2,stop_row-border_thickness-border_separation);
			}
		}
	SSD1306_ConfigStruct->GR_DrawMethod=DrawMethod_Straight;

	for(i=start_row; i<start_row+border_thickness; i++) SSD1306_DrawLine(SSD1306_ConfigStruct, 0,i,127,i);

	for(i=stop_row-border_thickness+1; i<=stop_row; i++) SSD1306_DrawLine(SSD1306_ConfigStruct, 0,i,127,i);
}

void SSD1306_DrawProgressIndicator(SSD1306_ConfigTypeDef *SSD1306_ConfigStruct, uint8_t progress)
{
	uint8_t i;
	uint8_t start_row=54, stop_row=63, border_thickness=1, border_separation=1;

	SSD1306_ConfigStruct->GR_DrawMethod=DrawMethod_OFF;
	for(i=start_row; i<=stop_row; i++) SSD1306_DrawLine(SSD1306_ConfigStruct, 0,i,127,i);

	SSD1306_ConfigStruct->GR_DrawMethod=DrawMethod_Straight;
	SSD1306_DrawLine(SSD1306_ConfigStruct, 0,start_row,127,start_row);
	SSD1306_DrawLine(SSD1306_ConfigStruct, 0,stop_row,127,stop_row);
	SSD1306_DrawLine(SSD1306_ConfigStruct, 0,start_row,0,stop_row);
	SSD1306_DrawLine(SSD1306_ConfigStruct, 127,start_row,127,stop_row);

	for(i=start_row+border_thickness+border_separation; i<=stop_row-border_thickness-border_separation; i++) SSD1306_DrawLine(SSD1306_ConfigStruct, 2,i,2+((uint16_t)progress*124)/255,i);
}

void SSD1306_DrawMeasurementProgressIndicator(SSD1306_ConfigTypeDef *SSD1306_ConfigStruct, uint8_t progress, uint8_t run, uint8_t run_number)
{
	uint8_t i;
	uint8_t start_row=54, stop_row=63, border_thickness=1, border_separation=1;
	char str[6];

	SSD1306_ConfigStruct->GR_DrawMethod=DrawMethod_OFF;
	for(i=start_row; i<=stop_row; i++) SSD1306_DrawLine(SSD1306_ConfigStruct, 0,i,127,i);

	SSD1306_ConfigStruct->GR_DrawMethod=DrawMethod_Straight;
	uint8_t shift=0;
	if(run_number<10) shift=1;
	getnum(run_number, str);
	SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 127-5*6, 7, str);
	getnum(run, str);
	SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 127-3*6+shift*6, 7, "/");
	SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 127-8*6+shift*6, 7, str);

	SSD1306_DrawLine(SSD1306_ConfigStruct, 0,start_row,95+shift*6*2,start_row);
	SSD1306_DrawLine(SSD1306_ConfigStruct, 0,stop_row,95+shift*6*2,stop_row);
	SSD1306_DrawLine(SSD1306_ConfigStruct, 0,start_row,0,stop_row);
	SSD1306_DrawLine(SSD1306_ConfigStruct, 95+shift*6*2,start_row,95+shift*6*2,stop_row);

	for(i=start_row+border_thickness+border_separation; i<=stop_row-border_thickness-border_separation; i++) SSD1306_DrawLine(SSD1306_ConfigStruct, 2,i,2+((uint16_t)progress*(92+shift*6*2))/255,i);
}

void SSD1306_StartProgressBar(SSD1306_ConfigTypeDef *SSD1306_ConfigStruct)
{
	SSD1306_ConfigStruct->Scroll_State=ON;
	SSD1306_ScrollInit(SSD1306_ConfigStruct);
}

void SSD1306_StopProgressBar(SSD1306_ConfigTypeDef *SSD1306_ConfigStruct)
{
	SSD1306_ConfigStruct->Scroll_State=OFF;
	SSD1306_ScrollInit(SSD1306_ConfigStruct);
}

int MCP4725_SetVoltage(uint16_t data_code)
{
	uint32_t error_wait;

	error_wait = I2C_TIMEOUT;
	while (I2C_GetFlagStatus(I2C1, I2C_FLAG_BUSY) == SET)
	{
		error_wait--;
		if (error_wait==0)
		{
			I2C_SoftwareResetCmd(I2C1, ENABLE);
			I2C_SoftwareResetCmd(I2C1, DISABLE);
			return 1;
		}
	}
	//wait for I2C to get ready, if not ready in time, reset I2C and return

	I2C_GenerateSTART(I2C1, ENABLE);
	//send START condition

	error_wait = I2C_TIMEOUT;
	while (I2C_CheckEvent(I2C1, I2C_EVENT_MASTER_MODE_SELECT) == ERROR)
	{
		error_wait--;
		if (error_wait==0) return 1;
	}
	//wait for START to be sent, if not sent in time, return

	I2C_Send7bitAddress(I2C1, MCP4725_ADDRESS, I2C_Direction_Transmitter);
	//send address+RW bit

	error_wait = I2C_TIMEOUT;
	while (I2C_CheckEvent(I2C1, I2C_EVENT_MASTER_TRANSMITTER_MODE_SELECTED) == ERROR)
	{
		error_wait--;
		if (error_wait==0) return 1;
	}
	//wait for address to be sent, if not sent in time, return

	I2C_SendData(I2C1, 0x0F & (uint8_t)(data_code >> 8));
	//send upper byte of DAC value

	error_wait = I2C_TIMEOUT;
	while (I2C_CheckEvent(I2C1, I2C_EVENT_MASTER_BYTE_TRANSMITTED) == ERROR)
	{
		error_wait--;
		if (error_wait==0) return 1;
	}
	//wait for upper byte of DAC value to be sent

	I2C_SendData(I2C1, (uint8_t)data_code);
	//send lower byte of DAC value

	error_wait = I2C_TIMEOUT;
	while (I2C_CheckEvent(I2C1, I2C_EVENT_MASTER_BYTE_TRANSMITTED) == ERROR)
	{
		error_wait--;
		if (error_wait==0) return 1;
	}
	//wait for lower byte of DAC value to be sent, if not sent in time, return

	I2C_GenerateSTOP(I2C1, ENABLE);
	//generate STOP condition

	error_wait = I2C_TIMEOUT;
	while (I2C_GetFlagStatus(I2C1, I2C_FLAG_STOPF))
	{
		error_wait--;
		if (error_wait==0) return 1;
	}
	//wait until STOP is cleared

	return 0;
}

void ADC_BoardInit(void)
{
	ADC_InitTypeDef ADC_InitStruct;
	GPIO_InitTypeDef GPIO_InitStruct;
	EXTI_InitTypeDef EXTI_InitStruct;
	NVIC_InitTypeDef NVIC_InitStruct;

	GPIO_InitStruct.GPIO_Mode=GPIO_Mode_AIN;	//set analog pins as analog inputs
	GPIO_InitStruct.GPIO_Pin = OUT_REF | OUT_LOG | OUT_LIN;
	GPIO_Init(OUT_PORT, &GPIO_InitStruct);

	GPIO_InitStruct.GPIO_Mode=GPIO_Mode_IPD;	//set trigger input as floating input
	GPIO_InitStruct.GPIO_Pin = ADC_TRG;
	GPIO_Init(ADC_TRG_PORT, &GPIO_InitStruct);

	RCC_APB2PeriphClockCmd(RCC_APB2Periph_AFIO, ENABLE);	//enable AFIO because the trigger uses EXTI11
	GPIO_PinRemapConfig(GPIO_Remap_ADC1_ETRGREG, DISABLE);	//trigger mapped to EXTI11
	GPIO_PinRemapConfig(GPIO_Remap_ADC2_ETRGREG, DISABLE);
	GPIO_EXTILineConfig(ADC_TRG_PORTSOURCE, ADC_TRG_PINSOURCE);

	EXTI_StructInit(&EXTI_InitStruct);	//configure EXTI to handle rising edge on EXTI11
	EXTI_InitStruct.EXTI_Line=EXTI_Line11;
	EXTI_InitStruct.EXTI_LineCmd=ENABLE;
	EXTI_InitStruct.EXTI_Mode=EXTI_Mode_Interrupt;
	EXTI_InitStruct.EXTI_Trigger=EXTI_Trigger_Falling;
	EXTI_Init(&EXTI_InitStruct);

	RCC_ADCCLKConfig(RCC_PCLK2_Div4); //set ADC clock to 14 MHz
	RCC_APB2PeriphClockCmd(RCC_APB2Periph_ADC1, ENABLE);
	RCC_APB2PeriphClockCmd(RCC_APB2Periph_ADC2, ENABLE);

	ADC_InitStruct.ADC_ContinuousConvMode = DISABLE;
	//ADC_InitStruct.ADC_ContinuousConvMode = ENABLE;
	ADC_InitStruct.ADC_DataAlign = ADC_DataAlign_Right;
	ADC_InitStruct.ADC_ExternalTrigConv = ADC_ExternalTrigConv_Ext_IT11_TIM8_TRGO;
	//ADC_InitStruct.ADC_ExternalTrigConv = ADC_ExternalTrigConv_None;
	ADC_InitStruct.ADC_Mode=ADC_Mode_RegSimult;
	ADC_InitStruct.ADC_NbrOfChannel = 1;
	ADC_InitStruct.ADC_ScanConvMode = DISABLE;

	ADC_RegularChannelConfig(ADC1, OUT_LOG_ADC_CHANNEL, 1, ADC_SampleTime_28Cycles5);
	ADC_RegularChannelConfig(ADC2, OUT_LIN_ADC_CHANNEL, 1, ADC_SampleTime_28Cycles5);
	ADC_ExternalTrigConvCmd(ADC1, ENABLE);
	ADC_ExternalTrigConvCmd(ADC2, ENABLE);

	ADC_Init(ADC1, &ADC_InitStruct);
	ADC_Init(ADC2, &ADC_InitStruct);
	ADC_StartCalibration(ADC1);
	ADC_StartCalibration(ADC2);
	while((ADC_GetCalibrationStatus(ADC1)==RESET)|(ADC_GetCalibrationStatus(ADC2)==RESET)){__asm volatile ("NOP");}
	ADC_Cmd(ADC1, ENABLE);
	ADC_Cmd(ADC2, ENABLE);
	ADC_ITConfig(ADC2, ADC_IT_EOC, ENABLE);

	NVIC_PriorityGroupConfig(NVIC_PriorityGroup_4);

	NVIC_InitStruct.NVIC_IRQChannel=EXTI15_10_IRQn;
	NVIC_InitStruct.NVIC_IRQChannelCmd=DISABLE;
	NVIC_InitStruct.NVIC_IRQChannelPreemptionPriority=0;
	NVIC_InitStruct.NVIC_IRQChannelSubPriority=0;
	NVIC_Init(&NVIC_InitStruct);

	NVIC_InitStruct.NVIC_IRQChannel=ADC1_2_IRQn;
	NVIC_InitStruct.NVIC_IRQChannelCmd=ENABLE;
	NVIC_InitStruct.NVIC_IRQChannelPreemptionPriority=0;
	NVIC_InitStruct.NVIC_IRQChannelSubPriority=0;
	NVIC_Init(&NVIC_InitStruct);
}

void SERIAL_Init(void)
{
	USART_InitTypeDef USART_InitStruct;
	GPIO_InitTypeDef GPIO_InitStruct;
	NVIC_InitTypeDef NVIC_InitStructure;

	RCC_APB2PeriphClockCmd(USART_PERIPH | RCC_APB2Periph_USART1, ENABLE);

	GPIO_StructInit(&GPIO_InitStruct);
	GPIO_InitStruct.GPIO_Mode=GPIO_Mode_AF_PP;
	GPIO_InitStruct.GPIO_Speed=GPIO_Speed_50MHz;
	GPIO_InitStruct.GPIO_Pin=USART_TX;
	GPIO_Init(USART_PORT, &GPIO_InitStruct);

	GPIO_InitStruct.GPIO_Mode=GPIO_Mode_IN_FLOATING;
	GPIO_InitStruct.GPIO_Pin=USART_RX;
	GPIO_Init(USART_PORT, &GPIO_InitStruct);

	USART_StructInit(&USART_InitStruct);
	USART_InitStruct.USART_BaudRate=230400;
	USART_InitStruct.USART_HardwareFlowControl=USART_HardwareFlowControl_None;
	USART_InitStruct.USART_Mode=USART_Mode_Rx | USART_Mode_Tx;
	USART_InitStruct.USART_Parity=USART_Parity_No;
	USART_InitStruct.USART_StopBits=USART_StopBits_1;
	USART_InitStruct.USART_WordLength=USART_WordLength_8b;
	USART_Init(USART1, &USART_InitStruct);
	USART_Cmd(USART1, ENABLE);

	NVIC_InitStructure.NVIC_IRQChannel = USART1_IRQn;
	NVIC_InitStructure.NVIC_IRQChannelPreemptionPriority = 1;
	NVIC_InitStructure.NVIC_IRQChannelSubPriority = 0;
	NVIC_InitStructure.NVIC_IRQChannelCmd = ENABLE;
	NVIC_Init(&NVIC_InitStructure);

	USART_ITConfig(USART1, USART_IT_TXE, DISABLE);
	USART_ITConfig(USART1, USART_IT_RXNE, ENABLE);
}

EnableState Calibrate_Si5351(Si5351_ConfigTypeDef *Si5351_ConfigStruct, SSD1306_ConfigTypeDef *SSD1306_ConfigStruct, Framebuffer *display_buffer, Board_ReflectometerStateTypeDef *Board_ReflectometerState, EnableState RunGraphical)
{
	uint8_t data;
	EnableState state=OFF; //OFF when OK, ON when encountered error

	if(RunGraphical==ON)
	{
		SSD1306_ClearPartialDisplayBuffer(SSD1306_ConfigStruct, 0,5);
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 0, " Initialising Si5351");
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 4, "     Please wait");
		SSD1306_StopProgressBar(SSD1306_ConfigStruct);
		SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,0,5);
		SSD1306_StartProgressBar(SSD1306_ConfigStruct);
		Delay_ms(4*DRAMATIC_PAUSE);
	}

	//initialize the PLL
	Si5351_Board_Init(Si5351_ConfigStruct);

	ReflectometerMode_Init(Si5351_ConfigStruct, ReflectometerMode_Stop);
	Delay_ms(100);
	Si5351_ClearStickyBits(Si5351_ConfigStruct);

	//check SYSINIT flag (proper initialization of PLL upon startup)
	if(RunGraphical==ON)
	{
		SSD1306_ClearPartialDisplayBuffer(SSD1306_ConfigStruct, 0, 5);
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 0, "PLL SysInit");
		SSD1306_StopProgressBar(SSD1306_ConfigStruct);
		SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,0,5);
		SSD1306_StartProgressBar(SSD1306_ConfigStruct);
		Delay_ms(DRAMATIC_PAUSE);
	}

	data=Si5351_ReadRegister(Si5351_ConfigStruct, REG_DEV_STATUS);

	if(data & DEV_SYS_INIT_MASK)
	{
		if(RunGraphical==ON) dispError(SSD1306_ConfigStruct,0);
		state=ON;
	} else {
		if(RunGraphical==ON) dispOK(SSD1306_ConfigStruct,0);
	}
	if(RunGraphical==ON)
	{
		SSD1306_StopProgressBar(SSD1306_ConfigStruct);
		SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,0,5);
		SSD1306_StartProgressBar(SSD1306_ConfigStruct);
		Delay_ms(DRAMATIC_PAUSE);
	}

	//check LOS_XTAL bit (loss of signal on XTAL clock input)
	if(RunGraphical==ON)
	{
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 1, "PLL XTAL stable");
		SSD1306_StopProgressBar(SSD1306_ConfigStruct);
		SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,0,5);
		SSD1306_StartProgressBar(SSD1306_ConfigStruct);
		Delay_ms(DRAMATIC_PAUSE);
	}

	data=Si5351_ReadRegister(Si5351_ConfigStruct, REG_DEV_STATUS);

	if(data & DEV_LOS_XTAL_MASK)
	{
		if(RunGraphical==ON) dispError(SSD1306_ConfigStruct,1);
		state=ON;
	} else {
		if(RunGraphical==ON) dispOK(SSD1306_ConfigStruct,1);
	}

	if(RunGraphical==ON)
	{
		SSD1306_StopProgressBar(SSD1306_ConfigStruct);
		SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,0,5);
		SSD1306_StartProgressBar(SSD1306_ConfigStruct);
		Delay_ms(DRAMATIC_PAUSE);
	}

	//check LOL_A bit (loss of lock of PLL A)
	if(RunGraphical==ON)
	{
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 2, "PLL A stable");
		SSD1306_StopProgressBar(SSD1306_ConfigStruct);
		SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,0,5);
		SSD1306_StartProgressBar(SSD1306_ConfigStruct);
		Delay_ms(DRAMATIC_PAUSE);
	}

	data=Si5351_ReadRegister(Si5351_ConfigStruct, REG_DEV_STATUS);

	if(data & DEV_LOL_A_MASK)
	{
		if(RunGraphical==ON) dispError(SSD1306_ConfigStruct,2);
		state=ON;
	} else {
		if(RunGraphical==ON) dispOK(SSD1306_ConfigStruct,2);
	}

	if(RunGraphical==ON)
	{
		SSD1306_StopProgressBar(SSD1306_ConfigStruct);
		SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,0,5);
		SSD1306_StartProgressBar(SSD1306_ConfigStruct);
		Delay_ms(DRAMATIC_PAUSE);
	}

	//check LOL_B bit (loss of lock of PLL B)
	if(RunGraphical==ON)
	{
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 3, "PLL B stable");
		SSD1306_StopProgressBar(SSD1306_ConfigStruct);
		SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,0,5);
		SSD1306_StartProgressBar(SSD1306_ConfigStruct);
		Delay_ms(DRAMATIC_PAUSE);
	}

	data=Si5351_ReadRegister(Si5351_ConfigStruct, REG_DEV_STATUS);

	if(data & DEV_LOL_B_MASK)
	{
		if(RunGraphical==ON) dispError(SSD1306_ConfigStruct,3);
		state=ON;
	} else {
		if(RunGraphical==ON) dispOK(SSD1306_ConfigStruct,3);
	}

	//report whether the PLL initialization was successful
	if(RunGraphical==ON)
	{
		SSD1306_StopProgressBar(SSD1306_ConfigStruct);
		SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,0,5);
		SSD1306_StartProgressBar(SSD1306_ConfigStruct);
		Delay_ms(DRAMATIC_PAUSE);
		if(state==OFF)
		{
			SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 4, "PLL Startup complete");
		} else {
			SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 4, "PLL Startup error");
			while(1){}
		}
		SSD1306_StopProgressBar(SSD1306_ConfigStruct);
		SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,0,5);
		SSD1306_StartProgressBar(SSD1306_ConfigStruct);
		Delay_ms(DRAMATIC_PAUSE*4);
	}

	return state;
}

EnableState Calibrate_Sampler_Offset(Si5351_ConfigTypeDef *Si5351_ConfigStruct, SSD1306_ConfigTypeDef *SSD1306_ConfigStruct, Framebuffer *display_buffer, Board_ReflectometerStateTypeDef *Board_ReflectometerState, EnableState RunGraphical)
{
	uint16_t i16;
	EnableState state=OFF; //OFF when OK, ON when encountered error

	if(RunGraphical==ON)
	{
		SSD1306_ClearPartialDisplayBuffer(SSD1306_ConfigStruct, 0,5);
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 0, " Please connect open");
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 1, "  standard directly");
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 2, "    to test port.");
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 4, "    Press button");
		SSD1306_StopProgressBar(SSD1306_ConfigStruct);
		SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,0,5);
		Wait_For_User_Action();
		SSD1306_StartProgressBar(SSD1306_ConfigStruct);

		SSD1306_ClearPartialDisplayBuffer(SSD1306_ConfigStruct, 0,5);
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 0, " Calibrating sampler");
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 1, "       offset.");
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 4, "     Please wait");
		SSD1306_StopProgressBar(SSD1306_ConfigStruct);
		SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,0,5);
		SSD1306_StartProgressBar(SSD1306_ConfigStruct);
	}

	ReflectometerMode_Init(Si5351_ConfigStruct, ReflectometerMode_Calibrate_Sampler_HIGH);
	Delay_ms(100);
	Si5351_ClearStickyBits(Si5351_ConfigStruct);

	uint16_t temp_lin_high=4095, temp_lin_low, temp_lin_low_new;
	int16_t temp_offset;

	for(i16=0; i16<4095; i16++)
	{
		MCP4725_SetVoltage(i16);
		while(GPIO_ReadInputDataBit(GPIOB, GPIO_Pin_11)==Bit_RESET){}
		while(GPIO_ReadInputDataBit(GPIOB, GPIO_Pin_11)==Bit_SET){}
		if(Board_ReflectometerState->sample_lin_last<3920)
		{
			Board_ReflectometerState->dac_value=i16;
			temp_lin_high=Board_ReflectometerState->sample_lin_last;
			break;
		}
		if (i16==4095) state=ON;
	}

	ReflectometerMode_Init(Si5351_ConfigStruct, ReflectometerMode_Calibrate_Sampler_LOW);
	Delay_ms(100);
	Si5351_ClearStickyBits(Si5351_ConfigStruct);

	while(GPIO_ReadInputDataBit(GPIOB, GPIO_Pin_11)==Bit_RESET){}
	while(GPIO_ReadInputDataBit(GPIOB, GPIO_Pin_11)==Bit_SET){}
	temp_lin_low=Board_ReflectometerState->sample_lin_last;
	temp_offset=(temp_lin_low+temp_lin_high)/2-2048;
	temp_lin_low_new=temp_lin_low-temp_offset;

	for(i16=0; i16<4095; i16++)
	{
		MCP4725_SetVoltage(i16);
		while(GPIO_ReadInputDataBit(GPIOB, GPIO_Pin_11)==Bit_RESET){}
		while(GPIO_ReadInputDataBit(GPIOB, GPIO_Pin_11)==Bit_SET){}
		if(Board_ReflectometerState->sample_lin_last<=temp_lin_low_new)
		{
			Board_ReflectometerState->dac_value=i16;
			temp_lin_low=Board_ReflectometerState->sample_lin_last;
			break;
		}
		if (i16==4095) state=ON;
	}

	if(RunGraphical==ON)
	{
		Delay_ms(2*DRAMATIC_PAUSE);
	}

	return state;
}

EnableState Calibrate_Logic_Levels(Si5351_ConfigTypeDef *Si5351_ConfigStruct, SSD1306_ConfigTypeDef *SSD1306_ConfigStruct, Framebuffer *display_buffer, Board_ReflectometerStateTypeDef *Board_ReflectometerState, Board_ReflectometerCalibrationStandardTypeDef Calibration_Normal, EnableState RunGraphical)
{
	uint16_t i16;
	char str[6];

	if(RunGraphical==ON)
	{
		SSD1306_ClearPartialDisplayBuffer(SSD1306_ConfigStruct, 0,5);
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 0, "   Measuring logic");
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 1, "       levels.");
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 4, "     Please wait");
		SSD1306_StopProgressBar(SSD1306_ConfigStruct);
		SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,0,5);
		SSD1306_StartProgressBar(SSD1306_ConfigStruct);
	}

	ReflectometerMode_Init(Si5351_ConfigStruct, ReflectometerMode_Calibrate_Sampler_LOW);
	Delay_ms(100);
	Si5351_ClearStickyBits(Si5351_ConfigStruct);

	//run one measurement as soon as possible and wait for the measurement to be completed
	Board_ReflectometerState->enable_continuous_run=OFF;
	Board_ReflectometerState->start_sample_index=Board_ReflectometerState->current_sample_index+300;
	Board_ReflectometerState->pending_measurement=ON;
	Board_ReflectometerState->enable_sampling=ON;
	while(Board_ReflectometerState->pending_measurement==ON){}

	uint32_t temp32;

	//measure low level voltage average
	temp32=0;
	for(i16=0; i16<4095; i16++)
	{
		temp32+=Board_ReflectometerState->sampled_data[i16];
	}
	Board_ReflectometerState->calibration[Calibration_Normal].low_value=temp32>>12;

	//measure low level voltage variance
	temp32=0;
	for(i16=0; i16<4095; i16++)
	{
		temp32+=((int32_t)Board_ReflectometerState->sampled_data[i16]-Board_ReflectometerState->calibration[Calibration_Normal].low_value)*((int32_t)Board_ReflectometerState->sampled_data[i16]-Board_ReflectometerState->calibration[Calibration_Normal].low_value);
	}
	Board_ReflectometerState->calibration[Calibration_Normal].low_variance=temp32/4095;

	ReflectometerMode_Init(Si5351_ConfigStruct, ReflectometerMode_Calibrate_Sampler_HIGH);
	Delay_ms(100);
	Si5351_ClearStickyBits(Si5351_ConfigStruct);

	//run one measurement as soon as possible and wait for the measurement to be completed
	Board_ReflectometerState->enable_continuous_run=OFF;
	Board_ReflectometerState->start_sample_index=Board_ReflectometerState->current_sample_index+300;
	Board_ReflectometerState->pending_measurement=ON;
	Board_ReflectometerState->enable_sampling=ON;
	while(Board_ReflectometerState->pending_measurement==ON){}

	//measure high level voltage average
	temp32=0;
	for(i16=0; i16<4095; i16++)
	{
		temp32+=Board_ReflectometerState->sampled_data[i16];
	}
	Board_ReflectometerState->calibration[Calibration_Normal].high_value=temp32>>12;

	//measure high level voltage variance
	temp32=0;
	for(i16=0; i16<4095; i16++)
	{
		temp32+=((int32_t)Board_ReflectometerState->sampled_data[i16]-Board_ReflectometerState->calibration[Calibration_Normal].high_value)*((int32_t)Board_ReflectometerState->sampled_data[i16]-Board_ReflectometerState->calibration[Calibration_Normal].high_value);
	}
	Board_ReflectometerState->calibration[Calibration_Normal].high_variance=temp32/4095;

	//report the results
	if(RunGraphical==ON)
	{
		SSD1306_ClearPartialDisplayBuffer(SSD1306_ConfigStruct, 0, 5);
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 0, "LOW value");
		SSD1306_StopProgressBar(SSD1306_ConfigStruct);
		SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,0,5);
		SSD1306_StartProgressBar(SSD1306_ConfigStruct);
		Delay_ms(DRAMATIC_PAUSE);
		getnum(Board_ReflectometerState->calibration[Calibration_Normal].low_value,str);
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 127-24, 0, str+1);
		SSD1306_StopProgressBar(SSD1306_ConfigStruct);
		SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,0,5);
		SSD1306_StartProgressBar(SSD1306_ConfigStruct);
		Delay_ms(DRAMATIC_PAUSE);

		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 1, "HIGH value");
		SSD1306_StopProgressBar(SSD1306_ConfigStruct);
		SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,0,5);
		SSD1306_StartProgressBar(SSD1306_ConfigStruct);
		Delay_ms(DRAMATIC_PAUSE);
		getnum(Board_ReflectometerState->calibration[Calibration_Normal].high_value,str);
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 127-24, 1, str+1);
		SSD1306_StopProgressBar(SSD1306_ConfigStruct);
		SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,0,5);
		SSD1306_StartProgressBar(SSD1306_ConfigStruct);
		Delay_ms(DRAMATIC_PAUSE);

		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 2, "LOW variance");
		SSD1306_StopProgressBar(SSD1306_ConfigStruct);
		SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,0,5);
		SSD1306_StartProgressBar(SSD1306_ConfigStruct);
		Delay_ms(DRAMATIC_PAUSE);
		getnum(Board_ReflectometerState->calibration[Calibration_Normal].low_variance,str);
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 127-24, 2, str+1);
		SSD1306_StopProgressBar(SSD1306_ConfigStruct);
		SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,0,5);
		SSD1306_StartProgressBar(SSD1306_ConfigStruct);
		Delay_ms(DRAMATIC_PAUSE);

		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 3, "HIGH variance");
		SSD1306_StopProgressBar(SSD1306_ConfigStruct);
		SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,0,5);
		SSD1306_StartProgressBar(SSD1306_ConfigStruct);
		Delay_ms(DRAMATIC_PAUSE);
		getnum(Board_ReflectometerState->calibration[Calibration_Normal].high_variance,str);
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 127-24, 3, str+1);
		SSD1306_StopProgressBar(SSD1306_ConfigStruct);
		SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,0,5);
		SSD1306_StartProgressBar(SSD1306_ConfigStruct);
		Delay_ms(DRAMATIC_PAUSE);

		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 4, "Level calibration OK.");
		SSD1306_StopProgressBar(SSD1306_ConfigStruct);
		SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,0,5);
		SSD1306_StartProgressBar(SSD1306_ConfigStruct);
		Delay_ms(4*DRAMATIC_PAUSE);
	}

	return OFF;
}

EnableState Calibrate_Rising_Edge_Position_Guess(Si5351_ConfigTypeDef *Si5351_ConfigStruct, SSD1306_ConfigTypeDef *SSD1306_ConfigStruct, Framebuffer *display_buffer, Board_ReflectometerStateTypeDef *Board_ReflectometerState, EnableState RunGraphical)
{
	uint32_t start_millis,last_largest_differentiation_point;
	uint8_t position_hits=0;

	//start the pulse generator
	ReflectometerMode_Init(Si5351_ConfigStruct, ReflectometerMode_Run);
	Delay_ms(100);
	Si5351_ClearStickyBits(Si5351_ConfigStruct);

	if(RunGraphical==ON)
	{
		SSD1306_ClearPartialDisplayBuffer(SSD1306_ConfigStruct, 0,5);
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 0, " Finding rising edge.");
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 4, "     Please wait");
		SSD1306_StopProgressBar(SSD1306_ConfigStruct);
		SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,0,5);
		SSD1306_StartProgressBar(SSD1306_ConfigStruct);
	}

	start_millis=millis;
	//repeat looking for new largest differentiation index until it lies four times in tolerance field
	while(position_hits<4)
	{
		last_largest_differentiation_point=Board_ReflectometerState->largest_differentiation_point;
		while(Board_ReflectometerState->current_sample_index!=1){}
		while(Board_ReflectometerState->current_sample_index!=2){}
		if ((millis-start_millis)>120000) return ON; //if not found in two minutes, return error
		if (abs(Board_ReflectometerState->largest_differentiation_point-last_largest_differentiation_point)>=256)
		{
			position_hits=0;
		} else position_hits++;
	}

	EnableState scroll_state=SSD1306_ConfigStruct->Scroll_State;
	Board_CalibrationState=CAL_WAIT_REFERENCE_PLANE;
	if(RunGraphical==ON)
	{
		SSD1306_ClearPartialDisplayBuffer(SSD1306_ConfigStruct, 0,5);
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 0, " Please connect open");
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 1, " standard to the end");
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 2, "   of an airline.");
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 4, "    Press button");
		SSD1306_StopProgressBar(SSD1306_ConfigStruct);
		SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,0,5);
		Wait_For_User_Action();
		SSD1306_StartProgressBar(SSD1306_ConfigStruct);

		SSD1306_ClearDisplayBuffer(SSD1306_ConfigStruct);
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 0, "   Calibrating edge");
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 1, "      position.");
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 4, "     Please wait");
		SSD1306_DrawProgressIndicator(SSD1306_ConfigStruct,0);
		if (scroll_state==ON) SSD1306_StopProgressBar(SSD1306_ConfigStruct);
		SSD1306_DrawBuffer(SSD1306_ConfigStruct);
	}

	Board_CalibrationState=CAL_FINDING_REFERENCE_PLANE;

	//set the guessed value-512 as starting value
	Board_ReflectometerState->start_sample_index=(last_largest_differentiation_point-512)%NUMBER_OF_POINTS;
	Delay_ms(10);
	Board_ReflectometerState->enable_continuous_run=ON;
	Board_ReflectometerState->enable_sampling=ON;
	Board_ReflectometerState->pending_measurement=ON;
	Board_ReflectometerState->average_count=0;

	//get 8 averages of the surroundings of the rising edge
	#define RISING_EDGE_AVG 8
	uint8_t last_progress=0;
	while(Board_ReflectometerState->average_count<RISING_EDGE_AVG)
	{
		while(Board_ReflectometerState->pending_measurement==ON)
		{
			if(RunGraphical==ON)
			{
				static uint8_t progress=(255*((Board_ReflectometerState->current_sample_index + NUMBER_OF_POINTS - Board_ReflectometerState->start_sample_index) % NUMBER_OF_POINTS))/(NUMBER_OF_POINTS*RISING_EDGE_AVG)+(255*Board_ReflectometerState->average_count)/RISING_EDGE_AVG;
				if(progress>last_progress)SSD1306_DrawProgressIndicator(SSD1306_ConfigStruct, progress);
				last_progress=progress;
				SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,6,7);
			}
		}
		Board_ReflectometerState->pending_measurement=ON;
	}

	Board_ReflectometerState->enable_sampling=OFF;

	//start the progress indicator instead of progress bar
	if(RunGraphical==ON)
	{
		SSD1306_ClearPartialDisplayBuffer(SSD1306_ConfigStruct,5,7);
		SSD1306_DrawProgressBar(SSD1306_ConfigStruct);
		SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,5,7);
		if (scroll_state==ON) SSD1306_StartProgressBar(SSD1306_ConfigStruct);
	}

	//find minimum value and index
	uint16_t min_value, i16;
	uint32_t min_index;
	min_value=Board_ReflectometerState->sampled_data[0];
	for(i16=0; i16<=SAMPLE_MEMORY_SIZE-1; i16++)
	{
		if (Board_ReflectometerState->sampled_data[i16]<min_value)
		{
			min_value=Board_ReflectometerState->sampled_data[i16];
			min_index=i16;
		}
	}

	uint16_t base_value, top_value, edge_20percent_value, edge_80percent_value;
	uint32_t edge_20percent_index, edge_80percent_index;
	if (min_index>=128)
	{
		top_value=Board_ReflectometerState->sampled_data[min_index-128];
	} else {
		top_value=Board_ReflectometerState->sampled_data[0];
	}

	if (min_index<=(SAMPLE_MEMORY_SIZE-1-256))
	{
		base_value=Board_ReflectometerState->sampled_data[min_index+256];
	} else {
		base_value=Board_ReflectometerState->sampled_data[SAMPLE_MEMORY_SIZE-1];
	}

	edge_20percent_value=base_value+(top_value-base_value)/5;
	edge_80percent_value=top_value-(top_value-base_value)/5;

	//find 20% rising edge point
	if (min_index<128) min_index=128;
	if (min_index>(SAMPLE_MEMORY_SIZE-1-128)) min_index=SAMPLE_MEMORY_SIZE-1-128;

	for(i16=min_index-128; i16<=min_index; i16++)
	{
		if (Board_ReflectometerState->sampled_data[i16]<edge_20percent_value)
		{
			edge_20percent_index=i16;
			break;
		}
	}

	//find 80% rising edge point
	for(i16=edge_20percent_index; i16<=min_index; i16++)
	{
		if (Board_ReflectometerState->sampled_data[i16]<edge_80percent_value)
		{
			edge_80percent_index=i16;
			break;
		}
	}

	Board_ReflectometerState->rising_edge_start_index=(Board_ReflectometerState->start_sample_index+edge_80percent_index-(edge_20percent_index-edge_80percent_index)*10-SAMPLE_MEMORY_SIZE/32)%NUMBER_OF_POINTS;

	if(RunGraphical==ON)
	{
		SSD1306_ClearDisplayBuffer(SSD1306_ConfigStruct);
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 0, "     Edge found OK.");
		if (scroll_state==ON)
		{
			SSD1306_DrawProgressBar(SSD1306_ConfigStruct);
			SSD1306_StopProgressBar(SSD1306_ConfigStruct);
		}
		SSD1306_DrawBuffer(SSD1306_ConfigStruct);
		if (scroll_state==ON) SSD1306_StartProgressBar(SSD1306_ConfigStruct);
		Delay_ms(4*DRAMATIC_PAUSE);
	}

	return OFF;
}

EnableState Calibrate_Rising_Edge_Parameters(Si5351_ConfigTypeDef *Si5351_ConfigStruct, SSD1306_ConfigTypeDef *SSD1306_ConfigStruct, Framebuffer *display_buffer, Board_ReflectometerStateTypeDef *Board_ReflectometerState, Board_ReflectometerCalibrationStandardTypeDef Calibration_Normal, EnableState RunGraphical)
{
	uint16_t i16, temp;

	//get index and amplitude of first minimum
	temp=Board_ReflectometerState->sampled_data[0];
	for(i16=0; i16<=4095; i16++)
	{
		if (Board_ReflectometerState->sampled_data[i16]<temp)
			{
				temp=Board_ReflectometerState->sampled_data[i16];
				Board_ReflectometerState->calibration[Calibration_Normal].T_min=i16;
				Board_ReflectometerState->calibration[Calibration_Normal].A_preshoot=Board_ReflectometerState->calibration[Calibration_Normal].low_value-Board_ReflectometerState->sampled_data[i16];
			}
		if(Board_ReflectometerState->sampled_data[i16]>(temp)+500) break;
	}

	//get index and amplitude of minimum
	temp=Board_ReflectometerState->sampled_data[0];
	for(i16=Board_ReflectometerState->calibration[Calibration_Normal].T_min; i16<=Board_ReflectometerState->calibration[Calibration_Normal].T_min+128; i16++)
	{
		if (Board_ReflectometerState->sampled_data[i16]>temp)
			{
				temp=Board_ReflectometerState->sampled_data[i16];
				Board_ReflectometerState->calibration[Calibration_Normal].T_max=i16;
				Board_ReflectometerState->calibration[Calibration_Normal].A_overshoot=Board_ReflectometerState->calibration[Calibration_Normal].high_value-Board_ReflectometerState->sampled_data[i16];
			}
	}

	//get index and amplitude of 10% rise
	for(i16=Board_ReflectometerState->calibration[Calibration_Normal].T_min; i16<=Board_ReflectometerState->calibration[Calibration_Normal].T_min+128; i16++)
	{
		if (Board_ReflectometerState->sampled_data[i16]>temp)
			{
				temp=Board_ReflectometerState->sampled_data[i16];
				Board_ReflectometerState->calibration[Calibration_Normal].T_max=i16;
				Board_ReflectometerState->calibration[Calibration_Normal].A_overshoot=Board_ReflectometerState->calibration[Calibration_Normal].high_value-Board_ReflectometerState->sampled_data[i16];
			}
	}

	return OFF;
}

EnableState Calibrate_Get_Calibration_Normal_Response(Si5351_ConfigTypeDef *Si5351_ConfigStruct, SSD1306_ConfigTypeDef *SSD1306_ConfigStruct, Framebuffer *display_buffer, Board_ReflectometerStateTypeDef *Board_ReflectometerState, Board_ReflectometerCalibrationStandardTypeDef Calibration_Normal, EnableState RunGraphical)
{
	uint16_t i16;
	EnableState scroll_state=SSD1306_ConfigStruct->Scroll_State;

	ReflectometerMode_Init(Si5351_ConfigStruct, ReflectometerMode_Run);
	Delay_ms(100);
	Si5351_ClearStickyBits(Si5351_ConfigStruct);

	for(i16=0;i16<=32;i16++)
	{
		Board_ReflectometerState->calibration[Calibration_Normal].ideal_averaging=i16/2;
		if((i16*i16>Board_ReflectometerState->calibration[Calibration_Normal].low_variance) & (i16*i16>Board_ReflectometerState->calibration[Calibration_Normal].high_variance)) break;
	}

	if(RunGraphical==ON)
	{
		SSD1306_ClearDisplayBuffer(SSD1306_ConfigStruct);
		SSD1306_DrawProgressIndicator(SSD1306_ConfigStruct,0);
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 0, "Sampling calibration");
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 1, "   normal response");
		SSD1306_DrawStringToBuffer(SSD1306_ConfigStruct, 0, 4, "     Please wait");
		SSD1306_DrawProgressIndicator(SSD1306_ConfigStruct,0);
		if (scroll_state==ON) SSD1306_StopProgressBar(SSD1306_ConfigStruct);
		SSD1306_DrawBuffer(SSD1306_ConfigStruct);
	}

	Board_ReflectometerState->start_sample_index=Board_ReflectometerState->rising_edge_start_index;
	Delay_ms(10);
	Board_ReflectometerState->enable_continuous_run=ON;
	Board_ReflectometerState->enable_sampling=ON;
	Board_ReflectometerState->calibration[Calibration_Normal].calibration_trace_start_index=Board_ReflectometerState->start_sample_index;
	Board_ReflectometerState->pending_measurement=ON;
	Board_ReflectometerState->average_count=0;

	while(Board_ReflectometerState->average_count<Board_ReflectometerState->calibration[Calibration_Normal].ideal_averaging)
	{
		while(Board_ReflectometerState->pending_measurement==ON){}
		Board_ReflectometerState->pending_measurement=ON;
		if(RunGraphical==ON)
		{
			SSD1306_DrawProgressIndicator(SSD1306_ConfigStruct,(255*Board_ReflectometerState->average_count)/Board_ReflectometerState->calibration[Calibration_Normal].ideal_averaging);
			SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,6,7);
		}
	}

	for(i16=0; i16<1024; i16++)
	{
		Board_ReflectometerState->calibration[Calibration_Normal].calibration_trace[i16]=Board_ReflectometerState->sampled_data[i16];
	}

	Board_ReflectometerState->enable_sampling=OFF;

	if(RunGraphical==ON)
	{
		if(scroll_state==ON)
		{
			SSD1306_ClearPartialDisplayBuffer(SSD1306_ConfigStruct,5,7);
			SSD1306_DrawProgressBar(SSD1306_ConfigStruct);
			SSD1306_DrawPartialBuffer(SSD1306_ConfigStruct,5,7);
			SSD1306_StartProgressBar(SSD1306_ConfigStruct);
		}
		Delay_ms(4*DRAMATIC_PAUSE);
	}

	return OFF;
}

void EXTI15_10_IRQHandler(void)
{
	if(EXTI_GetITStatus(EXTI_Line11) != RESET) 	EXTI_ClearITPendingBit(EXTI_Line11);
}

bool Compare_Strings(char string1[], char string2[])
{
	uint8_t index=0;

	while(string1[index]==string2[index])
	{
		if ((string1[index]==0)&(string2[index]==0)) return TRUE;
		if (index==255) return FALSE;
		index++;
	}
	return FALSE;
}

void USART1_IRQHandler(void)
{

	static uint8_t RX_buffer[32];
	static uint8_t RX_length=0;
	uint8_t response_pending;
	response_pending=global_response_pending;

	if (USART_GetFlagStatus(USART1, USART_FLAG_RXNE) != RESET) // Receiving of characters and parsing
	{
		if (response_pending==NO_RESPONSE_PENDING)
		{
			if (RX_length==32) RX_length=0;
			RX_buffer[RX_length]=USART_ReceiveData(USART1);
			if ((RX_buffer[RX_length]=='\n')|(RX_buffer[RX_length]=='\r'))
			{
				RX_buffer[RX_length]=0;
				RX_length=0;
				if (Compare_Strings(RX_buffer, commands[COMMAND_REMOTE]))
				{
					response_pending = RESPONSE_REMOTE;
					GPIO_WriteBit(LED_PORT, LED_BUSY, Bit_RESET);
					Remote_Mode=TRUE;
				}
				if (Compare_Strings(RX_buffer, commands[COMMAND_DEVICE]))
				{
					response_pending = RESPONSE_DEVICE;
					GPIO_WriteBit(LED_PORT, LED_BUSY, Bit_RESET);
				}
				if (Compare_Strings(RX_buffer, commands[COMMAND_STATE]))
				{
					response_pending = 2+Board_CalibrationState;
					GPIO_WriteBit(LED_PORT, LED_BUSY, Bit_RESET);
					Remote_Mode=TRUE;
				}
				if (Compare_Strings(RX_buffer, commands[COMMAND_ACTION]))
				{
					remote_user_action=TRUE;
					GPIO_WriteBit(LED_PORT, LED_BUSY, Bit_RESET);
					Remote_Mode=TRUE;
				}
				if (Compare_Strings(RX_buffer, commands[COMMAND_SEND_DATA]))
				{
					response_pending=RESPONSE_SEND_DATA;
					GPIO_WriteBit(LED_PORT, LED_BUSY, Bit_RESET);
					Remote_Mode=TRUE;
				}
				if (Compare_Strings(RX_buffer, commands[COMMAND_GET_AVG]))
				{
					response_pending=RESPONSE_AVG;
					GPIO_WriteBit(LED_PORT, LED_BUSY, Bit_RESET);
					Remote_Mode=TRUE;
				}
			} else RX_length++;
		} else {
			USART_ReceiveData(USART1);
		}
	}

	global_response_pending=response_pending;
}

void ADC1_2_IRQHandler(void)
{
	#define DIFF_POINTS 16
	static EnableState local_is_enabled=OFF, local_is_running=OFF;
	static uint8_t differentiation_index=0;
	static uint16_t local_largest_diff=0, local_average_count=0;
	static uint16_t local_sample_lin=0, local_sample_lin_last[DIFF_POINTS];
	static uint16_t local_window_max=0, local_window_min=4095, local_sample_max=0, local_sample_min=4095;
	static uint32_t local_largest_diff_point=0, local_current_sample_index=0, local_start_sample_index=0;

	//save last measured value from previous call
	local_sample_lin_last[(differentiation_index-1)%DIFF_POINTS]=local_sample_lin;

	//wait for ADC2 to have valid data (should be ready by the time this interrupt was triggered by ADC1, but better to check)
	//while (ADC_GetFlagStatus(ADC2, ADC_FLAG_EOC)==RESET) {__asm volatile ("NOP");}

	//read both ADCs and store their values both locally and globally
	//Board_ReflectometerState.sample_log_last=ADC_GetConversionValue(ADC1);
	local_sample_lin=ADC_GetConversionValue(ADC2);
	Board_ReflectometerState.sample_lin_last=local_sample_lin;

	//if running new measurement cycle, store cycle peak detectors and reset them
	if(local_current_sample_index==0)
	{
		Board_ReflectometerState.sample_cycle_min=local_sample_min;
		Board_ReflectometerState.sample_cycle_max=local_sample_max;
		local_sample_min=4095;
		local_sample_max=0;
		Board_ReflectometerState.largest_differentiation_point=local_largest_diff_point;
	}

	//cycle peak detectors
	if(local_sample_min>local_sample_lin) local_sample_min=local_sample_lin;
	if(local_sample_max<local_sample_lin) local_sample_max=local_sample_lin;

	if(local_sample_lin<local_sample_lin_last[differentiation_index]) //if rising edge
	{
		//this ensures finding largest difference and resetting the peak difference detector over measurement cycles while ensuring continuity over the measurement cycle boundary, should the peak be at point with index 0
		if(local_largest_diff>(local_sample_lin_last[differentiation_index]-local_sample_lin))	//if the difference between previous sample and current sample is not the largest measured difference
		{
			if(local_current_sample_index==0) local_largest_diff=0;	//if at measurement cycle boundary, reset the difference to 0
		} else {
			local_largest_diff=local_sample_lin_last[differentiation_index]-local_sample_lin; //otherwise set the new difference as largest and remember where it happened
			local_largest_diff_point=local_current_sample_index;
		}
	}

	//if not storing data right now, update whether sampling should be enabled
	if(local_is_running==OFF) local_is_enabled=Board_ReflectometerState.enable_sampling;

	if(local_is_enabled==OFF)	//if sampling not enabled
	{
		if(local_start_sample_index!=Board_ReflectometerState.start_sample_index) local_average_count=0;
		if(local_average_count!=Board_ReflectometerState.average_count) local_average_count=0;
		local_start_sample_index=Board_ReflectometerState.start_sample_index; //update the starting point and reset window peak detectors and average counter
		local_window_max=0;
		local_window_min=4095;
		local_start_sample_index=Board_ReflectometerState.start_sample_index; //update starting point
	} else { //if sampling is enabled
		if(local_current_sample_index==local_start_sample_index)
		{
			local_is_running=ON;	//start storing data if on beginning of the window and tell it globally
			Board_ReflectometerState.is_running=local_is_running;
		}
	}

	if(local_is_running==ON)
	{
		if (local_window_max<local_sample_lin) local_window_max=local_sample_lin;	//window maximum detector
		if (local_window_min>local_sample_lin) local_window_min=local_sample_lin;	//window minimum detector

		//store the data and average them while storing
		if (local_current_sample_index>=local_start_sample_index)	//if not running over the measurement cycle border
		{
			Board_ReflectometerState.sampled_data[local_current_sample_index-local_start_sample_index]=(Board_ReflectometerState.sample_lin_last + (uint32_t)local_average_count*Board_ReflectometerState.sampled_data[local_current_sample_index-local_start_sample_index])/(local_average_count+1); //address data the normal way
		} else {
			Board_ReflectometerState.sampled_data[(local_current_sample_index+NUMBER_OF_POINTS)-local_start_sample_index]=(Board_ReflectometerState.sample_lin_last + (uint32_t)local_average_count*Board_ReflectometerState.sampled_data[(local_current_sample_index+NUMBER_OF_POINTS)-local_start_sample_index])/(local_average_count+1); //otherwise address data with shift to get over the border
		}

		//stop sampling if on end of the window, can run over the measurement cycle boundary
		if(local_current_sample_index==((local_start_sample_index+SAMPLE_MEMORY_SIZE-1)%NUMBER_OF_POINTS))
		{
			Board_ReflectometerState.sample_window_min=local_window_min;	//save the window peak detectors globally
			Board_ReflectometerState.sample_window_max=local_window_max;

			local_window_max=0;		//reset the window peak detectors locally
			local_window_min=4095;

			local_is_running=OFF;	//stop saving data and save it globally
			Board_ReflectometerState.is_running=local_is_running;

			local_average_count++;	//increase the average counter and save it globally
			Board_ReflectometerState.average_count=local_average_count;

			//if continuous sampling is disabled, disable sampling after finishing one measurement cycle
			if(Board_ReflectometerState.enable_continuous_run==OFF) Board_ReflectometerState.enable_sampling=OFF;

			//clear the pending measurement flag
			Board_ReflectometerState.pending_measurement=OFF;
		}
	}

	//increase the index
	local_current_sample_index++;
	if (local_current_sample_index==NUMBER_OF_POINTS) local_current_sample_index=0;
	Board_ReflectometerState.current_sample_index=local_current_sample_index;

	differentiation_index=(differentiation_index+1)%DIFF_POINTS;
}
