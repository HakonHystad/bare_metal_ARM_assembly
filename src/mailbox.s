/* communication via mailbox */

	.include "mmap.s"
	//.equ mailboxAddr, 0x3F00B880	// mailbox base address

///////////////////////////////////////////////////////////////////////////////////////
// Macros 
//////////////////////////////////////////////////////////////////////////////////////
	.macro loadMailboxAddr
	ldr r0,=mailboxAddr
	.endm

///////////////////////////////////////////////////////////////////////////////////////
// declarations
//////////////////////////////////////////////////////////////////////////////////////

	.globl mailboxRead	// read GPU message
	.globl mailboxWrite	// send a framebuffer

///////////////////////////////////////////////////////////////////////////////////////
// definitions
//////////////////////////////////////////////////////////////////////////////////////
	
/*-------------------------------------- mailboxWrite  ---------------------------------------*/
/* takes input in r0 and addr in r1, writes to GPU memory */
mailboxWrite:
	/* validate input */
	tst r0,#0b1111		// (test and) low 4 bits are for address
	movne pc,lr
	cmp r1,#15		// mailbox can't be larger than 4 bits
	movhi pc,lr

	box .req r1
	msg .req r2
	mov msg,r0

	loadMailboxAddr
	addr .req r0
	
/* wait for the ready signal from GPU */
waitForWrite$:
	writeStatus .req r3
	ldr writeStatus,[addr,#0x18] // GPU status field
	tst writeStatus,#0x8000000 // top bit set = signal ready
	.unreq writeStatus
	bne waitForWrite$

	/* make packet */
	add msg,box
	.unreq box

	/* send packet */
	str msg,[addr,#0x20]	// send/store in write field that GPU checks
	.unreq msg
	.unreq addr

	mov pc,lr

/*-------------------------------------- mailboxRead  ---------------------------------------*/
/* mailbox to read from in r0, output to r0 */
mailboxRead:
	/* validate input */
	cmp r0,#15		// 4 bit mailbox
	movhi pc,lr

	box .req r1
	mov box,r0
	loadMailboxAddr
	addr .req r0

/* wait for the correct box to post */
waitForBox$:	
/* wait for message */
waitForRead$:
	readStatus .req r2
	ldr readStatus,[addr,#0x18] // GPU status field
	tst readStatus,#0x40000000 // 30th bit cleared = read ok
	.unreq readStatus
	bne waitForRead$

	/* read */
	msg .req r2
	ldr msg,[addr,#0]

	/* check box nr */
	recvBox .req r3
	and recvBox,msg,#0b1111	// extract 4 first bits (mailbox)
	teq recvBox,box
	.unreq recvBox
	bne waitForBox$

	.unreq box
	.unreq addr

	and r0,msg,#0xFFFFFFF0	// upper 28 bits are the message
	.unreq msg

	mov pc,lr
	
