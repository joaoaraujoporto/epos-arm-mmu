SECTIONS
{
	. = 0x10000;
	.startup . : { startup.o(.text) }
	.text : { *(.text) }
	.data : { *(data) }
	.bss : { *(bss COMMON) }
	. = ALIGN(16);
	. = . + 0X1000; /* 4Kb of stack memory */
	stack_top = .;
	. = 0xFFFFFF;
	. = ALIGN(16);
	ttb_address = .;
}
