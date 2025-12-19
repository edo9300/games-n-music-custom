/* SPDX-License-Identifier: Zlib */
/* Copyright (c) 2024 Adrian "asie" Siekierka */

OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(patch_and_jump)

MEMORY {
	RAM  : ORIGIN = 0x02080000, LENGTH = 0x021007ff-0x02080000
	DLDI  : ORIGIN = 0x02088000, LENGTH = 0x8000
}

SECTIONS {
	/* === Constants === */
	PROVIDE(__dldi_size = 32768);
	__dldi_log2_size = LOG2CEIL(__dldi_size + 1) - 1;

	.text : ALIGN(4) {
		*(.text.patch_and_jump);
        *(.text*);
	} >RAM

	.dldi : ALIGN(512) {
		__dldi_start = .;
		*(.dldi .dldi.*)
		. = __dldi_start + __dldi_size;
		. = ALIGN(512);
	} >DLDI
}
