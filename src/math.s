	/* imlementing math functions */

///////////////////////////////////////////////////////////////////////////////////////
// declarations
//////////////////////////////////////////////////////////////////////////////////////
.section .text
	.globl divideU32

///////////////////////////////////////////////////////////////////////////////////////
// definition
//////////////////////////////////////////////////////////////////////////////////////

/*-------------------------------------- divideU32  ---------------------------------------*/
// r0 = divident, r1 = divisor. Return: result, remainder
divideU32:	

	divident .req r0
	divisor .req r1
	shift .req r2
	current .req r3

	/* get nr of shifts */
	clz shift, divisor		// count leading zeros of divisor to get number of shifts
	clz r3, divident		// do the same to divident
	subs shift, r3			// limit the number of shifts possible, also set flags in case of divident<divisor
	lsl current, divisor, shift	// shift the divisor up

	.unreq divisor
	.unreq divident
	res .req r0
	mod .req r1

	/* initialize */
	mov mod, r0			// load remainder with divident
	mov res, #0			// initialize result

	blt divideU32Return$		// divident<divisor

divideU32Loop$:

	cmp mod, current
	blt divideU32LoopContinue$	//  while remainder<current

	add res, res,#1			// set/reset lsb
	subs mod, current		// update remainder
	lsleq res, shift		// shift in final bit
	beq divideU32Return$		// no more remainder => perfect division

divideU32LoopContinue$:	
	subs shift,#1			// --shift, (set flag shift<=0)
	lsrge current,#1		// shift divisor down 
	lslge res,#1			// shift in result
	bge divideU32Loop$		// while shift>0

divideU32Return$:

	mov pc,lr

	.unreq shift
	.unreq current
	.unreq res
	.unreq mod
	
