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
	$(_V)$(CC) -std=gnu23 -nostartfiles -nostdlib -DSTARTUP -T src/dldi.ld -ffreestanding -ffunction-sections -I$(BLOCKSDS)/libs/libnds/include -marm -fpic -fPIC -O3 src/dldi_patch.c src/dldi_stub.s src/memcpy.s src/memset.s -o build/dldi.o
	$(_V)$(OBJCOPY) -O binary -j .text build/dldi.o build/dldi_patch.bin
	$(_V)$(OBJCOPY) -O binary -j .dldi build/dldi.o build/dldi.bin
