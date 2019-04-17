.global _Reset
_Reset:
  B Clean
  B Reset_Handler /* Reset */
  B . /* Undefined */
  B . /* SWI */
  B . /* Prefetch Abort */
  B . /* Data Abort */
  B . /* reserved */
  B . /* IRQ */
  B . /* FIQ */
 
Clean:
/*Disable MMU*/
MRC p15, 0, r1, c1, c0, 0 /* Read Control Register configuration data*/
BIC r1, r1, #0x1
MCR p15, 0, r1, c1, c0, 0 /* Write Control Register configuration data*/

/*Disable L1 Caches*/
MRC p15, 0, r1, c1, c0, 0 /* Read Control Register configuration data*/
BIC r1, r1, #(0x1 << 12)  /* Disable I Cache*/
BIC r1, r1, #(0x1 << 2)   /* Disable D Cache*/
MCR p15, 0, r1, c1, c0, 0 /* Write Control Register configuration data*/

/*Invalidate L1 Caches*/
/*Invalidate Instruction cache*/
MOV r1, #0
MCR p15, 0, r1, c7, c5, 0

/*Invalidate Data cache*/
/*to make the code general purpose, we calculate the*/
/*cache size first and loop through each set + way*/
MRC p15, 1, r0, c0, c0, 0   /*Read Cache Size ID*/
LDR r3, =stack_top
AND r0, r3, r0, LSR #13     /* r0 = no. of sets - 1*/

MOV r1, #0                  /* r1 = way counter way_loop*/
way_loop:
MOV r3, #0                  /*r3 = set counter set_loop*/
set_loop:
MOV r2, r1, LSL #30 
ORR r2, r3, LSL #5          /*r2 = set/way cache operation format*/
MCR p15, 0, r2, c7, c6, 2   /*Invalidate line described by r2*/
ADD r3, r3, #1              /* Increment set counter*/
CMP r0, r3                  /*Last set reached yet?*/
BGT set_loop                /* if not, iterate set_loop*/
ADD r1, r1, #1              /* else, next*/
CMP r1, #4                  /* Last way reached yet?*/
BNE way_loop                /* if not, iterate way_loop*/

/*Invalidate TLB*/
MCR p15, 0, r1, c8, c7, 0

/*Branch Prediction Enable*/
MOV r1, #0
MRC p15, 0, r1, c1, c0, 0   /* Read Control Register configuration data*/
ORR r1, r1, #(0x1 << 11)    /* Global BP Enable bit*/
MCR p15, 0, r1, c1, c0, 0    /* Write Control Register configuration data*/

Reset_Handler:
  LDR sp, =stack_top
  BL main
  B .
