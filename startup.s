@ We will create a basic L1 page table in RAM, with 1MB sections containing a flat (VA=PA) mapping, all pages Full Access, Strongly Ordered
@ It would be faster to create this in a read-only section in an assembly file

LDR r0, =0xDE2 @ r0 is the non-address part of descriptor
LDR r1, =ttb_address
LDR r3, = 4095 @ loop counter
write_pte:
ORR r2, r0, r3, LSL #20 @ OR together address & default PTE bits
STR r2, [r1, r3, LSL #2] @ write PTE to TTB
SUBS r3, r3, #1 @ decrement loop counter
CMP r3, #0
BNE write_pte

@ for the very first entry in the table, we will make it cacheable, normal, write-back, write allocate
BIC r0, r0, #0xC @ clear CB bits
ORR r0, r0, #0X4 @ inner write-back, write allocate
BIC r0, r0, #0x7000 @ clear TEX bits
ORR r0, r0, #0x5000 @ set TEX as write-back, write allocate
ORR r0, r0, #0x10000 @ shareable
STR r0, [r1]

@ Initialize MMU
MOV r1,#0x0
MCR p15, 0, r1, c2, c0, 2 @ Write Translation Table Base Control Register
LDR r1, =ttb_address
MCR p15, 0, r1, c2, c0, 0 @ Write Translation Table Base Register 0

@ In this simple example, we don't use TRE or Normal Memory Remap Register.
@ Set all Domains to Client
LDR r1, =0x55555555
MCR p15, 0, r1, c3, c0, 0 @ Write Domain Access Control Register
	
@ Enable MMU
MRC p15, 0, r1, c1, c0, 0	@ Read Control Register configuration data
ORR r1, r1, #0x1
MCR p15, 0, r1, c1, c0, 0	@ Write Control Register configuration data
	
@ Go to C program
LDR sp, =stack_top
BL c_entry
B .
