/* set port functions and pins for the GPIO pins */

	.include "mmap.s"

///////////////////////////////////////////////////////////////////////////////////////
// Macros 
//////////////////////////////////////////////////////////////////////////////////////
	.macro loadGPIOaddr
	ldr r0,=GPIOaddr
	.endm

///////////////////////////////////////////////////////////////////////////////////////
// declarations
//////////////////////////////////////////////////////////////////////////////////////


// global to make accessible to other files
	.globl setGPIOport	// configure pin as input, output or alt.
	.globl setGPIOpin	// enable/disable pin
	

///////////////////////////////////////////////////////////////////////////////////////
// definitions
//////////////////////////////////////////////////////////////////////////////////////

	
/*-------------------------------------- setGPIOport  ---------------------------------------*/
/* configure the GPIO pins, r0 has pin nr, r1 has function */
setGPIOport:

	/* check input */
	cmp r0,#53		// pins 0-53
	cmpls r1,#7		// (cmp less or same 53)
	movhi pc,lr		// (mov if higher) return

	/* get address for pin */
	push {lr}		// store the inital return addr on stack
	mov r4,r0		// store pin nr
	loadGPIOaddr

	/* find function block */
	/* 10 pins per block */
portLoop$:	
	cmp r4,#9		// subtraction is faster than division
	subhi r4,#10		
	addhi r0,#4		// add 4 bytes to address for each block
	bhi portLoop$

	/* find function bit */
	/* 3 function bits per pin */
	add r4, r4,lsl #1	// r4 = r4*3 = r4*2 + r4, multiplication is slow: left shift before adding
	lsl r1,r4		// shift given function to the right pin

	/* set the function */
	ldr r2,[r0]		// load current pin config from memory
	orr r1,r2		// add the new config
	str r1,[r0]

	/* return */
	pop {pc}		// pop return address into program counter


	
/*-------------------------------------- setGPIOpin  ---------------------------------------*/
/* enable/disable pin, r0 has pin nr, r1 is 0 for off and 1 for on */
setGPIOpin:
	pinNum .req r0
	pinState .req r1	// register alias for readability

	/* test input */
	cmp pinNum,#53
	movhi pc,lr		// return if invalid pin nr

	/* get control addr */
	mov r2,pinNum
	.unreq pinNum
	pinNum .req r2		// change register for pinNum
	push {lr}
	loadGPIOaddr
	gpioAddr .req r0

	/* find pin regsiter offset */
	pinReg .req r3
	/* 2 registers, 0 for pin  0-31 and 1 for the remaning 22 */
	lsr pinReg, pinNum,#5	// (rightshift) divide pin by 32 to get 1 or 0
	lsl pinReg, #2		// make the memory offset: either 4 or 0 (a reg is 4 bytes)
	add gpioAddr,pinReg
	.unreq pinReg

	/* find bit corresponding to the pin in the register */
	/* bit 0-31 <=> pin 0-31 reg 0, bit 0-22 <=> pin 32-53 reg 1 */
	/* => corresponding bit will be the remainder of div by 32 */
	and pinNum,#31		// remainder
	pinBit .req r3
	mov pinBit,#1
	lsl pinBit,pinNum
	.unreq pinNum

	/* turn pin on or off */
	teq pinState,#0		// (test equal)
	.unreq pinState
	streq pinBit,[gpioAddr,#0x28] //(store if equal) GPCLR 0 or 1 
	strne pinBit,[gpioAddr,#0x1C] //(store if not equal) GPSET 0 or 1
	.unreq pinBit
	.unreq gpioAddr

	/* return */
	pop {pc}

