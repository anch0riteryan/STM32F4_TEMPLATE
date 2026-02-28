#include <stm32f4xx.h>
#include <stm32f4xx_hal.h>

#ifdef USE_FREERTOS
#include <FreeRTOS.h>
#include <task.h>
extern void xPortSysTickHandler (void);
#endif

void HardFault_Handler () {
	while (1);
}

void SysTick_Handler () {
	HAL_IncTick();

#ifdef USE_FREERTOS
	if (xTaskGetSchedulerState() != taskSCHEDULER_NOT_STARTED) {
		xPortSysTickHandler();
	}
#endif
}

