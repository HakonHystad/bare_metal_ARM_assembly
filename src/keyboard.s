/* interface for a interrupt driven ps2 keyboard */

	.include "mmap.s"


///////////////////////////////////////////////////////////////////////////////////////
// literals 
//////////////////////////////////////////////////////////////////////////////////////
.equ KBD_CLK_PIN, 14	// pins below 10 or above 19 must also change FSEL register 
.equ KBD_DATA_PIN, 15

.equ KBD_TIMEOUT, 11000	//us, signals a packet timeout	
	
///////////////////////////////////////////////////////////////////////////////////////
// declarations 
//////////////////////////////////////////////////////////////////////////////////////

.section .text
	.globl init_kbd
	.globl ISR_kbd

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

/*-------------------------------------- ISR_kbd  ---------------------------------------*/
// fires when a falling edge interrupt is triggered on clock pin
ISR_kbd:
	push {lr}


	/* clear interrupt (by writing 1 to event detect reg) */
	gpioBase .req r0
	ldr gpioBase, =GPIOaddr
	mov r1, #1<<KBD_CLK_PIN
	str r1,[gpioBase,#GPEDS0]

	/* read level on data pin */
	data .req r3
	ldr data,[gpioBase,#GPLEV0]
	and data,#1<<KBD_DATA_PIN
	
	.unreq gpioBase

	

	/* check time since last SOF */
	time .req r0
	SOFaddr .req r1
	bl getTime
	ldr SOFaddr,=SOFtimer
	ldr r2,[SOFaddr]		// load timer
	.unreq SOFaddr
	sub r2,time,r2			// calc interval
	ldr r1,=KBD_TIMEOUT
	cmp r2,r1
	
	blt recvKey$			// if !timeout we're still receiving a keycode


	// if timeout reset everything for a new keycode
	ldr r1,=count
	mov r2,#0
	strb r2,[r1]			// rest count
	ldr r1,=key
	strb r2,[r1]			// reset key
	ldr r1,=SOFtimer
	str time,[r1]			// update SOF time
	pop {pc}

	.unreq time


/* build a keycode */
recvKey$:

	counterAddr .req r1
	counter .req r0
	
	/* add bit */
	ldr counterAddr,=count
	ldrb counter,[counterAddr]	// load bit placement

	
	// increment count while we have it loaded
	add r2,counter,#1
	strb r2,[counterAddr]
	.unreq counterAddr


	// check counter for action
	cmp counter,#7			// non-incremented counter
	popgt {pc}			// don't care beyond keycode (odd parity and EOF)

	// TODO: skip if data=0 

	// ready data and keycode
	keycodeAddr .req r1
	keycode .req r2
	ldr keycodeAddr,=key
	ldrb keycode,[keycodeAddr]
	lsr data,#KBD_DATA_PIN		// set data to lsb
	lsl data, counter		// shift data up to count
	orr keycode,data		// OR in bit

	teq counter,#7
	beq getChar$			// no need to store the last bit if keycode is complete (counter==7)
	
	// store bit
	strb keycode,[keycodeAddr]
	pop {pc}
	.unreq keycodeAddr
	.unreq counter
	.unreq data

/* if keycode is complete, take action */
getChar$:
	
	// keycode == r2

	//mov r0,r2
	//bl printNr

	/* is it a break code? */
	cmp keycode,#0xF0
	beq setBreakFlag$

	/* bounds check */
	cmp keycode,#0x7f
	popgt {pc}

	/* do lookup */
	char .req r0
	
	ldr r1,=kbdLUT
	ldrb char,[r1,keycode]
	.unreq keycode

	

	/* check for invalid char */
	teq char,#0
	popeq {pc}		// invalid character
	
	/* check break flag */
	ldr r1,=kbdFlags
	ldrb r2,[r1]
	tst r2,#1
	bne removeChar$		// previous character was a break code, rm this character from the buffer

	/* not an invalid char, no break code set. store it in keybuffer */

	/* only the last key has typematic repeat, check if this is it */
	lastKeyAddr .req r1
	ldr lastKeyAddr,=lastKey
	ldrb r2,[lastKeyAddr]
	teq r2,char
	popeq {pc}		// its a repeat, exit


	// get active keycount
	nKeysAddr .req r2
	nKeys .req r3
	ldr nKeysAddr,=nKeysInBuffer
	ldrb nKeys,[nKeysAddr]

	
	cmp nKeys,#KBD_BUFFER_SIZE-1
	popge {pc}		// buffer is full

	// update last key
	strb char,[lastKeyAddr]
	.unreq lastKeyAddr
	// store key
	ldr r1,=keyBuffer
	strb char,[r1,nKeys]	// store new key
	// update keycount
	add nKeys,#1
	strb nKeys,[nKeysAddr]	// increment

	pop {pc}

	
setBreakFlag$:	
	ldr r0,=kbdFlags
	mov r1,#1
	strb r1,[r0]
	pop {pc}

removeChar$:

	// reset break flag
	eor r2,#1			
	strb r2,[r1]
	/* get active keycount */
	ldr nKeysAddr,=nKeysInBuffer
	ldrb nKeys,[nKeysAddr]

	/* do action based on keycount */
	cmp nKeys,#1
	subeq nKeys,#1		// if just 1 key is pressed let it be overwritten
	streqb nKeys,[nKeysAddr]
	popeq {pc}
	poplt {pc}		// something is wrong a key should be pressed, exit

	.unreq nKeys
	.unreq nKeysAddr

	loopCount .req r2
	bufferAddr .req r1

	ldr bufferAddr,=keyBuffer
/* traverse keyBuffer and remove char */
rmLoop$:
	
	sub loopCount,#1
		
	ldrb r3,[bufferAddr,loopCount]
	teq r3,char
	beq rm$					// remove if we find a match in buffer
	
	teq loopCount,#0
	popeq {pc}				// exit loop in case char was not in buffer
	
	b rmLoop$


/* remove char from buffer and decrement keycount */ 
rm$:
	mov r3,#0				// this does not work, pressed keys need to be in the bottom of buffer
	strb r3,[bufferAddr,loopCount]		// null out

	.unreq loopCount
	.unreq bufferAddr
	
	
	nKeysAddr .req r1
	nKeys .req r2
	
	ldr nKeysAddr,=nKeysInBuffer
	ldrb nKeys,[nKeysAddr]
	sub nKeys,#1				// decrement nKeys
	strb nKeys,[nKeysAddr]

	.unreq nKeysAddr
	.unreq nKeys

	pop {pc}

.section .data
	.align 4

// ISR function data
SOFtimer:
	.long	0
count:	
	.byte	0
key:	
	.byte	0
lastKey:
	.byte	0

// KBD data
.globl keyBuffer	
keyBuffer:
	.byte	'A'	// TEST
	.byte	'B'	// TEST
	.byte	0
	.byte	0
	.byte	0
	.byte	0

.equ KBD_BUFFER_SIZE,6
	
.globl nKeysInBuffer
nKeysInBuffer:
	.byte	2	// TEST
kbdFlags:
	.byte	0


kbdLUT:	
	//       0     1     2     3     4     5     6     7     8     9     a     b     c     d     e     f
	.byte 0000, 000,  0000, 0000, 0000, 0000, 0000, 0000,  000, 0000, 0000, 0000, 0000, '\t',  '`',  000	// 0
	.byte 0000, 0000, 0000,  000, 0000,  'Q',  '1',  000,  000,  000,  'Z',  'S',  'A',  'W',  '2', 0000	// 1
	.byte 0000,  'C',  'X',  'D',  'E',  '4',  '3', 0000,  000,  ' ',  'V',  'F',  'T',  'R',  '5', 0000	// 2
	.byte 0000,  'N',  'B',  'H',  'G',  'Y',  '6',  000,  000,  000,  'M',  'J',  'U',  '7',  '8',  000	// 3
	.byte 0000, 0000,  'K',  'I',  'O',  '0',  '9',  000,  000,  '.',  '/',  'l',  ';',  'p',  '-',  000	// 4
	.byte 0000,  000, 0000,  000,  '[',  '=',  000,  000, 0xa0, 0000, '\n',  ']',  000, 0000,  000,  000	// 5
	.byte 0000,  '<',  000,  000,  000,  000, '\r',  000,  000, 0000,  000, 0000, 0x06,  000,  000,  000	// 6
	.byte 0000, 0000, 0000,  '5', 0000, 0000, 0000, 0000, 0000,  '+', 0000,  '-',  '*', 0000, 0000,  000    // 7
	.byte 0000,  000,  000, 0000	
