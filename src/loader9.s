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
	@ Og instruction is a5 ee ff eb 'bl #0x0201b664', we change it to 'bl #0x02240000'

	@jump to 0x02240000
	ldr r0, =#0xeb08810c
	ldr r1, =#0x0201fbc8
	str r0,[r1]


	@ The run nds function takes the filename as 2nd argument (r1)
	@ its pointer is then moved to r3, and later moved again to r2 to perform a function call.
	@ To preserve the value across this function call, we store it in r4, so that when our code
	@ is run, it is still available
	@ mov r3,r1 changed to r4,r1
	ldr r0, =#0xe1a04001
	ldr r1, =#0x0201fb90
	str r0,[r1]

	@ mov r2,r3 changed to r2,r4
	ldr r0, =#0xe1a02004
	ldr r1, =#0x0201fba0
	str r0,[r1]
	

	adrl r0, miniboot_arm9_start
	adrl r1, miniboot_arm9_end
	ldr r2, =#0x02240000
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
miniboot_arm9_start:

add r1,r4,#256
ldr r2,=#0x02000000
1:
	ldr r3, [r4], # 4
	str r3, [r2], # 4
	cmp r4, r1
	blt 1b
ldr r0,=#0x027FF000
ldr r1,=#0x0D15EA5E
str r1,[r0,#0x0]
b 1f
.pool
1:
.incbin "arm9miniboot.bin"
miniboot_arm9_end:

.balign 4, 0xff
arm9_payload:
.incbin "arm9-c.bin"
