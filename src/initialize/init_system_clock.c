#include <user.h>
#include <stm32f4xx_hal.h>

static void clock_error_halt (void ) {
	while (1) {
		//
	}
}

void init_system_clock (void ) {
	RCC_OscInitTypeDef osc = {0};
	RCC_ClkInitTypeDef clk = {0};

	HAL_Init();

	__HAL_RCC_PWR_CLK_ENABLE();
	__HAL_PWR_VOLTAGESCALING_CONFIG(PWR_REGULATOR_VOLTAGE_SCALE1);

	osc.OscillatorType = RCC_OSCILLATORTYPE_HSE;
	osc.HSEState = RCC_HSE_ON;
	osc.PLL.PLLState = RCC_PLL_ON;
	osc.PLL.PLLSource = RCC_PLLSOURCE_HSE;
	osc.PLL.PLLM = 8;                 // HSE 8MHz / 8 = 1MHz
	osc.PLL.PLLN = 360;               // 1MHz * 360 = 360MHz (VCO)
	osc.PLL.PLLP = RCC_PLLP_DIV2;     // 360 / 2 = 180MHz SYSCLK
	osc.PLL.PLLQ = 7;
	if (HAL_RCC_OscConfig(&osc) != HAL_OK) {
		clock_error_halt();
	}

	if (HAL_PWREx_EnableOverDrive() != HAL_OK) {
		clock_error_halt();
	}

	clk.ClockType = RCC_CLOCKTYPE_SYSCLK | RCC_CLOCKTYPE_HCLK |
	                RCC_CLOCKTYPE_PCLK1  | RCC_CLOCKTYPE_PCLK2;
	clk.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
	clk.AHBCLKDivider = RCC_SYSCLK_DIV1;   // HCLK  = 180MHz
	clk.APB1CLKDivider = RCC_HCLK_DIV4;    // PCLK1 = 45MHz (max)
	clk.APB2CLKDivider = RCC_HCLK_DIV2;    // PCLK2 = 90MHz (max)
	if (HAL_RCC_ClockConfig(&clk, FLASH_LATENCY_5) != HAL_OK) {
		clock_error_halt();
	}
}
