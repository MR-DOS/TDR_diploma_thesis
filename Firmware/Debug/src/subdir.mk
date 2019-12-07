################################################################################
# Automatically-generated file. Do not edit!
################################################################################

# Add inputs and outputs from these tool invocations to the build variables 
C_SRCS += \
../src/board.c \
../src/main.c \
../src/si5351.c \
../src/ssd1306.c \
../src/syscalls.c \
../src/system_stm32f10x.c 

OBJS += \
./src/board.o \
./src/main.o \
./src/si5351.o \
./src/ssd1306.o \
./src/syscalls.o \
./src/system_stm32f10x.o 

C_DEPS += \
./src/board.d \
./src/main.d \
./src/si5351.d \
./src/ssd1306.d \
./src/syscalls.d \
./src/system_stm32f10x.d 


# Each subdirectory must supply rules for building sources it contributes
src/%.o: ../src/%.c
	@echo 'Building file: $<'
	@echo 'Invoking: MCU GCC Compiler'
	@echo $(PWD)
	arm-none-eabi-gcc -mcpu=cortex-m3 -mthumb -mfloat-abi=soft -DSTM32 -DSTM32F1 -DSTM32F103C8Tx -DDEBUG -DSTM32F10X_MD -DUSE_STDPERIPH_DRIVER -I"/home/msboss/Documents/SW4STM32/TDR5351_FW/StdPeriph_Driver/inc" -I"/home/msboss/Documents/SW4STM32/TDR5351_FW/inc" -I"/home/msboss/Documents/SW4STM32/TDR5351_FW/CMSIS/device" -I"/home/msboss/Documents/SW4STM32/TDR5351_FW/CMSIS/core" -Og -g3 -Wall -fmessage-length=0 -v -ffunction-sections -fdata-sections -c -MMD -MP -MF"$(@:%.o=%.d)" -MT"$@" -o "$@" "$<"
	@echo 'Finished building: $<'
	@echo ' '


