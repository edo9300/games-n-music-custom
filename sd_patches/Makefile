# SPDX-License-Identifier: CC0-1.0
#
# SPDX-FileContributor: Adrian "asie" Siekierka, 2024

export WONDERFUL_TOOLCHAIN ?= /opt/wonderful
export BLOCKSDS ?= /opt/blocksds/core

# Tools
# -----

GBATOOL	:= $(WONDERFUL_TOOLCHAIN)/bin/wf-gbatool
OBJCOPY	:= $(WONDERFUL_TOOLCHAIN)/toolchain/gcc-arm-none-eabi/bin/arm-none-eabi-objcopy
AS		:= $(WONDERFUL_TOOLCHAIN)/toolchain/gcc-arm-none-eabi/bin/arm-none-eabi-as
CC		:= $(WONDERFUL_TOOLCHAIN)/toolchain/gcc-arm-none-eabi/bin/arm-none-eabi-gcc
CP		:= cp
MAKE	:= make
MKDIR	:= mkdir
DD		:= dd
CAT		:= cat
RM		:= rm -rf

# Verbose flag
# ------------

ifeq ($(V),1)
_V		:=
else
_V		:= @
endif

# Build rules
# -----------

.PHONY: all clean sdio

all: sdio

clean:
	rm -r build

sdio:
	@$(MKDIR) -p build
	$(_V)$(CC) -std=gnu23 -nostartfiles -nostdlib -DSTARTUP -T src/startup.ld -ffreestanding -ffunction-sections -I$(BLOCKSDS)/libs/libnds/include -mthumb -mthumb-interwork -fpic -fPIC -O3 src/gmtf.c -o build/startup.o
	$(_V)$(OBJCOPY) -O binary -j .text build/startup.o build/startup.bin
	$(_V)$(CC) -std=gnu23 -nostartfiles -nostdlib -DSDREAD -T src/sdRead.ld -ffreestanding -ffunction-sections -I$(BLOCKSDS)/libs/libnds/include -mthumb -mthumb-interwork -fpic -fPIC -O3 src/gmtf.c -o build/sdRead.o
	$(_V)$(OBJCOPY) -O binary -j .text -j .data build/sdRead.o build/sdRead.bin
	$(_V)$(CC) -std=gnu23 -nostartfiles -nostdlib -DSDWRITE -T src/sdWrite.ld -ffreestanding -ffunction-sections -I$(BLOCKSDS)/libs/libnds/include -mthumb -mthumb-interwork -fpic -fPIC -O3 src/gmtf.c -o build/sdWrite.o
	$(_V)$(OBJCOPY) -O binary -j .text build/sdWrite.o build/sdWrite.bin
