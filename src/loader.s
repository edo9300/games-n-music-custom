.arch   armv5te
.cpu    arm946e-s
.align 4
.arm

entrypoint:
	adrl r0, arm9_payload
	ldr r1, =#0x02000800
	movs r4, r1
	swi 0x110000
	bx r4
.pool

.balign 4, 0xff
arm9_payload:
.incbin "arm9.bin"
