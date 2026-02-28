#include <user.h>
#include <stdio.h>
#include <stm32f4xx_hal.h>

#ifdef USE_FREERTOS
#include <FreeRTOS.h>
#include <croutine.h>
#include <task.h>
#include <timers.h>

static void init_led_gpio (void ) {
	GPIO_InitTypeDef gpio = {0};

	__HAL_RCC_GPIOG_CLK_ENABLE();

	gpio.Pin = GPIO_PIN_13 | GPIO_PIN_14;
	gpio.Mode = GPIO_MODE_OUTPUT_PP;
	gpio.Pull = GPIO_NOPULL;
	gpio.Speed = GPIO_SPEED_FREQ_LOW;
	HAL_GPIO_Init (GPIOG, &gpio);

	HAL_GPIO_WritePin (GPIOG, GPIO_PIN_13 | GPIO_PIN_14, GPIO_PIN_RESET);
}

static void vLedTask (void *arg) {
	(void)arg;

	for (;;) {
		HAL_GPIO_WritePin(GPIOG, GPIO_PIN_13, GPIO_PIN_SET);
		HAL_GPIO_WritePin(GPIOG, GPIO_PIN_14, GPIO_PIN_RESET);
		vTaskDelay(pdMS_TO_TICKS(1000));

		HAL_GPIO_WritePin(GPIOG, GPIO_PIN_13, GPIO_PIN_RESET);
		HAL_GPIO_WritePin(GPIOG, GPIO_PIN_14, GPIO_PIN_SET);
		vTaskDelay(pdMS_TO_TICKS(1000));
	}
}

static StaticTask_t xLedTaskTCB;
static StackType_t uxLedTaskStack[256];
#endif

int main (void ) {
	init_system_clock ();
	init_uart_debug ();
	init_fsmc_sdram ();

	init_led_gpio ();

#ifdef USE_FREERTOS
	rtos_cli_start ();

	xTaskCreateStatic (vLedTask, "led", 256, 0, tskIDLE_PRIORITY + 1U, uxLedTaskStack, &xLedTaskTCB);
	vTaskStartScheduler ();
#endif

	while (1) {
		//
	}

	return 0;
}
