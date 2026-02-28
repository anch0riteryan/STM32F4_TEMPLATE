#include <user.h>
#include <stm32f4xx_hal.h>

static UART_HandleTypeDef huart1;
static volatile uint8_t uart_ready = 0;

static void uart_error_halt (void ) {
	while (1) {
		//
	}
}

void init_uart_debug (void ) {
	GPIO_InitTypeDef gpio = {0};

	__HAL_RCC_USART1_CLK_ENABLE();
	__HAL_RCC_GPIOA_CLK_ENABLE();

	gpio.Pin = GPIO_PIN_9 | GPIO_PIN_10; // PA9=TX, PA10=RX
	gpio.Mode = GPIO_MODE_AF_PP;
	gpio.Pull = GPIO_PULLUP;
	gpio.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
	gpio.Alternate = GPIO_AF7_USART1;
	HAL_GPIO_Init(GPIOA, &gpio);

	huart1.Instance = USART1;
	huart1.Init.BaudRate = 115200;
	huart1.Init.WordLength = UART_WORDLENGTH_8B;
	huart1.Init.StopBits = UART_STOPBITS_1;
	huart1.Init.Parity = UART_PARITY_NONE;
	huart1.Init.Mode = UART_MODE_TX_RX;
	huart1.Init.HwFlowCtl = UART_HWCONTROL_NONE;
	huart1.Init.OverSampling = UART_OVERSAMPLING_16;

	if (HAL_UART_Init(&huart1) != HAL_OK) {
		uart_error_halt();
	}

	uart_ready = 1U;
}

int _write (int file, char *ptr, int len) {
	(void)file;

	if ((uart_ready == 0U) || (ptr == 0) || (len <= 0)) {
		return len;
	}

	if (HAL_UART_Transmit(&huart1, (uint8_t *)ptr, (uint16_t)len, HAL_MAX_DELAY) != HAL_OK) {
		return 0;
	}

	return len;
}

int uart_debug_read (uint8_t *ch, uint32_t timeout_ms) {
	if ((uart_ready == 0U) || (ch == 0)) {
		return (int)HAL_ERROR;
	}

	return (int)HAL_UART_Receive(&huart1, ch, 1U, timeout_ms);
}

int uart_debug_write (const uint8_t *data, uint16_t len, uint32_t timeout_ms) {
	if ((uart_ready == 0U) || (data == 0) || (len == 0U)) {
		return (int)HAL_ERROR;
	}

	return (int)HAL_UART_Transmit(&huart1, (uint8_t *)data, len, timeout_ms);
}
