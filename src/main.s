
	.equ SCREEN_SIZE_X,1024
	.equ SCREEN_SIZE_Y,768
	
	.section .init
	.globl _start

_start:

	/* set up interrupt vector table */
	ldr pc, reset_handler	// branch to reset imidiatly
	// the rest will only be loaded in memory
	ldr pc, undefined_handler
	ldr pc, software_handler
	ldr pc, prefetch_abort_handler
	ldr pc, data_abort_handler
	ldr pc, unused_handler
	ldr pc, interrupt_handler
	ldr pc, fast_handler

reset_handler:		.word reset
undefined_handler:	.word halt
software_handler:	.word halt
prefetch_abort_handler:	.word halt
data_abort_handler:	.word halt
unused_handler:		.word halt
interrupt_handler:	.word irq
fast_handler:		.word halt

halt:	b halt

	// by loading constants we get the correct value in memory from 0x8000 onwards, now copy this to 0x0000
reset:

	/* remap IVT to start of instructions with coprocessor */
	mov r0,#0x8000
	MCR p15, 4, r0, c12, c0, 0

	mov sp,#0x8000		//stack starts at 0x8000
	
	b main

/*-------------------------------------- instructions  ---------------------------------------*/
.section .text
main:

	/* initialize frame buffer with */
	mov r0,#SCREEN_SIZE_X		// width
	mov r1,#SCREEN_SIZE_Y		// height
	mov r2,#16		// bit depth/color mode
	bl initFrameBuffer

	/* handle error */
	teq r0,#0
	bne noError$

	/* if error, flash ACT LED */
	mov r0,#47		// pin 47
	mov r1,#1		// output
	bl setGPIOport
	

error$:
	/* turn on ACT led */
	mov r0,#47
	mov r1,#1
	bl setGPIOpin

	/* wait */
	ldr r0,=1000000		//wait 1s
	bl wait
	
	/* turn off ACT led */
	mov r0,#47
	mov r1,#0
	bl setGPIOpin

	/* wait */
	ldr r0,=1000000
	bl wait
	
	b error$		// inf loop error

noError$:
	/* set GPU memory location */
	bl setGraphicsAddr

	/* set initial color */
	color .req r4
	ldr color,=0xE7E0
	mov r0,color
	bl setForeColor
	.unreq color

	bl init_kbd
	cpsie i			// enable interrupts

	
/* draw graphics */
render$:

	/* draw rectangle */
	ldr r0,=1023		// x1
	ldr r1,=767		// y1
	mov r2,#0		// x2
	mov r3,#0		// y2
	bl drawRectangleDiag

	x .req r4
	y .req r5
	// set initial coordinates
	mov x,#10
	mov y,#10

	p_nKeys .req r6
	p_keyBuffer .req r7
	ldr p_nKeys,=nKeysInBuffer
	ldr p_keyBuffer,=keyBuffer

drawCharInput$:

	ldr r0,=100000			// refresh rate
	bl wait

	nKeys .req r8
	/* check input */
	ldrb nKeys,[p_nKeys]
	cmp nKeys,#1
	blt drawCharInput$		// no pending keys
	
drawLoop$:
	sub nKeys,#1

	ldrb r0,[p_keyBuffer,nKeys]
	mov r1,x
	mov r2,y
	bl drawChar

	/******* TEST ***********/
	mov r0,#'.'
	mov r1,x
	mov r2,y
	bl drawChar
	/***********************/


	cmp x,#SCREEN_SIZE_X-8
	addlt x,#10
	addge y,#10			// new line
	movge x,#10			// start of line
	cmp y,#SCREEN_SIZE_Y-8
	bge endLoop$

	teq nKeys,#0
	beq drawCharInput$
	

	b drawLoop$

	.unreq p_nKeys
	.unreq p_keyBuffer
	.unreq nKeys


endLoop$:	
	
	b endLoop$		// inf loop
