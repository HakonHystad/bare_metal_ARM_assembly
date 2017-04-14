/* setup buffer for GPU communication */

///////////////////////////////////////////////////////////////////////////////////////
// declarations
//////////////////////////////////////////////////////////////////////////////////////
.section .text
	.globl initFrameBuffer

///////////////////////////////////////////////////////////////////////////////////////
// definitions
//////////////////////////////////////////////////////////////////////////////////////

/*-------------------------------------- initFrameBuffer  ---------------------------------------*/
/* make the frame buffer, r0=width, r1=height, r2=bitDepth */	
initFrameBuffer:
	width .req r0
	height .req r1
	bitDepth .req r2

	/* validate input */
	cmp width,#4096
	cmpls height,#4096
	cmpls bitDepth,#32
	result .req r0
	movhi result,#0		// return 0 for failure
	movhi pc,lr

	/* fill in frame buffer */
	fbInfoAddr .req r4
	push {r4,lr}
	ldr fbInfoAddr,=frameBufferInfo // ptr to generic frame buffer
	str width,[fbInfoAddr,#0]
	str height,[fbInfoAddr,#4]
	str width,[fbInfoAddr,#8]
	str height,[fbInfoAddr,#12]
	str bitDepth,[fbInfoAddr,#20]
	.unreq width
	.unreq height
	.unreq bitDepth

	/* ask GPU for place to store frame buffer */
	mov r0,fbInfoAddr
	add r0,#0xC0000000	// flush cache?
	mov r1,#1		// mailbox 1
	bl mailboxWrite

	/* read respons */
	mov r0,#1		// of mailbox 1
	bl mailboxRead
	teq result,#0
	movne result,#0		// 0 for failure
	popne {r4,pc}

	mov result,fbInfoAddr	// all ok: return frame buffer ptr we can write to
	pop {r4,pc}
	.unreq result
	.unreq fbInfoAddr
	

	
///////////////////////////////////////////////////////////////////////////////////////
// data
//////////////////////////////////////////////////////////////////////////////////////

.section .data
	.align 4		// (pad with 16 zeros) keep 4 lowest bits of the placing address to 0
	.globl frameBufferInfo
	
frameBufferInfo:
.int 1024 /* #0 Physical Width */
.int 768 /* #4 Physical Height */
.int 1024 /* #8 Virtual Width */
.int 768 /* #12 Virtual Height */
.int 0 /* #16 GPU - Pitch */
.int 16 /* #20 Bit Depth */
.int 0 /* #24 X */
.int 0 /* #28 Y */
.int 0 /* #32 GPU - Pointer */
.int 0 /* #36 GPU - Size */
