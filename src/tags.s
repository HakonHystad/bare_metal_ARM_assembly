/* finds the system tags */

///////////////////////////////////////////////////////////////////////////////////////
// data
//////////////////////////////////////////////////////////////////////////////////////

.section .data

tag_core: .int 0
tag_mem: .int 0
tag_videotext: .int 0
tag_ramdisk: .int 0
tag_initrd2: .int 0
tag_serial: .int 0
tag_revision: .int 0
tag_videolfb: .int 0
tag_cmdline: .int 0

///////////////////////////////////////////////////////////////////////////////////////
// declarations
//////////////////////////////////////////////////////////////////////////////////////

.section .text

	.globl findTag

///////////////////////////////////////////////////////////////////////////////////////
// definitions
//////////////////////////////////////////////////////////////////////////////////////

/*-------------------------------------- findTag  ---------------------------------------*/
/* search for tags and place them in memory return address of spesific tag=r0 */
findTag:	
	/* validate input */
	sub r0,#1		// if neg nr is big in unsigned comp + we need it later
	cmp r0,#8
	movhi r0,#0		// return 0
	movhi pc,lr

	tag .req r0
	tagList .req r1
	tagAddr .req r2

	ldr tagList,=tag_core	// address to our stored tags

tagReturn$:	
	/* find tagAddr */
	add tagAddr,tagList,tag,lsl #2 // every size is multiple of 4, offset by tag-1
	ldr tagAddr,[tagAddr]	// content/length of tag

	/* check content at tag (!=0) */
	teq tagAddr,#0
	movne r0,tagAddr
	movne pc,lr		// success, return addr

	/* check core content */
	ldr tagAddr,[tagList]
	teq tagAddr,#0
	movne r0,#0
	movne pc,lr		// could not find tag addr and core is valid -> does not exist

	/* have not prev stored tags, lets search for them */
	mov tagAddr,#0x100	// core start in memory

	push {r4}
	tagIndex .req r3
	oldAddr .req r4

tagLoop$:
	ldrh tagIndex,[tagAddr,#4] // tag nr
	subs tagIndex,#1
	poplt {r4}
	blt tagReturn$		// tag nr is not valid (==0), we're at the end


	/* valid tag found, check if we allready stored this addr */
	add tagIndex,tagList,tagIndex,lsl #2
	ldr oldAddr,[tagIndex]
	teq oldAddr,#0
	.unreq oldAddr
	streq tagAddr,[tagIndex] // if not, store it

	/* add the length of the found tag to find the next */
	ldr tagIndex,[tagAddr]
	add tagAddr,tagIndex,lsl #2 // length stored in lower half word
	b tagLoop$

	.unreq tag
	.unreq tagList
	.unreq tagAddr
	.unreq tagIndex
	
	
