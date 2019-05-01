.equ Mode_FIQ, 0x11
.equ Mode_IRQ, 0x12
.equ Mode_SVC, 0x13

LDR R0, =stack_top	@stack_base
@ Enter each mode in turn and set up the stack pointer
MSR CPSR_c, #Mode_FIQ:OR:I_Bit:OR:F_Bit ;
MOV SP, R0
SUB R0, R0, #FIQ_Stack_Size
MSR CPSR_c, #Mode_IRQ:OR:I_Bit:OR:F_Bit ;
MOV SP, R0

@ Disable MMU
MRC p15, 0, r1, c1, c0, 0 @ Read Control Register configuration data
BIC r1, r1, #0x1
MCR p15, 0, r1, c1, c0, 0 @ Write Control Register configuration data

@ Disable L1 Caches
MRC p15, 0, r1, c1, c0, 0 @ Read Control Register configuration data
BIC r1, r1, #(0x1 << 12)  @ Disable I Cache
BIC r1, r1, #(0x1 << 2)   @ Disable D Cache
MCR p15, 0, r1, c1, c0, 0 @ Write Control Register configuration data

@ Invalidate L1 Caches
@ Invalidate Instruction cache
MOV r1, #0
MCR p15, 0, r1, c7, c5, 0

@ Invalidate Data cache
@ to make the code general purpose, we calculate the
@ cache size first and loop through each set + way
MRC p15, 1, r0, c0, c0, 0   @ Read Cache Size ID
LDR r3, =stack_top
AND r0, r3, r0, LSR #13     @ r0 = no. of sets - 1

MOV r1, #0                  @ r1 = way counter way_loop
way_loop:
MOV r3, #0                  @ r3 = set counter set_loop
set_loop:
MOV r2, r1, LSL #30 
ORR r2, r3, LSL #5          @ r2 = set/way cache operation format
MCR p15, 0, r2, c7, c6, 2   @ Invalidate line described by r2
ADD r3, r3, #1              @ Increment set counter
CMP r0, r3                  @ Last set reached yet?
BGT set_loop                @ if not, iterate set_loop
ADD r1, r1, #1              @ else, next
CMP r1, #4                  @ Last way reached yet?
BNE way_loop                @ if not, iterate way_loop

@ Invalidate TLB
MCR p15, 0, r1, c8, c7, 0

@ Branch Prediction Enable
MOV r1, #0
MRC p15, 0, r1, c1, c0, 0   @ Read Control Register configuration data
ORR r1, r1, #(0x1 << 11)    @ Global BP Enable bit
MCR p15, 0, r1, c1, c0, 0   @ Write Control Register configuration data

@ Enable D-side Prefetch
MRC p15, 0, r1, c1, c0, 1 @ Read Auxiliary Control Register
ORR r1, r1, #(0x1 <<2) @ Enable D-side prefetch
MCR p15, 0, r1, c1, c0, 1 @ Write Auxiliary Control Register
DSB
ISB
@ DSB causes completion of all cache maintenance operations appearing in program
@ order before the DSB instruction
@ An ISB instruction causes the effect of all branch predictor maintenance
@ operations before the ISB instruction to be visible to all instructions
@ after the ISB instruction.
@ Initialize PageTable
	
@ We will create a basic L1 page table in RAM, with 1MB sections containing a flat (VA=PA) mapping, all pages Full Access, Strongly Ordered
@ It would be faster to create this in a read-only section in an assembly file

LDR r0, =0xDE2 @ r0 is the non-address part of descriptor
LDR r1, =ttb_address
LDR r3, = 4095 @ loop counter
write_pte:
ORR r2, r0, r3, LSL #20 @ OR together address & default PTE bits
STR r2, [r1, r3, LSL #2] @ write PTE to TTB
SUBS r3, r3, #1 @ decrement loop counter
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
BIC r1, r1, #0x1
MCR p15, 0, r1, c1, c0, 0	@ Write Control Register configuration data
	
@ Go to C program
@LDR sp, =stack_top
BL c_entry
B .
