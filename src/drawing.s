	.include "mmap.s"
	
///////////////////////////////////////////////////////////////////////////////////////
// data
//////////////////////////////////////////////////////////////////////////////////////

.section .data
	.align 1
foreColor:
	.hword 0xFFFF
	
	.align 2
graphicsAddress:
	.int 0

	.align 4
font:
	.incbin "font.bin"	// font stored as separate binary file

///////////////////////////////////////////////////////////////////////////////////////
// declarations
//////////////////////////////////////////////////////////////////////////////////////

.section .text
	.globl setForeColor	// change the color
	.globl setGraphicsAddr	// change/set graphics address
	.globl setPixel		// draw a given pixel
	.globl drawLine		// sets pixels in a line between 2 points
	.globl drawRectangle	// make a rectangle based on size and upper left corner coordinate
	.globl drawRectangleDiag // make a rectangle based on the diagonal
	.globl drawChar		// make a fonted character
	.globl drawString

///////////////////////////////////////////////////////////////////////////////////////
// definitions
//////////////////////////////////////////////////////////////////////////////////////
	
/*-------------------------------------- setForeColor  ---------------------------------------*/
/* changes to the color given in r0 */
setForeColor:
	/* validate input */
	cmp r0,#0x10000		// max 16 bit colors
	movhs pc,lr


	ldr r1,=foreColor
	strh r0,[r1]		// change color
	mov pc,lr


/*-------------------------------------- setGraphicsAddr  ---------------------------------------*/
/* changes to the address in r0 */
setGraphicsAddr:
	ldr r1,=graphicsAddress
	str r0,[r1]
	mov pc,lr


/*-------------------------------------- setPixel  ---------------------------------------*/
/* sets the pixel x=r0,y=r1 */
setPixel:
	x .req r0
	y .req r1
	addr .req r2
	/* validate input */
	ldr addr,=graphicsAddress
	ldr addr,[addr]

	height .req r3
	ldr height,[addr,#4]
	sub height,#1
	cmp y,height
	movhi pc,lr
	.unreq height

	
	width .req r3		// check width
	ldr width,[addr,#0]
	sub width,#1		// make boundary
	cmp x,width
	movhi pc,lr

	/* find memory offset */
	ldr addr,[addr,#32]
	sub addr,#unCachedOffset	// sub cache access
	add width,#1		// restore width
	mla x,y,width,x		// x=y*width+x -> offset
	add addr,x,lsl #1	// mem ptr = offset*2 ( 2 bytes per pixel/color )
	.unreq x
	.unreq y
	.unreq width

	/* set pixel */
	pcolor .req r3
	ldr pcolor,=foreColor
	ldrh pcolor,[pcolor]
	strh pcolor,[addr]
	.unreq pcolor
	.unreq addr

	mov pc,lr


/*-------------------------------------- drawLine  ---------------------------------------*/
/* set pixels in line between points r0=x0,r1=y0,r2=x1,r3=y1 */
drawLine:
	push {r4,r5,r6,r7,r8,r9,r10,r11,r12,lr}

	x0 .req r4
	mov x0,r0
	y0 .req r5
	mov y0,r1
	x1 .req r6
	mov x1,r2
	y1 .req r7
	mov y1,r3

	dx .req r8
	dy .req r9
	stepx .req r10
	stepy .req r11
	err .req r12

	/* calc deltaX and sign of step x-dir */
	cmp x1,x0
	subgt dx,x1,x0		// x1>x0
	movgt stepx,#1
	suble dx,x0,x1		// x1<=x0
	movle stepx,#-1

	/* calc deltaX and sign of step x-dir */
	cmp y1,y0
	subgt dy,y0,y1		// only use negative deltaY
	movgt stepy,#1
	suble dy,y1,y0
	movle stepy,#-1

	/* initial error */
	add err,dx,dy

	/* conditions */
	add x1,stepx
	add y1,stepy

/* iterate over all pixels in between */
nextPixel$:
	/* test condition met */
	teq x0,x1		// at end x?
	teqne y0,y1		// if not: at end y?
	popeq {r4,r5,r6,r7,r8,r9,r10,r11,r12,pc}

	/* draw pixel */
	mov r0,x0
	mov r1,y0
	bl setPixel

	/* if( -deltay < error*2 ) */
	cmp dy,err,lsl #1 
	addle x0,stepx
	addle err,dy

	/* if( deltax > error*2 ) */
	cmp dx,err,lsl #1
	addge y0,stepy
	addge err,dx

	b nextPixel$

	.unreq x0
	.unreq x1
	.unreq y0
	.unreq y1
	.unreq dx
	.unreq dy
	.unreq stepx
	.unreq stepy
	.unreq err



/*-------------------------------------- drawRectangle  ---------------------------------------*/	
/* make rectangle with width=r0,height=r1,upper left corner: x=r2,y=r3 */
drawRectangle:
	push {r4,r5,r6,r7,lr}

	width .req r4
	mov width,r0
	height .req r5
	mov height,r1
	x .req r6
	mov x,r2
	y .req r7
	mov y,r3

	x0 .req r0
	y0 .req r1
	x1 .req r2
	y1 .req r3

	/* top line */
	mov x0,x
	mov y0,y
	mov x1,x
	add x1,width
	mov y1,y
	push {x1,y1}		// save current point
	bl drawLine

	/* right line */
	pop {x0,y0}
	mov x1,x0
	mov y1,y0
	add y1,height
	push {x1,y1}
	bl drawLine

	/* bottom line */
	pop {x0,y0}
	mov x1,x0
	sub x1,width
	mov y1,y0
	push {x1,y1}
	bl drawLine

	/* left line */
	pop {x0,y0}
	mov x1,x0
	mov y1,y0
	sub y1,height
	bl drawLine

	pop {r4,r5,r6,r7,pc}

	.unreq width
	.unreq height
	.unreq x
	.unreq y
	.unreq x0
	.unreq y0
	.unreq x1
	.unreq y1

/*-------------------------------------- drawRectangle2  ---------------------------------------*/
	/* pass diagonal: r0=x_1,r1=y_1,r2=x_2,r3=y_2 */

drawRectangleDiag:
	push {r4,r5,r6,r7,r8,r9,r10,r11,lr}

	x1 .req r4
	y1 .req r5
	x2 .req r6
	y2 .req r7

	mov x1,r0
	mov y1,r1
	mov x2,r2
	mov y2,r3

	width .req r8
	height .req r9
	X .req r10
	Y .req r11


	/* get width parameters */
	subs width,x2,x1		
	rsblt width,#0		// absolute value
	movlt X,x2		// x1>x2
	movge X,x1

	/* get height parameters */
	subs height,y2,y1
	rsblt height,#0		// abs value
	movlt Y,y2		// y1>y2
	movge Y,y1

/* set upper and lower pixels over the width */
widthLoop$:
	subs width,#1
	blt heightLoop$

	/* set y1 pixel at (r0,r1) */
	mov r0,X
	mov r1,y1		
	bl setPixel

	/* set y2 pixel at (r0,r1) */
	mov r0,X
	mov r1,y2		
	bl setPixel

	/* update width direction */
	add X,#1


	b widthLoop$

/* set left and right over the height */
heightLoop$:
	subs height,#1
	poplt {r4,r5,r6,r7,r8,r9,r10,r11,pc}

	/* set x1 pixel at (r0,r1) */
	mov r0,x1
	mov r1,Y		
	bl setPixel

	/* set y2 pixel at (r0,r1) */
	mov r0,x2
	mov r1,Y		
	bl setPixel

	/* update width direction */
	add Y,#1

	b heightLoop$


	.unreq X
	.unreq Y
	.unreq width
	.unreq height
	.unreq x1
	.unreq y1
	.unreq x2
	.unreq y2
	

	
	
	
/*-------------------------------------- drawChar  ---------------------------------------*/	
/* get the specified ASCII char=r0 from the font variable and draws it at x=r1,y=r2. Return the size of the written char, r0=width, r1=height */
drawChar:
	
	/* validate input */
	cmp r0,#127
	movhi r0,#0		// no char set
	movhi r1,#0
	movhi pc,lr
	

	push {r4,r5,r6,r7,r8,lr}

	char .req r0
	posx .req r5
	mov posx,r1
	posy .req r6
	mov posy,r2

	/* find address of char */
	charAddr .req r4
	ldr charAddr,=font
	add charAddr,char,lsl #4 // each char takes up 16 bytes
	.unreq char

charLoop$:
	/* 16 rows of 8 bits each */

	pixels .req r7
	ldrb pixels,[charAddr]

	/*iterate over each pixel/bit */
	bit .req r8
	mov bit,#8		// loop count/col offset
pixelLoop$:
	/* loop check 1 */
	subs bit,#1		// subtract AND set zero flag
	blt pixelLoopEnd$	// loop check if short loop back

	/* check if set */
	lsl pixels,#1
	tst pixels,#0x100	// check if prev MSB of 1st byte was set
	beq pixelLoop$		// if not (and ret 0) loop back pixel

	/* set pixel */
	add r0,posx,bit		// loop count doubles as col offset
	mov r1,posy
	bl setPixel

	/* loop check 2 */
	teq bit,#0		// loop check if long loop back
	bne pixelLoop$

pixelLoopEnd$:
	.unreq bit
	.unreq pixels

	add posy,#1		// add new row
	add charAddr,#1		// add new row addr (next byte)

	tst charAddr,#0b1111	// the align 4 gives the first 4 bits all 0 in the start of a valid addr
	bne charLoop$

	.unreq posx
	.unreq posy
	.unreq charAddr

	/* return size of made character */
	mov r0,#8		// width
	mov r1,#16		// height

	pop {r4,r5,r6,r7,r8,pc}
	
	
/*-------------------------------------- drawString  ---------------------------------------*/
/* r0=ptr to string, r1=length, r2=x, r3=y */
drawString:
	push {r4,r5,r6,r7,r8,r9,lr}

	x .req r4		// current horizontal pos
	mov x,r2
	y .req r5		// current vertical pos
	mov y,r3
	x0 .req r6		// string start horizontal pos
	mov x0,x
	string .req r7
	mov string,r0
	len .req r8
	mov len,r1
	char .req r9		// current character of string

stringLoop$:
	/* loop count */
	subs len,#1
	blt stringLoopEnd$

	/* get the next character */
	ldrb char,[string]
	add string,#1

	/* draw it */
	mov r0,char
	mov r1,x
	mov r2,y
	bl drawChar		// if it's not printable nothing happens

	/* handle control characters */
	width .req r0
	height .req r1

	/* - newline */
	teq char,#'\n'
	moveq x,x0
	addeq y,height
	beq stringLoop$

	/* - tab */
	teq char,#'\t'
	addne x,width		// if not: update horizontal position
	bne stringLoop$		// and loop back

	add width, width,lsl #2	// tab=5 blank chars

	newX .req r1
	mov newX,x0
/* loop until we are past the current horizontal position */
tabLoop$:	
	add newX,width		// add 1 tab
	cmp x,newX		
	bge tabLoop$

	mov x,newX
	.unreq newX

	b stringLoop$


stringLoopEnd$:
	.unreq width
	.unreq height
	.unreq x
	.unreq y
	.unreq x0
	.unreq string
	.unreq len

	pop {r4,r5,r6,r7,r8,r9,pc}
	
