
#ifndef _USER_
#define _USER_

#include <stm32f4xx.h>

void init_clock (void );
void init_system_clock (void );
void init_fsmc_sdram (void );
void init_uart_debug (void );
void rtos_cli_start (void );
int uart_debug_read (uint8_t *ch, uint32_t timeout_ms);
int uart_debug_write (const uint8_t *data, uint16_t len, uint32_t timeout_ms);

#endif
