/* interface for a interrupt driven ps2 keyboard */

	.include "mmap.s"


///////////////////////////////////////////////////////////////////////////////////////
// literals 
//////////////////////////////////////////////////////////////////////////////////////
.equ KBD_CLK_PIN, 14	// pins below 10 or above 19 must also change FSEL register 
.equ KBD_DATA_PIN, 15
	
///////////////////////////////////////////////////////////////////////////////////////
// declarations 
//////////////////////////////////////////////////////////////////////////////////////

.section .text
	.globl init_kbd

///////////////////////////////////////////////////////////////////////////////////////
// definitions 
//////////////////////////////////////////////////////////////////////////////////////


/*-------------------------------------- init_kbd  ---------------------------------------*/
init_kbd:

	push {r4,lr}

	baseAddr .req r4
	ldr baseAddr,=GPIOaddr


	/* set pull-ups on pins, p.101 BCM refrence manual */

	// enable/signal pull-up
	mov r0, #0b10		// enable pull-up
	str r0,[baseAddr,#GPPUD]

	mov r0,#15		// waiting 1us is much more than the 150 cycles needed
	bl wait


	// clock in pull-up on pins
	mov r0, #1<<KBD_CLK_PIN
	orr r0, #1<<KBD_DATA_PIN
	str r0,[baseAddr,#GPPUDCLK0]

	mov r0,#15
	bl wait			// wait another >150 cycles

	// remove signal and clock
	mov r0,#0
	str r0,[baseAddr,#GPPUD]
	str r0,[baseAddr,#GPPUDCLK0]

	
	
	/* set pins as input */ 
	ldr r0,[baseAddr,#GPSEL1]
	bic r0, #0b111111<<( 3*(KBD_CLK_PIN - 10) )	// AND NOT (assuming clock and data is neighboring pins)
	str r0,[baseAddr,#GPSEL1]
	

	
	/* enable falling edge detection on clock pin */
	mov r0,#1<<KBD_CLK_PIN
	str r0,[baseAddr,#GPFEN0]	

	/* enable interrupts on all header pins (gpio_int[0] = 49) */
	ldr r1,=IRQaddr
	mov r0,#1<<(49-32)
	str r0,[r1,#IRQ_EN2]

	pop {r4,pc}

	.unreq baseAddr
