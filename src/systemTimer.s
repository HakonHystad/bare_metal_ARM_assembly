/* use the system counter to get time and also wait */
	
	.include "mmap.s"
	
///////////////////////////////////////////////////////////////////////////////////////
// Macros 
//////////////////////////////////////////////////////////////////////////////////////
	.macro loadTimerAddr
	ldr r0,=timerAddr
	.endm

///////////////////////////////////////////////////////////////////////////////////////
// declarations 
//////////////////////////////////////////////////////////////////////////////////////

	
	.globl wait		// waits a given amount of us's
	.globl getTime		// get the count of the timer

///////////////////////////////////////////////////////////////////////////////////////
// definitions
//////////////////////////////////////////////////////////////////////////////////////

/*-------------------------------------- wait  ---------------------------------------*/
/* waits the amount of micro second in r0  */
wait:
	push {lr}
	
	delay .req r3
	mov delay,r0

	/* get current counter value */
	bl getTime
	startTime .req r1
	mov startTime,r0

	/* wait until delay is met */
	currentTime .req r0
	elapsedTime .req r2
waitLoop$:
	bl getTime
	sub elapsedTime,r0,startTime // elapsed = current-start
	cmp elapsedTime,delay
	bls waitLoop$		// (branch link smaller)

	/* clean up and return */
	.unreq delay
	.unreq startTime
	.unreq currentTime
	.unreq elapsedTime
	pop {pc}
	
	
/*-------------------------------------- getTime  ---------------------------------------*/
/* returns the lowest 4 bytes of the system counter in r0 */
getTime:
	push {lr}
	loadTimerAddr
	ldr r0,[r0,#4]
	pop {pc}
