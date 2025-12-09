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
	mov r0, #0
	mrc p15, 0, r0, c7, c6, 0
	mov r0, #0
	mrc p15, 0, r0, c7, c5, 0
	bx r4
.pool

.balign 4, 0xff
arm9_payload:
.incbin "arm9.bin"
