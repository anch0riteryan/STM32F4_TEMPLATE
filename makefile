APP_NAME := STM32F4-TEMPLATE

TOOLCHAIN := arm-none-eabi
CC := $(TOOLCHAIN)-gcc
AS := $(TOOLCHAIN)-as

USE_FREERTOS := true

# CMSIS
CMSIS_PATH   := ./../../../CMSIS_6/CMSIS

CHIPSET_PATH := ./../../STM32F4xx_DSP_StdPeriph_Lib_V1.9.0/Libraries/CMSIS/Device/ST/STM32F4xx
STARTUP_PATH := $(CHIPSET_PATH)/Source/Templates/gcc_ride7
SYSTEM_PATH  := $(CHIPSET_PATH)/Source/Templates

LD_PATH      := ./../../STM32F4_LD

# ARM_MATH support
CMSIS_DSP_PATH := ./../../../CMSIS-DSP

# FreeRTOS kernel path
FREERTOS_PATH := ./../../../FreeRTOSv202406.01-LTS/FreeRTOS-LTS/FreeRTOS/FreeRTOS-Kernel

# apps source folder
SRC_PATH := ./src
INC_PATH := ./inc
OBJ_PATH := ./obj
LIB_PATH := ./../../libs

# ARM CORTEX-M4F CMSIS startup_stm32f429_439xx.s file
startup_src += $(wildcard $(STARTUP_PATH)/startup_stm32f429_439xx.s)
startup_obj += $(patsubst $(STARTUP_PATH)/%.s, $(OBJ_PATH)/cmsis/%.o, $(startup_src))

# ARM CORTEX-M4F CMSIS system_stm32f4xx.c file
system_src += $(wildcard $(SYSTEM_PATH)/system_stm32f4xx.c)
system_obj += $(patsubst $(SYSTEM_PATH)/%.c, $(OBJ_PATH)/cmsis/%.o, $(system_src))

# ARM DSP, Math support
arm_dsp_src += $(shell find $(CMSIS_DSP_PATH)/Source -name *.c)
arm_dsp_obj += $(patsubst $(CMSIS_DSP_PATH)/%.c, $(OBJ_PATH)/cmsis-dsp/%.o, $(arm_dsp_src))

# FreeRTOS support
freertos_src += $(shell find $(FREERTOS_PATH)/portable/GCC/ARM_CM4F -name *.c)
freertos_src += $(shell find $(FREERTOS_PATH) -maxdepth 1 -name *.c)
freertos_obj += $(patsubst $(FREERTOS_PATH)/%.c, $(OBJ_PATH)/freertos/%.o, $(freertos_src))

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

linker_script := $(LD_PATH)/STM32F429ZI_FLASH.ld
specs := --specs=nosys.specs
mcu := -mcpu=cortex-m4 -mfpu=fpv4-sp-d16 -mfloat-abi=hard -mthumb -std=gnu2x
debug := -g -gdwarf-4 -O0


CFLAGS += $(mcu) $(specs)
CFLAGS += -DSTM32F429_439xx
#CFLAGS += -DUSE_STDPERIPH_DRIVER
CFLAGS += -DARM_MATH_CM4F
CFLAGS += \
	-I$(CMSIS_PATH)/Core/Include \
	-I$(CHIPSET_PATH)/Include \
	-I$(CMSIS_DSP_PATH)/Include \
	-I$(CMSIS_DSP_PATH)/PrivateInclude \
	-I$(FREERTOS_PATH)/include \
	-I$(FREERTOS_PATH)/portable/GCC/ARM_CM4F

ifeq ($(USE_FREERTOS),true)
CFLAGS += -D_USE_FREERTOS
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

# ARM DSP and math
#LDFLAGS += -L$(THIRDPARTY_PATH)/Lib

# LINKER DESCIPRTOR
LDFLAGS += -T$(linker_script)

.PHONY : all

objs += $(startup_obj) $(system_obj)

ifeq ($(USE_FREERTOS),true)
objs += $(freertos_obj)
endif

objs += $(obj) $(libs_obj) #$(arm_dsp_obj)

all: dump_info check_obj_path $(APP_NAME).elf $(APP_NAME).hex
	@echo done!

clean:
	rm ./obj/* -rf
	rm ./$(APP_NAME).elf
	rm ./$(APP_NAME).hex
	rm ./$(APP_NAME).map

dump_info:
	@echo "----------------------------"
	@echo "---- ARM Cortex-M4F SDK ----"
	@echo "----     STM32F429ZI    ----"
	@echo "----------------------------"

path := $(dir $(objs))
check_obj_path:
	@mkdir -p $(path)

check_objs:
	@echo $(objs)

# ELF
$(APP_NAME).elf : $(objs)
	@$(CC) $(objs) $(LDFLAGS) -o ./$@

# HEX
$(APP_NAME).hex : $(APP_NAME).elf
	$(TOOLCHAIN)-objcopy $< -Oihex $@

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

# FREERTOS .o rules
$(OBJ_PATH)/freertos/%.o : $(FREERTOS_PATH)/%.c
	@echo $(CC) $<
	@$(CC) $< $(CFLAGS) $@

# LIBS .o RULES
$(OBJ_PATH)/libs/%.o : $(LIB_PATH)/%.c
	@echo $(CC) $<
	@$(CC) $< $(CFLAGS) $@

# USER APPS .o RULES
$(OBJ_PATH)/%.o : $(SRC_PATH)/%.c
	@echo $(CC) $<
	@$(CC) $< $(CFLAGS) $@
