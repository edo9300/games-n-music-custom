# SPDX-License-Identifier: CC0-1.0
#
# SPDX-FileContributor: Adrian "asie" Siekierka, 2024

export WONDERFUL_TOOLCHAIN ?= /opt/wonderful
export BLOCKSDS ?= /opt/blocksds/core

# Tools
# -----

OBJCOPY	:= $(WONDERFUL_TOOLCHAIN)/toolchain/gcc-arm-none-eabi/bin/arm-none-eabi-objcopy
AS		:= $(WONDERFUL_TOOLCHAIN)/toolchain/gcc-arm-none-eabi/bin/arm-none-eabi-as
NPACK	:= $(WONDERFUL_TOOLCHAIN)/bin/wf-nnpack-lzss
CP		:= cp
MV		:= mv
MAKE	:= make
MKDIR	:= mkdir
DD		:= dd
CAT		:= cat
RM		:= rm -rf

TARGET := GameNMusic2

# Verbose flag
# ------------

ifeq ($(V),1)
_V		:=
else
_V		:= @
endif

# Build rules
# -----------

.PHONY: all clean sd_patches dldi_boot

all: $(TARGET)-enc.nds
	
clean:
	@echo "  CLEAN"
	$(_V)$(RM) build $(TARGET).nds $(TARGET)-enc.nds gnm-backup.bin
	$(_V)$(MAKE) -C sd_patches clean
	$(_V)$(MAKE) -C dldi_boot clean

$(TARGET).nds: build/arm9.bin build/arm7.bin
	@echo "  BUILDING"
	$(_V)$(BLOCKSDS)/tools/ndstool/ndstool -c $@ \
		-7 build/arm7.bin -9 build/arm9.bin \
		-t data/banner.bin -h data/header.bin \
		-r9 0x02100000 -e9 0x02100800 \
		-r7 0x02380000 -e7 0x02380000

$(TARGET)-enc.nds: $(TARGET).nds
	@echo "  ENCRYPTING"
	$(_V)$(CP) $(TARGET).nds build/$@
	$(_V)$(DD) if=data/secure-area.bin of=build/$@ seek=16 status=none
	$(_V)$(DD) if=$(TARGET).nds of=build/$@ skip=36 seek=36 status=none
	$(_V)$(MV) build/$@ $@
	$(_V)$(BLOCKSDS)/tools/ndstool/ndstool -fh $@
	$(_V)$(CP) $@ gnm-backup.bin

build/arm9-c.bin: data/arm9.bin
	@$(MKDIR) -p build
	$(_V)$(NPACK) -ewo data/arm9.bin build/arm9-c.bin

build/arm9.bin: sd_patches dldi_boot build/arm9-c.bin
	@$(MKDIR) -p build
	$(_V)$(AS) -I src -I build -I sd_patches/build -I dldi_boot/build src/loader9.s -o build/loader9.out
	$(_V)$(OBJCOPY) -O binary build/loader9.out build/loader9.frm
	$(_V)$(CAT) data/bare-entrypoint.bin build/loader9.frm > build/arm9.bin

build/arm7.bin: data/arm7.bin
	@$(MKDIR) -p build
	$(_V)$(AS) -I data -I sd_patches/build src/loader7.s -o build/loader7.out
	$(_V)$(OBJCOPY) -O binary build/loader7.out build/arm7.bin

sd_patches:
	$(_V)$(MAKE) -C sd_patches

dldi_boot:
	$(_V)$(MAKE) -C dldi_boot