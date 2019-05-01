SECTIONS
{
	. = 0x10000;
	.startup . : { startup.o(.text) }
	.text : { *(.text) }
	.data : { *(data) }
	.bss : { *(bss COMMON) }
	. = ALIGN(8);
	. = . + 0X1000; /* 4Kb of stack memory */
	stack_top = .;
	. = 0x12300000;
	. = ALIGN(16);
	ttb_address = .;
}
