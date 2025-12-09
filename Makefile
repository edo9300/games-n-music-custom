# SPDX-License-Identifier: CC0-1.0
#
# SPDX-FileContributor: Adrian "asie" Siekierka, 2024

export WONDERFUL_TOOLCHAIN ?= /opt/wonderful
export BLOCKSDS ?= /opt/blocksds/core

# Tools
# -----

OBJCOPY	:= $(WONDERFUL_TOOLCHAIN)/toolchain/gcc-arm-none-eabi/bin/arm-none-eabi-objcopy
AS		:= $(WONDERFUL_TOOLCHAIN)/toolchain/gcc-arm-none-eabi/bin/arm-none-eabi-as
CP		:= cp
MAKE	:= make
MKDIR	:= mkdir
DD		:= dd
CAT		:= cat
RM		:= rm -rf

TARGET := GameNMusic2.nds

# Verbose flag
# ------------

ifeq ($(V),1)
_V		:=
else
_V		:= @
endif

# Build rules
# -----------

.PHONY: all clean miniboot stage1

all: $(TARGET)
	

clean:
	@echo "  CLEAN"
	$(_V)$(RM) build loader.frm $(TARGET)

$(TARGET): build/arm9.bin
	$(_V)$(BLOCKSDS)/tools/ndstool/ndstool -c $@ \
		-7 data/arm7.bin -9 build/arm9.bin \
		-t data/banner.bin -h data/header.bin \
		-r9 0x02100000 -e9 0x02100800

build/arm9.bin:
	@$(MKDIR) -p build
	$(_V)$(AS) -I src src/loader.s -o build/loader.out
	$(_V)$(OBJCOPY) -O binary build/loader.out build/loader.frm
	$(_V)$(CAT) data/bare-entrypoint.bin build/loader.frm > build/arm9.bin
	
	
