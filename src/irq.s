/* handle interrupt requests and branch to the apropriate ISRs */
	.include "mmap.s"

	.equ KBD_CLK_PIN, 14
		
///////////////////////////////////////////////////////////////////////////////////////
// declarations 
//////////////////////////////////////////////////////////////////////////////////////
.section .text
	.globl irq	// global interrupt handler
	//.globl ISR_kbd	// ps2 keyboard clock interrupt

///////////////////////////////////////////////////////////////////////////////////////
// definitions
//////////////////////////////////////////////////////////////////////////////////////


	
/*-------------------------------------- global interrupt handler  ---------------------------------------*/
irq:
	push {r0-r3,lr}		// save state

	// check if interrupt is pending in 1 or 2
	ldr r1, =IRQaddr

	/***** only care about pins on the header for now *********
	ldr r0, [r1]
	tst r0,#1<<8		// test pending 1
	bne PDG1$

	tst r0,#1<<9		// test pending 2
	bne PDG2$

	b return$

	// p.109 BCM2835 refrence manual
PDG1$:
	ldr r0,[r1,#IRQ_PDG1]
	// different ISRs for source 31:0 goes here 
	
	b return$
	*/

PDG2$:
	ldr r0,[r1,#IRQ_PDG2]
	/* different ISRs for source 63:32 goes here */
	// gpio_int[0]..gpio_int[3] <=> GPU_interrupt 49..52, 49 covers all pins of the header
	tst r0,#1<<(49-32)	// check gpio_int[0], all header pins
	blne ISR_kbd
	
return$:
	pop {r0-r3,lr}
	eret			// exception return in HYP mode

/*-------------------------------------- keyboard clock interrupt handler  ---------------------------------------*/
ISR_kbd:
	// clear event detect bit for GPIO pin 2 (kbd clock)

	push {r0-r4,lr}

	// clear interrupt (by writing 1 to event detect reg)

	ldr r0, =GPIOaddr
	mov r1, #1<<KBD_CLK_PIN
	str r1, [r0,#GPEDS0]

	/*-------------------------------------- ISR  ---------------------------------------*/


	ldr r0,=irq_count
	ldr r1,[r0]
	add r1,#1
	str r1,[r0]


	/*-------------------------------------- ISR  ---------------------------------------*/

	

	pop {r0-r4,pc}

.section .data
	
	.globl irq_count
irq_count:	.int 0
	
