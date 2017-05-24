


	///////////////////////////////////////////////////////////////////////////////////////
	// GPIO
	//////////////////////////////////////////////////////////////////////////////////////
	.equ GPIOaddr, 0x3F200000	// the GPIO base address (gpio function select 0)
	.equ GPSEL1, 0x4		// gpio function select 1
	.equ GPSEL2, 0x8		// function select 2
	.equ GPSEL3, 0xC		// function select 3

	.equ GPSET0, 0x1C		// gpio pin output set 0
	.equ GPSET1, 0x20		// output set 1

	.equ GPCLR0, 0x28		// gpio pin output clear 0
	.equ GPCLR1, 0x2C		// output clear 1

	.equ GPLEV0, 0x34		// gpio pin level 0
	.equ GPLEV1, 0x38		// pin level 1

	.equ GPEDS0, 0x40		// gpio event detect status 0
	.equ GPEDS1, 0x44		// event detect status 1

	.equ GPREN0, 0x4C		// gpio pin rising edge detect enable 0
	.equ GPREN1, 0x50		// rising edge detect 1

	.equ GPFEN0, 0x58		// gpio pin falling edge detect enable 0
	.equ GPFEN1, 0x5C		// falling edge detect enable 1

	.equ GPPUD, 0x94		// gpio pin pull-up/down enable
	.equ GPPUDCLK0, 0x98		// gpio pull-up/down enable clock 0
	.equ GPPUDCLK1, 0x9C		// pull-up/down enable clock 1

	///////////////////////////////////////////////////////////////////////////////////////
	// TIMER
	//////////////////////////////////////////////////////////////////////////////////////
	.equ timerAddr, 0x3F003000	// timer base address

	///////////////////////////////////////////////////////////////////////////////////////
	// GPU
	//////////////////////////////////////////////////////////////////////////////////////
	.equ mailboxAddr, 0x3F00B880	// mailbox base address
	.equ unCachedOffset, 0xC0000000		// uncached bus address of the VideoCore start 

	///////////////////////////////////////////////////////////////////////////////////////
	// Interrupts
	//////////////////////////////////////////////////////////////////////////////////////
	.equ IRQaddr, 0x3F00B000	// interrupt base address
	// offsets
	.equ IRQ_BASIC_PDG, 0x200	// basic interrupt pending
	.equ IRQ_PDG1, 0x204		// pending interrupt 1
	.equ IRQ_PDG2, 0x208		// pending 2
	.equ IRQ_EN1, 0x210		// interrupt enable 1
	.equ IRQ_EN2, 0x214		// enable 2
	.equ IRQ_DI1, 0x21C		// interrupt disable 1
	.equ IRQ_DI2, 0x220		// disable 2




