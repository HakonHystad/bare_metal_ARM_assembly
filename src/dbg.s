	/* for debugging purposes */

.section .text

.globl printNr
// print the number given in r0	
printNr:
	push {r0-r3,lr}		// pushing all as to not disturb anything

	mov r3,r0

	ldr r0,=NR
	mov r1,#endNR-NR
	ldr r2,=endNR

	bl formatString

	mov r1,r0		// length
	ldr r0,=endNR		// string ptr
	mov r2,#200		// x
	mov r3,#200		// y
	bl drawString

	pop {r0-r3,pc}

.section .data

NR:
	.ascii "DBG: %d"
endNR:	
