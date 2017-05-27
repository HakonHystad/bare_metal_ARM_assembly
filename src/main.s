
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
	mov r0,#1024		// width
	mov r1,#768		// height
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

	/* draw a circle */
	mov r0,#512		// x_c
	ldr r1,=384		// y_c
	ldr r2,=383		// radius
	bl drawCircle


drawIrqCount$:	
	
	ldr r0,=irqCountFormat
	mov r1,#irqCountFormatEnd-irqCountFormat
	ldr r2,=irqCountFormatEnd
	ldr r3,=irq_count
	ldr r3,[r3]
	bl formatString

	mov r1,r0
	ldr r0,=irqCountFormatEnd
	mov r2,#50
	mov r3,#50
	bl drawString

	b drawIrqCount$


endLoop$:	
	
	b endLoop$		// inf loop

	
.section .data

irqCountFormat:
	.ascii "Interrupt count: %d"
irqCountFormatEnd:
	
