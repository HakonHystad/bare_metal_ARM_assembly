/* handle interrupt requests and branch to the apropriate ISRs */
	.include "mmap.s"
	
	
.globl irq
irq:
	push {r0,r1,lr}		// save state

	// check if interrupt is pending in 1 or 2
	ldr r1, =IRQaddr

	/* only care about pins on the header for now
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
	//blne kbd_irq
	
return$:
	pop {r0,r1,pc}
