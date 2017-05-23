
	.section .init
	.globl _start

_start:

	/* set up interrupt vector table */
	// let bootloarder put branch instructions to the ISR address constants at the start of instruction memory (0x8000)
	ldr pc, reset_handler	// branch to reset imidiatly
	// the rest will never be executed
	ldr pc, undefined_handler
	ldr pc, software_handler
	ldr pc, prefetch_abort_handler
	ldr pc, data_abort_handler
	ldr pc, unused_handler
	ldr pc, interrupt_handler
	ldr pc, fast_handler

reset_handler:	.word reset
undefined_handler:	.word halt
software_handler:	.word halt
prefetch_abort_handler:	.word halt
data_abort_handler:	.word halt
unused_handler:	.word halt
interrupt_handler:	.word irq
fast_handler:	.word halt

halt:	b halt

	// by loading constants we get the correct value in memory from 0x8000 onwards, now copy this to 0x0000
reset:
	mov r0,#0x8000
	mov r1,#0x0000

	ldmia r0!,{r2-r9}	// load r2-r9 with words from address in r0 and on, update r0 to incremented after (!)
	stmia r1!,{r2-r9}	// store r2-r9 in address r1 and on, update r1
	// ivt table is now filled with pointers to the constants, put the constants right after which points to the ISRs
	ldmia r0!,{r2-r9}	
	stmia r1!,{r2-r9}
	
	
	b main

/*-------------------------------------- instructions  ---------------------------------------*/
.section .text
main:
	
	mov sp,#0x8000		//stack starts at 0x8000

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

/* draw graphics */
render$:

	/*
	// draw rectangle based on upper corner, width and height
	rwidth .req r0
	rheight .req r1
	rx .req r2
	ry .req r3

	ldr rwidth,=1023
	ldr rheight,=767
	mov rx,#0
	mov ry,#0
	bl drawRectangle

	.unreq rwidth
	.unreq rheight
	.unreq rx
	.unreq ry*/

	/* draw a rectangular frame, passing diagonal coordinates */
	// upper corner to lower
	//mov r0,#0		// x1
	//mov r1,#0		// y1
	//ldr r2,=1023		// x2
	//ldr r3,=767		// y2
	// lower corner to upper, works both ways
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

	/* make a formated string */
	ldr r0,=format
	mov r1,#formatEnd-format // length of format
	ldr r2,=formatEnd	// start of string
	mov r3,#65		// set 5 args to 'A'
	push {r3}
	push {r3}
	push {r3}
	push {r3}
	bl formatString
	add sp,#4*4		// overwrite 4 args on the stack

	/* draw the formated string */
	mov r1,r0		// pass string length (ret from formatString)
	ldr r0,=formatEnd
	mov r2,#50
	mov r3,#50
	bl drawString
	


endLoop$:	
	
	b endLoop$		// inf loop

	
.section .data

format:
	.ascii "Converting %d:\n\t0b%b=0x%x=0%o='%c'"
formatEnd:	
	
	
