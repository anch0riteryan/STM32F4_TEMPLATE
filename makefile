APP_NAME := STM32F4_TEMPLATE

TOOLCHAIN := arm-none-eabi
CC := $(TOOLCHAIN)-gcc
AS := $(TOOLCHAIN)-as
AR := $(TOOLCHAIN)-ar
ARFLAGS := rcs

USE_FREERTOS := true

# CMSIS
CMSIS_PATH   := ./../../../CMSIS_6/CMSIS

CHIPSET_PATH := ./../../STM32CubeF4/Drivers/CMSIS/Device/ST/STM32F4xx
STARTUP_PATH := $(CHIPSET_PATH)/Source/Templates/gcc
SYSTEM_PATH  := $(CHIPSET_PATH)/Source/Templates
HAL_PATH     := ./../../STM32CubeF4/Drivers/STM32F4xx_HAL_Driver
LD_PATH      := ./../../STM32F4_LD

# ARM_MATH support
CMSIS_DSP_PATH := ./../../../CMSIS-DSP

# FreeRTOS kernel path
FREERTOS_PATH := ./../../../FreeRTOSv202406.01-LTS/FreeRTOS-LTS/FreeRTOS/FreeRTOS-Kernel
FREERTOS_CLI_PATH := ./../../../FreeRTOS/FreeRTOS-Plus/Source/FreeRTOS-Plus-CLI

# Drivers path
DRIVER_PATH := ./../../../drivers

# apps source folder
SRC_PATH := ./src
INC_PATH := ./inc
OBJ_PATH := ./obj
LIB_PATH := ./../../libs

# ARM CORTEX-M4F CMSIS startup_stm32f429xx.s file
startup_src += $(wildcard $(STARTUP_PATH)/startup_stm32f429xx.s)
startup_obj += $(patsubst $(STARTUP_PATH)/%.s, $(OBJ_PATH)/cmsis/%.o, $(startup_src))

# ARM CORTEX-M4F CMSIS system_stm32f4xx.c file
system_src += $(wildcard $(SYSTEM_PATH)/system_stm32f4xx.c)
system_obj += $(patsubst $(SYSTEM_PATH)/%.c, $(OBJ_PATH)/cmsis/%.o, $(system_src))

# ARM DSP, Math support
arm_dsp_src += $(shell find $(CMSIS_DSP_PATH)/Source -name '*.c' ! -name '_*.c')
arm_dsp_obj += $(patsubst $(CMSIS_DSP_PATH)/%.c, $(OBJ_PATH)/cmsis-dsp/%.o, $(arm_dsp_src))

# STM HAL files
hal_src += $(shell find $(HAL_PATH)/Src -name '*.c' ! -name '*_template.c')
hal_obj += $(patsubst $(HAL_PATH)/%.c, $(OBJ_PATH)/hal/%.o, $(hal_src))

# FreeRTOS support
freertos_src += $(shell find $(FREERTOS_PATH)/portable/GCC/ARM_CM4F -name *.c)
freertos_src += $(shell find $(FREERTOS_PATH) -maxdepth 1 -name *.c)
freertos_obj += $(patsubst $(FREERTOS_PATH)/%.c, $(OBJ_PATH)/freertos/%.o, $(freertos_src))

# FreeRTOS CLI support
freertos_cli_src += $(shell find $(FREERTOS_CLI_PATH) -maxdepth 1 -name *.c)
freertos_cli_obj += $(patsubst $(FREERTOS_CLI_PATH)/%.c, $(OBJ_PATH)/freertos_cli/%.o, $(freertos_cli_src))

# apps libs foldes @ ./libs/[LIB_NAME]
#libs += modbus
#libs += nvm
LIB_INC := $(foreach lib, $(libs), -I$(LIB_PATH)/$(lib))

# apps libs
libs_src += $(foreach \
	lib_name, \
	$(libs), \
	$(shell find $(LIB_PATH)/$(lib_name) -name *.c) \
)
libs_obj += $(patsubst $(LIB_PATH)/%.c, $(OBJ_PATH)/libs/%.o, $(libs_src))

# drivers
#drivers_src += $(shell find $(DRIVER_PATH) -name *.c)
drivers_obj += $(patsubst $(DRIVER_PATH)/%.c, $(OBJ_PATH)/drivers/%.o, $(drivers_src))

# apps src
headers += $(shell find $(INC_PATH) -name *.h)
headers += $(shell find $(SRC_PATH) -name *.h)
src := $(shell find $(SRC_PATH) -name *.c)
obj += $(patsubst $(SRC_PATH)/%.c, $(OBJ_PATH)/%.o, $(src))
APP_INC := $(foreach \
	inc,\
	$(sort $(dir $(src)) $(dir $(headers))),\
	-I$(inc)\
)

#linker_script := $(LD_PATH)/STM32F429ZITX_FLASH.ld
linker_script := $(LD_PATH)/STM32F429ZITX_FLASH_SDRAM.ld
specs := --specs=nosys.specs
mcu := -mcpu=cortex-m4 -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -std=gnu2x
debug := -g -gdwarf-4 -O0

CFLAGS += $(mcu) $(specs)
CFLAGS += -DSTM32F429xx
CFLAGS += -DARM_MATH_CM4F
CFLAGS += \
	-I$(CMSIS_PATH)/Core/Include \
	-I$(CHIPSET_PATH)/Include \
	-I$(CMSIS_DSP_PATH)/Include \
	-I$(CMSIS_DSP_PATH)/PrivateInclude \
	-I$(HAL_PATH)/Inc \
	-I$(FREERTOS_PATH)/include \
	-I$(FREERTOS_PATH)/portable/GCC/ARM_CM4F \
	-I$(FREERTOS_CLI_PATH) \
	-I$(INC_PATH)

ifeq ($(USE_FREERTOS),true)
CFLAGS += -DUSE_FREERTOS
endif

# LIBS include
CFLAGS += $(LIB_INC)

# apps include
CFLAGS += $(APP_INC)

CFLAGS += -Wall -Werror=implicit-function-declaration
CFLAGS += -Wno-unused-value
CFLAGS += $(debug)
CFLAGS += -c -o

LDFLAGS += $(mcu) $(specs)
LDFLAGS += -lc -lm -lg -lgcc -lrdimon -lnosys
LDFLAGS += -Wl,--gc-sections -Wl,--print-memory-usage -Wl,--no-warn-rwx-segments -Wl,--cref -Wl,-Map=./$(APP_NAME).map
LDFLAGS += $(debug)

# LINKER DESCIPRTOR
LDFLAGS += -T$(linker_script)

.PHONY : all size clean distclean

objs += $(startup_obj)
objs += $(system_obj)
objs += $(hal_obj)

ifeq ($(USE_FREERTOS),true)
objs += $(freertos_obj)
objs += $(freertos_cli_obj)
endif

objs += $(drivers_obj)
objs += $(obj) $(libs_obj)
objs += $(arm_dsp_obj)

ARCHIVE_PATH := $(OBJ_PATH)/archive
hal_lib := $(ARCHIVE_PATH)/libhal.a
cmsis_dsp_lib := $(ARCHIVE_PATH)/libcmsis-dsp.a

core_objs := $(startup_obj) $(system_obj) $(drivers_obj) $(obj) $(libs_obj)
ifeq ($(USE_FREERTOS),true)
core_objs += $(freertos_obj)
core_objs += $(freertos_cli_obj)
endif

link_inputs := $(core_objs) $(hal_lib) $(cmsis_dsp_lib)

all: dump_info check_obj_path $(APP_NAME).elf $(APP_NAME).hex
	@echo done!

clean:
	rm -f $(obj) $(libs_obj) $(drivers_obj) $(freertos_obj) $(freertos_cli_obj)
	rm -f ./$(APP_NAME).elf ./$(APP_NAME).hex ./$(APP_NAME).map
	rm -f $(OBJ_PATH)/link.rsp

distclean: clean
	rm -rf ./obj
	rm -f $(hal_lib) $(cmsis_dsp_lib) $(ARCHIVE_PATH)/*.rsp

dump_info:
	@echo "----------------------------------------"
	@echo "---- ARM Cortex-M4F SDK STM32F429ZI ----"
	@echo "----------------------------------------"

path := $(sort $(dir $(objs)) $(ARCHIVE_PATH)/)
check_obj_path:
	@mkdir -p $(path)

check_objs:
	@echo $(objs)

$(hal_lib): $(hal_obj)
	@$(file >$(ARCHIVE_PATH)/hal.rsp,$^)
	@echo $(AR) $@
	@$(AR) $(ARFLAGS) $@ @$(ARCHIVE_PATH)/hal.rsp

$(cmsis_dsp_lib): $(arm_dsp_obj)
	@$(file >$(ARCHIVE_PATH)/cmsis-dsp.rsp,$^)
	@echo $(AR) $@
	@$(AR) $(ARFLAGS) $@ @$(ARCHIVE_PATH)/cmsis-dsp.rsp

# ELF
$(APP_NAME).elf : $(core_objs) $(hal_lib) $(cmsis_dsp_lib)
	@$(file >$(OBJ_PATH)/link.rsp,$(link_inputs))
	@$(CC) @$(OBJ_PATH)/link.rsp $(LDFLAGS) -o ./$@

# HEX
$(APP_NAME).hex : $(APP_NAME).elf
	$(TOOLCHAIN)-objcopy $< -Oihex $@

# SIZE
size: $(APP_NAME).elf
	$(TOOLCHAIN)-size -A $(APP_NAME).elf

# CMSIS STARTUP .o RULES
$(OBJ_PATH)/cmsis/%.o : $(STARTUP_PATH)/%.s
	@echo $(CC) $<
	@$(CC) $< $(CFLAGS) $@

$(OBJ_PATH)/cmsis/%.o : $(SYSTEM_PATH)/%.c
	@echo $(CC) $<
	@$(CC) $< $(CFLAGS) $@

# CMSIS-DSP .o RULES
$(OBJ_PATH)/cmsis-dsp/%.o : $(CMSIS_DSP_PATH)/%.c
	@echo $(CC) $<
	@$(CC) $< $(CFLAGS) $@

# HAL .o RULES
$(OBJ_PATH)/hal/%.o : $(HAL_PATH)/%.c
	@echo $(CC) $<
	@$(CC) $< $(CFLAGS) $@

# FREERTOS .o rules
$(OBJ_PATH)/freertos/%.o : $(FREERTOS_PATH)/%.c
	@echo $(CC) $<
	@$(CC) $< $(CFLAGS) $@

# FREERTOS_CLI .o rules
$(OBJ_PATH)/freertos_cli/%.o : $(FREERTOS_CLI_PATH)/%.c
	@echo $(CC) $<
	@$(CC) $< $(CFLAGS) $@

# LIBS .o RULES
$(OBJ_PATH)/libs/%.o : $(LIB_PATH)/%.c
	@echo $(CC) $<
	@$(CC) $< $(CFLAGS) $@

# DRIVERS .o RULES
$(OBJ_PATH)/drivers/%.o : $(DRIVER_PATH)/%.c
	@echo $(CC) $<
	@$(CC) $< $(CFLAGS) $@

# USER APPS .o RULES
$(OBJ_PATH)/%.o : $(SRC_PATH)/%.c
	@echo $(CC) $<
	@$(CC) $< $(CFLAGS) $@
