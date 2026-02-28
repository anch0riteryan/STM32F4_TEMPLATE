#include <user.h>
#include <stdio.h>
#include <string.h>
#include <stm32f4xx_hal.h>

#ifdef USE_FREERTOS
#include <FreeRTOS.h>
#include <task.h>
#include <FreeRTOS_CLI.h>

static BaseType_t prvHelloCommand (char *write_buf, size_t write_buf_len, const char *cmd_str) {
	(void)cmd_str;
	snprintf(write_buf, write_buf_len, "hello from FreeRTOS CLI\r\n");
	return pdFALSE;
}

static const CLI_Command_Definition_t xHelloCommand = {
	"hello",
	"hello:\r\n Print hello message\r\n",
	prvHelloCommand,
	0
};
static CLI_Definition_List_Item_t xHelloCommandStorage;

static StaticTask_t xCliTaskTCB;
static StackType_t uxCliTaskStack[512];

static void vCliTask (void *arg) {
	char xCliInput[96] = {0};
	char xCliOutput[256] = {0};
	size_t xCliIndex = 0;
	uint8_t xCliPromptShown = 0;
	uint8_t ch = 0;
	BaseType_t more = pdFALSE;
	const char prompt[] = "\r\n> ";
	(void)arg;

	for (;;) {
		if (xCliPromptShown == 0U) {
			uart_debug_write((const uint8_t *)prompt, (uint16_t)strlen(prompt), HAL_MAX_DELAY);
			xCliPromptShown = 1U;
		}

		if (uart_debug_read(&ch, 50U) != (int)HAL_OK) {
			vTaskDelay(pdMS_TO_TICKS(10));
			continue;
		}

		if ((ch == '\r') || (ch == '\n')) {
			const char eol[] = "\r\n";
			uart_debug_write((const uint8_t *)eol, (uint16_t)strlen(eol), HAL_MAX_DELAY);

			if (xCliIndex > 0U) {
				xCliInput[xCliIndex] = '\0';
				do {
					more = FreeRTOS_CLIProcessCommand(xCliInput, xCliOutput, sizeof(xCliOutput));
					uart_debug_write((const uint8_t *)xCliOutput, (uint16_t)strlen(xCliOutput), HAL_MAX_DELAY);
				} while (more != pdFALSE);
				xCliIndex = 0U;
				xCliInput[0] = '\0';
			}

			uart_debug_write((const uint8_t *)prompt, (uint16_t)strlen(prompt), HAL_MAX_DELAY);
			continue;
		}

		if ((ch == '\b') || (ch == 0x7FU)) {
			if (xCliIndex > 0U) {
				const char bs[] = "\b \b";
				xCliIndex--;
				xCliInput[xCliIndex] = '\0';
				uart_debug_write((const uint8_t *)bs, (uint16_t)strlen(bs), HAL_MAX_DELAY);
			}
			continue;
		}

		if ((ch >= 0x20U) && (ch <= 0x7EU)) {
			if (xCliIndex < (sizeof(xCliInput) - 1U)) {
				xCliInput[xCliIndex++] = (char)ch;
				uart_debug_write(&ch, 1U, HAL_MAX_DELAY);
			}
		}
	}
}

void rtos_cli_start (void ) {
	FreeRTOS_CLIRegisterCommandStatic(&xHelloCommand, &xHelloCommandStorage);
	xTaskCreateStatic(vCliTask, "cli", 512, 0, tskIDLE_PRIORITY + 1U, uxCliTaskStack, &xCliTaskTCB);
}
#else
void rtos_cli_start (void ) {
}
#endif
