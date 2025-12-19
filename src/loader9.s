.arch   armv5te
.cpu    arm946e-s
.align 4
.syntax  unified
.arm

entrypoint:
	ldr r3, =#0x777F
	ldr r2, =#0x04000200
	ldr r1, [r2, #4]
	and r3,r1,r3
	strh r3,[r2, #4]
	ldrh r3,[r2, #4]
	orr r3,r3,#0x8000
	strh r3,[r2,#4]
	adrl r0, arm9_payload
	ldr r1, =#0x02000800
	movs r4, r1
	swi 0x110000

	adrl r0, sd_write_start
	adrl r1, sd_write_end
	ldr r2, =#0x20181cc
	bl copy

	adrl r0, sd_read_start
	adrl r1, sd_read_end
	ldr r2, =#0x20186ec
	bl copy

	adrl r0, sd_init_start
	adrl r1, sd_init_end
	ldr r2, =#0x2018b18
	bl copy

	@ This patches out the partition check to allow loading FAT partitions with a type
	@ of 0x0C (FAT32 with LBA) and 0x0E (FAT16B with LBA), removing the checks for partition type
	@ 0x5E (undocumented) and 0x5C (Supposedly "Priam EDisk Partitioned Volume")
	ldr r0, =#0xe353000c @ cmp        r3,#0x0C
	ldr r1, =#0x1353000e @ cmpne      r3,#0x0E
	ldr r2, =#0x020196f8
	str r0,[r2]
	str r1,[r2, #4]

	@ This makes the original boot nds code call our custom function so that we can dldi patch the loaded binary
	@ Og instruction is 06 00 00 eb 'bl #0x0201fcb8', we change it to 'bl #0x02180000'
	
	@correct
	@jump to 0x02080000
	@ ldr r0, =#0xeb0180d8
	
	@ ldr r0, =#0xebffe14b
	
	@jump to 0x23fe000
	@ ldr r0, =#0xeb0f78d8

	@jump to 0x01004600
	@ ldr r0, =#0xebbf9258

	@jump to 0x02180000
	ldr r0, =#0xeb0580d8

	
	ldr r1, =#0x0201fc98
	str r0,[r1]

	adrl r0, dldi_patch_start
	adrl r1, dldi_patch_end
	ldr r2, =#0x2180000
	bl copy

	adrl r0, dldi_start
	add r1, r0, #0x8000
	ldr r2, =#0x2188000
	bl copy
	
	mov r0, #0
	mrc p15, 0, r0, c7, c6, 0
	mov r0, #0
	mrc p15, 0, r0, c7, c5, 0

	bx r4

copy:
1:
	ldr r3, [r0], # 4
	str r3, [r2], # 4
	cmp r0, r1
	blt 1b
	bx lr
.pool

.balign 4, 0xff
arm9_payload:
.incbin "arm9-c.bin"

.balign 4, 0xff
sd_write_start:
.incbin "sdWrite.bin"
sd_write_end:

.balign 4, 0xff
sd_read_start:
.incbin "sdRead.bin"
sd_read_end:

.balign 4, 0xff
sd_init_start:
.incbin "startup.bin"
sd_init_end:

.balign 4, 0xff
dldi_patch_start:
.incbin "dldi_patch.bin"
dldi_patch_end:

.balign 4, 0xff
dldi_start:
.incbin "dldi.bin"
dldi_end:
