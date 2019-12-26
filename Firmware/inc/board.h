/*
 * board.h
 *
 *  Created on: Dec 24, 2017
 *      Author: msboss
 */

#ifndef BOARD_H_
#define BOARD_H_

#include "stm32f10x.h"
#include "ssd1306.h"
#include "si5351.h"

#ifdef __cplusplus
 extern "C" {
#endif

typedef enum {FALSE=0, TRUE=1} bool;

#define MCP4725_ADDRESS	(0xC0+(1<<2))

#define CH_MAINSAMP_P	0
#define	CH_MAINSAMP_N	1
#define CH_SLAVESAMP_P	2
#define CH_SLAVESAMP_N	3
#define CH_nCML_OE		4
#define CH_PULSE_P		5
#define CH_PULSE_N		6
#define CH_ADC_TRIGGER	7

#define TIM_ETR_PORT	GPIOA
#define TIM_ETR_PERIPH	RCC_APB2Periph_GPIOA
#define TIM_ETR			GPIO_Pin_12

#define OUT_PORT		GPIOA
#define OUT_PERIPH		RCC_APB2Periph_GPIOA
#define OUT_REF			GPIO_Pin_6
#define OUT_REF_ADC_CHANNEL		ADC_Channel_6
#define OUT_LIN			GPIO_Pin_11
#define OUT_LIN_ADC_CHANNEL		ADC_Channel_5
#define OUT_LOG			GPIO_Pin_12
#define OUT_LOG_ADC_CHANNEL		ADC_Channel_7

#define ADC_TRG_PORT	GPIOB
#define ADC_TRG_PERIPH	RCC_APB2Periph_GPIOB
#define ADC_TRG			GPIO_Pin_11
#define ADC_TRG_PORTSOURCE	GPIO_PortSourceGPIOB
#define ADC_TRG_PINSOURCE	GPIO_PinSource11

#define USART_PORT		GPIOA
#define USART_PERIPH	RCC_APB2Periph_GPIOA
#define USART_RX		GPIO_Pin_10
#define USART_TX		GPIO_Pin_9

#define LED_PORT		GPIOB
#define LED_PERIPH		RCC_APB2Periph_GPIOB
#define LED_NOT_RDY		GPIO_Pin_1
#define LED_RDY			GPIO_Pin_2
#define LED_BUSY		GPIO_Pin_3

#define BTN_PORT		GPIOB
#define BTN_PERIPH		RCC_APB2Periph_GPIOB
#define BTN				GPIO_Pin_4

#define I2C_PORT		GPIOB
#define I2C_PERIPH		RCC_APB2Periph_GPIOB
#define SDA				GPIO_Pin_7
#define SCL				GPIO_Pin_6
#define SDA_PinSource	GPIO_PinSource7
#define SCL_PinSource	GPIO_PinSource6

#define nPLL_OE_PORT	GPIOB
#define nPLL_OE_PERIPH	RCC_APB2Periph_GPIOB
#define nPLL_OE			GPIO_Pin_8

#define nPLL_INT_PORT	GPIOB
#define nPLL_INT_PERIPH	RCC_APB2Periph_GPIOB
#define nPLL_INT		GPIO_Pin_9

#define nOLED_RESET_PORT	GPIOB
#define nOLED_RESET_PERIPH	RCC_APB2Periph_GPIOB
#define nOLED_RESET			GPIO_Pin_12

//#define CLK_

typedef enum {DISABLED=0, ENABLED=1} ForceState;

typedef enum {CAL_BOARD_INIT=0, CAL_WAIT_EDGE, CAL_CALIBRATING_SAMPLER, CAL_NOISE_ESTIMATION,
			CAL_FINDING_EDGE, CAL_FINDING_REFERENCE_PLANE, CAL_READY, CAL_WAIT_OPEN, CAL_WAIT_SHORT,
			CAL_WAIT_LOAD, CAL_RUNNING, CAL_WAIT_REFERENCE_PLANE, CAL_WAIT_DUT, CAL_MEASUREMENT_RUNNING,
			CAL_READY_TO_SEND, CAL_SENDING_DATA, CAL_DATA_SENT} CalibrationState;

#ifndef ENABLESTATE
#define ENABLESTATE
	typedef enum
	{
		OFF = 0,
		ON = 1
	} EnableState;
#endif

typedef enum
{
	ReflectometerMode_Run,
		//enable everything
		//when disabled by OEB, pulser HIGH, first sampler connected, second connected, ADC still running (mask OEB)
		//"normal" measurement mode


	ReflectometerMode_Test_Risetime_Disconnected_Sampler,
		//disable main sampler (sampler disconnected), otherwise the same as "Run"
		//when disabled by OEB, pulser HIGH, first sampler disconnected, second connected, ADC still running (mask OEB)
		//should be used to measure risetime using oscilloscope or spectrum analyser
	ReflectometerMode_Test_Risetime_Connected_Sampler,
		//disable main sampler (sampler connected), otherwise the same as "Run"
		//when disabled by OEB, the same as "Run"
		//should be used to measure risetime using oscilloscope or spectrum analyser

	ReflectometerMode_Test_ReturnLoss_Disconnected_Sampler,
		//The same as "Test_Risetime_Disconnected_Sampler", but pulser set permanently to HIGH
		//when disabled by OEB, the same as "Test_Risetime_Disconnected_Sampler"
		//should be used to measure return loss using VNA or TDR
	ReflectometerMode_Test_ReturnLoss_Connected_Sampler,
		//The same as "Test_Risetime_Connected_Sampler", but pulser set permanently to HIGH
		//when disabled by OEB, the same as "Test_Risetime_Connected_Sampler"
		//should be used to measure return loss using VNA or TDR


	ReflectometerMode_Calibrate_Sampler_HIGH,
		//disable pulser (set to HIGH), otherwise the same as "Run"
		//when disabled by OEB, the same as "Run"
		//should be used to measure dependence of linear channel on DAC value
	ReflectometerMode_Calibrate_Sampler_LOW,
		//disable pulser (set to HLOW), otherwise the same as "Run"
		//when disabled by OEB, the same as "Run"
		//should be used to measure dependence of linear channel on DAC value
	ReflectometerMode_Calibrate_Log_Detector,
		//the same as "Calibrate_Sampler"
		//when disabled by OEB, the same as "Calibrate_Sampler"
		//should be used to measure log detector characteristic using DAC


	ReflectometerMode_Stop
		//everything disabled, but still running
		//don't care about OEB
		//should be used as "safe" mode
} Board_ReflectometerModeTypeDef;

typedef struct
{
	uint16_t low_value;
	uint16_t low_variance;
	uint16_t high_value;
	uint16_t high_variance;

	uint8_t ideal_averaging;

	uint32_t T_min;
	uint32_t T_max;
	uint32_t A_preshoot;
	uint32_t A_overshoot;
	uint32_t T_10_percent;
	uint32_t T_90_percent;
	uint32_t T_overshoot;
	uint32_t T_preshoot;

	uint32_t calibration_trace_start_index;
	uint16_t calibration_trace[1024];
} Board_ReflectometerCalibrationTypeDef;

typedef enum
{
	CAL_OPEN=0,
	CAL_LOAD=1,
	CAL_SHORT=2
} Board_ReflectometerCalibrationStandardTypeDef;

typedef struct
{
	volatile uint16_t sample_log_last;
	volatile uint16_t sample_lin_last;

	volatile uint16_t sample_cycle_max;
	volatile uint16_t sample_cycle_min;

	volatile uint16_t sample_window_max;
	volatile uint16_t sample_window_min;

	uint16_t dac_value;

	volatile uint32_t current_sample_index;
	volatile uint32_t start_sample_index;
	volatile uint32_t largest_differentiation_point;
	uint32_t rising_edge_start_index;
	uint32_t rising_edge_center_index;

	volatile uint16_t average_count;

	volatile EnableState enable_sampling;
	volatile EnableState is_running;
	volatile uint16_t sampled_data[4096];
	volatile EnableState enable_continuous_run;
	volatile EnableState pending_measurement;

	uint16_t dac_value__ideal;

	uint16_t open_low_level;
	uint16_t open_high_level;
	uint16_t open_low_variation;
	uint16_t open_high_variation;

	uint16_t load_low_level;
	uint16_t load_high_level;
	uint16_t load_low_variation;
	uint16_t load_high_variation;

	uint8_t ideal_averaging;

	Board_ReflectometerModeTypeDef Board_ReflectometerMode;

	Board_ReflectometerCalibrationTypeDef calibration[3];

	volatile uint32_t samples_missed;
} Board_ReflectometerStateTypeDef;

#include "main.h"

void SysTick_Handler(void);
void Delay_ms(uint32_t Wait);
void getnum(uint16_t num, char str[6]);
void getnum32(uint32_t num, char str[11]);
void getbits(uint8_t bits, char str[9]);

void dispOK(SSD1306_ConfigTypeDef *SSD1306_ConfigStruct, uint8_t y);
void dispError(SSD1306_ConfigTypeDef *SSD1306_ConfigStruct, uint8_t y);

void Si5351_ClearStickyBits(Si5351_ConfigTypeDef *Si5351_ConfigStruct);

void Init_Board(Si5351_ConfigTypeDef *Si5351_ConfigStruct, SSD1306_ConfigTypeDef *SSD1306_ConfigStruct, Framebuffer *display_buffer, Board_ReflectometerStateTypeDef *Board_ReflectometerState);

void I2C_Board_Init(ForceState Force_Init);

void Button_Init(void);

void LED_Init(void);

void OLED_Init(SSD1306_ConfigTypeDef *SSD1306_ConfigStruct, Framebuffer *display_buffer);
void OLED_Reset(void);

void Si5351_Board_Init(Si5351_ConfigTypeDef *Si5351_ConfigStruct);

void SY54020_Init(void);

void MCP4725_Init(void);
int MCP4725_SetVoltage(uint16_t data_code);

void SERIAL_Init(void);

void Timer_Init(void);

void ReflectometerMode_Init(Si5351_ConfigTypeDef *Si5351_ConfigStruct, Board_ReflectometerModeTypeDef mode);

void SSD1306_DrawProgressBar(SSD1306_ConfigTypeDef *SSD1306_ConfigStruct);

void SSD1306_DrawProgressIndicator(SSD1306_ConfigTypeDef *SSD1306_ConfigStruct, uint8_t progress);

void SSD1306_DrawMeasurementProgressIndicator(SSD1306_ConfigTypeDef *SSD1306_ConfigStruct, uint8_t progress, uint8_t run, uint8_t run_number);

void SSD1306_StartProgressBar(SSD1306_ConfigTypeDef *SSD1306_ConfigStruct);

void SSD1306_StopProgressBar(SSD1306_ConfigTypeDef *SSD1306_ConfigStruct);

void ADC_BoardInit(void);

void EXTI15_10_IRQHandler(void);

void USART1_IRQHandler(void);

void ADC1_2_IRQHandler(void);

bool Compare_Strings(char string1[], char string2[]);

EnableState Calibrate_Si5351(Si5351_ConfigTypeDef *Si5351_ConfigStruct, SSD1306_ConfigTypeDef *SSD1306_ConfigStruct, Framebuffer *display_buffer, Board_ReflectometerStateTypeDef *Board_ReflectometerState, EnableState RunGraphical);

EnableState Calibrate_Sampler_Offset(Si5351_ConfigTypeDef *Si5351_ConfigStruct, SSD1306_ConfigTypeDef *SSD1306_ConfigStruct, Framebuffer *display_buffer, Board_ReflectometerStateTypeDef *Board_ReflectometerState, EnableState RunGraphical);

EnableState Calibrate_Rising_Edge_Position_Guess(Si5351_ConfigTypeDef *Si5351_ConfigStruct, SSD1306_ConfigTypeDef *SSD1306_ConfigStruct, Framebuffer *display_buffer, Board_ReflectometerStateTypeDef *Board_ReflectometerState, EnableState RunGraphical);

EnableState Calibrate_Logic_Levels(Si5351_ConfigTypeDef *Si5351_ConfigStruct, SSD1306_ConfigTypeDef *SSD1306_ConfigStruct, Framebuffer *display_buffer, Board_ReflectometerStateTypeDef *Board_ReflectometerState, Board_ReflectometerCalibrationStandardTypeDef Calibration_Normal, EnableState RunGraphical);

EnableState Calibrate_Get_Calibration_Normal_Response(Si5351_ConfigTypeDef *Si5351_ConfigStruct, SSD1306_ConfigTypeDef *SSD1306_ConfigStruct, Framebuffer *display_buffer, Board_ReflectometerStateTypeDef *Board_ReflectometerState, Board_ReflectometerCalibrationStandardTypeDef Calibration_Normal, EnableState RunGraphical);


#ifdef __cplusplus
}
#endif

#endif /* BOARD_H_ */
