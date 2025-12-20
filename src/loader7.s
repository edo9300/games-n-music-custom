.cpu    arm7tdmi
.align 4
.syntax  unified
.arm

entrypoint:
	adrl r0, arm7_payload_start
	adrl r1, arm7_payload_end
	ldr r2, =#0x037F8000
	movs r4, r2
	bl copy

	adrl r0, arm7_miniboot_payload_start
	adrl r1, arm7_miniboot_payload_end
	ldr r2, =#0x037F7000
	bl copy	

	@ bl 0x03806000
	@ ldr r1, =#0xEB003349
	
	@ bl 0x037F7000
	ldr r1, =#0xEBFFF749
	ldr r0, =#0x037f92d4
	str r1, [r0]
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
arm7_payload_start:
.incbin "arm7.bin"
arm7_payload_end:


.balign 4, 0xff
arm7_miniboot_payload_start:
ldr r0,=#0x027FF000
mov r1,0
str r1,[r0,#0x0]
.incbin "arm7miniboot.bin"
.pool
arm7_miniboot_payload_end:
