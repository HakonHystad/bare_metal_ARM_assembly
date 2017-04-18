	/* for string manipulation */

	///////////////////////////////////////////////////////////////////////////////////////
	// declarations
	//////////////////////////////////////////////////////////////////////////////////////
	.section .text
	
	.globl signedString	// numToString signed
	.globl unsignedString	// numToString unsigned
	.globl formatString	// format a given string with arguments

	///////////////////////////////////////////////////////////////////////////////////////
	// definitions
	//////////////////////////////////////////////////////////////////////////////////////

/*-------------------------------------- singedString  ---------------------------------------*/
	/* signed number wrapper: ifnegative add a - sign */
	/* r0=the number, r1=storage dest (0 if no store), r2=base. RET length of string in r0 */
signedString:

	val .req r0
	dest .req r1
	base .req r2

	/* check sign */
	cmp val,#0
	bge unsignedString		// pass on if >=0, let it handle return

	teq dest,#0			// no-store flag
	
	/* add sign */
	movne r3, #'-'			
	strneb r3,[dest]
	addne dest,#1

	/* toString */
	rsb val,#0			// 0-val => change sign
	push {lr}			// handle return
	bl unsignedString
	teq r0,#0			// no string
	addne r0,#1			// length + 1 (sign)
	pop {pc}

	.unreq val
	.unreq dest
	.unreq base
	
/*-------------------------------------- unsignedString  ---------------------------------------*/
	/* numTostring; r0=the number, r1=storage dest (0 if no store), r2=base, RET length of string in r0 */
unsignedString:

	push {r4,r5,r6,lr}

	val .req r0
	dest .req r4
	base .req r5
	len .req r6

	mov dest,r1
	mov base,r2
	mov len,#0

	
	/* validate input */
	//cmp base,#36			// limit to base 36
	//movgt r0,#0
	//popgt {r4,r5,r6,pc}

// get each char through long division with base
charLoop$:
	mov r1,base
	bl divideU32

	cmp r1,#9			// check remainder
	addls r1,#'0'			// add ascii base for numbers
	addhi r1,#'a'-10		// if remainder is greater than decimal add base for letters

	teq dest,#0			// check for "null flag"=no store
	strneb r1,[dest,len]
	add len,#1

	teq val,#0			// finished divising number
	bne charLoop$

	/////////////// end loop

	/* if we stored a string, reverse it to get correct output */
	teq dest,#0
	movne r0, dest
	movne r1, len
	blne reverseString

	/* return length */
	mov r0,len
	pop {r4,r5,r6,pc}

	.unreq val
	.unreq dest
	.unreq base
	.unreq len

/*-------------------------------------- revereseString  ---------------------------------------*/
	/* reverse bytes, from r0 to r0+r1 */
reverseString:

	start .req r0
	end .req r1

	add end, start
	sub end,#1

revLoop$:
	cmp end,start
	movls pc,lr

	tmp1 .req r2
	tmp2 .req r3
	
	ldrb tmp1,[start]			
	ldrb tmp2,[end]			
	strb tmp2,[start]
	strb tmp1,[end]

	/* going at it from both ends */
	add start,#1
	sub end,#1
	
	b revLoop$
	
/*-------------------------------------- formatString  ---------------------------------------*/
	/* r0=addr to format, r1=len of format, r2=storage dest, r3+stack arguments */
formatString:

	push {r4,r5,r6,r7,r8,r9,lr}

	format .req r4
	formatLen .req r5
	dest .req r6
	arg .req r7
	argList .req r8
	len .req r9


	/* keep arguments */
	mov format, r0
	mov formatLen, r1
	mov dest, r2
	mov arg, r3
	add argList, sp,#7*4		// hold addr to stack arguments, compensate for the pushed regs
	mov len, #0			// initialize

formatLoop$:

	subs formatLen, #1
	movlt r0,len
	poplt {r4,r5,r6,r7,r8,r9,pc}

	/* check format */
	ldrb r0,[format]
	add format,#1
	teq r0,#'%'			// is format arg
	beq formatArg$

/* store the character */
formatChar$:
	teq dest,#0			// no store flag
	strneb r0,[dest]
	addne dest,#1
	add len,#1
	b formatLoop$

formatArg$:
	subs formatLen,#1
	movlt r0,len			// if through all args
	poplt {r4,r5,r6,r7,r8,r9,pc}

	/* load argument */
	ldrb r0,[format]
	add format,#1

	/* check % character */
	teq r0,#'%'
	beq formatChar$

	/* check ascii arg */
	teq r0,#'c'
	moveq r0, arg
	ldreq arg,[arglist]		// get argument off stack
	addeq argList,#4
	beq formatChar$

	/* check string arg */
	teq r0,#'s'
	beq formatString$

	/* check signed decimal int arg */
	teq r0,#'d'
	beq formatSigned$

	/* check unsigned int args */
	teq r0,#'u'			// unsigned decimal
	teqne r0, #'x'			// hex
	teqne r0,#'b'			// binary
	teqne r0,#'o'			// octal
	beq formatUnsigned$

	b formatLoop$			// default: move on

formatString$:
	ldrb r0,[arg]			// load byte of string

	/* check for null terminator */
	teq r0,#'\0'			
	ldreq arg,[argList]
	addeq argList,#4
	beq formatLoop$

	add len,#1
	teq dest,#0
	strneb r0,[dest]		// store byte for byte
	addne dest,#1
	add arg,#1
	b formatString$

formatSigned$:
	mov r0, arg			// pass number
	ldr arg, [argList]		// load next arg
	add argList,#4

	mov r1,dest			// pass storage addr
	mov r2,#10			// pass decimal base
	bl signedString

	teq dest,#0
	addne dest,r0			// add len of number as string
	add len, r0
	b formatLoop$

formatUnsigned$:

	/* unsigned decimal */
	teq r0,#'u'
	moveq r2,#10			// pass base

	/* hex */
	teq r0,#'x'
	moveq r2,#16			// pass base

	/* binary */
	teq r0,#'b'
	moveq r2,#2			// pass base

	/* octal */
	teq r0,#'o'
	moveq r2,#8			// pass base

	mov r0,arg			// pass number
	ldr arg,[argList]
	add argList,#4
	mov r1,dest			// pass storage dest
	bl unsignedString

	teq dest,#0
	addne dest,r0
	add len, r0
	b formatLoop$
