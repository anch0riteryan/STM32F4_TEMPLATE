#include <user.h>
#include <stm32f4xx_hal.h>

static SDRAM_HandleTypeDef hsdram1;

static void sdram_error_halt (void ) {
	while (1) {
		//
	}
}

static void init_sdram_gpio (void ) {
	GPIO_InitTypeDef gpio = {0};

	__HAL_RCC_FMC_CLK_ENABLE();
	__HAL_RCC_GPIOB_CLK_ENABLE();
	__HAL_RCC_GPIOC_CLK_ENABLE();
	__HAL_RCC_GPIOD_CLK_ENABLE();
	__HAL_RCC_GPIOE_CLK_ENABLE();
	__HAL_RCC_GPIOF_CLK_ENABLE();
	__HAL_RCC_GPIOG_CLK_ENABLE();

	gpio.Mode = GPIO_MODE_AF_PP;
	gpio.Pull = GPIO_PULLUP;
	gpio.Speed = GPIO_SPEED_FREQ_VERY_HIGH;
	gpio.Alternate = GPIO_AF12_FMC;

	// PB5,6 -> FMC_SDCKE1,SDNE1
	gpio.Pin = GPIO_PIN_5 | GPIO_PIN_6;
	HAL_GPIO_Init(GPIOB, &gpio);

	// PC0  -> FMC_SDNWE
	gpio.Pin = GPIO_PIN_0;
	HAL_GPIO_Init(GPIOC, &gpio);

	// PD0,1,8,9,10,14,15 -> FMC_D2,D3,D13,D14,D15,D0,D1
	gpio.Pin = GPIO_PIN_0 | GPIO_PIN_1 | GPIO_PIN_8 | GPIO_PIN_9 |
	           GPIO_PIN_10 | GPIO_PIN_14 | GPIO_PIN_15;
	HAL_GPIO_Init(GPIOD, &gpio);

	// PE0,1,7..15 -> FMC_NBL0,NBL1,D4..D12
	gpio.Pin = GPIO_PIN_0 | GPIO_PIN_1 | GPIO_PIN_7 | GPIO_PIN_8 |
	           GPIO_PIN_9 | GPIO_PIN_10 | GPIO_PIN_11 | GPIO_PIN_12 |
	           GPIO_PIN_13 | GPIO_PIN_14 | GPIO_PIN_15;
	HAL_GPIO_Init(GPIOE, &gpio);

	// PF0..5,11..15 -> FMC_A0..A5,SDNRAS,A6..A9
	gpio.Pin = GPIO_PIN_0 | GPIO_PIN_1 | GPIO_PIN_2 | GPIO_PIN_3 |
	           GPIO_PIN_4 | GPIO_PIN_5 | GPIO_PIN_11 | GPIO_PIN_12 |
	           GPIO_PIN_13 | GPIO_PIN_14 | GPIO_PIN_15;
	HAL_GPIO_Init(GPIOF, &gpio);

	// PG0,1,4,5,8,15 -> FMC_A10,A11,BA0,BA1,SDCLK,SDNCAS
	gpio.Pin = GPIO_PIN_0 | GPIO_PIN_1 | GPIO_PIN_4 |
	           GPIO_PIN_5 | GPIO_PIN_8 | GPIO_PIN_15;
	HAL_GPIO_Init(GPIOG, &gpio);
}

static void init_sdram_sequence (void ) {
	FMC_SDRAM_CommandTypeDef cmd = {0};
	uint32_t mode = 0;

	// 1) Enable SDRAM clock
	cmd.CommandMode = FMC_SDRAM_CMD_CLK_ENABLE;
	cmd.CommandTarget = FMC_SDRAM_CMD_TARGET_BANK2;
	cmd.AutoRefreshNumber = 1;
	cmd.ModeRegisterDefinition = 0;
	if (HAL_SDRAM_SendCommand(&hsdram1, &cmd, HAL_MAX_DELAY) != HAL_OK) {
		sdram_error_halt();
	}

	HAL_Delay(1);

	// 2) Precharge all
	cmd.CommandMode = FMC_SDRAM_CMD_PALL;
	cmd.CommandTarget = FMC_SDRAM_CMD_TARGET_BANK2;
	cmd.AutoRefreshNumber = 1;
	cmd.ModeRegisterDefinition = 0;
	if (HAL_SDRAM_SendCommand(&hsdram1, &cmd, HAL_MAX_DELAY) != HAL_OK) {
		sdram_error_halt();
	}

	// 3) Auto refresh
	cmd.CommandMode = FMC_SDRAM_CMD_AUTOREFRESH_MODE;
	cmd.CommandTarget = FMC_SDRAM_CMD_TARGET_BANK2;
	cmd.AutoRefreshNumber = 8;
	cmd.ModeRegisterDefinition = 0;
	if (HAL_SDRAM_SendCommand(&hsdram1, &cmd, HAL_MAX_DELAY) != HAL_OK) {
		sdram_error_halt();
	}

	// 4) Load mode register: burst=1, sequential, CAS=3, standard, single write burst
	mode = 0x0230U;
	cmd.CommandMode = FMC_SDRAM_CMD_LOAD_MODE;
	cmd.CommandTarget = FMC_SDRAM_CMD_TARGET_BANK2;
	cmd.AutoRefreshNumber = 1;
	cmd.ModeRegisterDefinition = mode;
	if (HAL_SDRAM_SendCommand(&hsdram1, &cmd, HAL_MAX_DELAY) != HAL_OK) {
		sdram_error_halt();
	}

	// Refresh counter for 90MHz SDRAM clock:
	// (64ms / 8192rows) * 90MHz - 20 ~= 683
	if (HAL_SDRAM_ProgramRefreshRate(&hsdram1, 683) != HAL_OK) {
		sdram_error_halt();
	}
}

void init_fsmc_sdram (void ) {
	FMC_SDRAM_TimingTypeDef timing = {0};

	init_sdram_gpio();

	hsdram1.Instance = FMC_SDRAM_DEVICE;
	hsdram1.Init.SDBank = FMC_SDRAM_BANK2;
	hsdram1.Init.ColumnBitsNumber = FMC_SDRAM_COLUMN_BITS_NUM_8;
	hsdram1.Init.RowBitsNumber = FMC_SDRAM_ROW_BITS_NUM_12;
	hsdram1.Init.MemoryDataWidth = FMC_SDRAM_MEM_BUS_WIDTH_16;
	hsdram1.Init.InternalBankNumber = FMC_SDRAM_INTERN_BANKS_NUM_4;
	hsdram1.Init.CASLatency = FMC_SDRAM_CAS_LATENCY_3;
	hsdram1.Init.WriteProtection = FMC_SDRAM_WRITE_PROTECTION_DISABLE;
	hsdram1.Init.SDClockPeriod = FMC_SDRAM_CLOCK_PERIOD_2;
	hsdram1.Init.ReadBurst = FMC_SDRAM_RBURST_ENABLE;
	hsdram1.Init.ReadPipeDelay = FMC_SDRAM_RPIPE_DELAY_1;

	// Timing for IS42S16400J with SDCLK=90MHz
	timing.LoadToActiveDelay = 2;
	timing.ExitSelfRefreshDelay = 7;
	timing.SelfRefreshTime = 4;
	timing.RowCycleDelay = 7;
	timing.WriteRecoveryTime = 2;
	timing.RPDelay = 2;
	timing.RCDDelay = 2;

	if (HAL_SDRAM_Init(&hsdram1, &timing) != HAL_OK) {
		sdram_error_halt();
	}

	init_sdram_sequence();
}
