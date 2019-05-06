.global _Reset
_Reset:
	B Reset_Handler
	B .

Reset_Handler: 	
    	@ Disable MMU
	MRC p15, 0, r1, c1, c0, 0	@ Atribui-se ao R1 o valor do registrador 1 do    
		                	@ coprocessor 15
	BIC r1, r1, #0x1           	@ Atribui-se ao bit 0 em R1 o valor 0, para 
		               		@ desligar a MMU 
	MCR p15, 0, r1, c1, c0, 0	@ Escreve-se no reg 1 do coprocessor 15 
		                	@ o que ha em R1, desabilitando a MMU

	@ Disable L1 Caches
	MRC p15, 0, r1, c1, c0, 0	@ Read Control Register configuration data
	BIC r1, r1, #(0x1 << 12)	@ Disable I Cache
	BIC r1, r1, #(0x1 << 2)		@ Disable D Cache
	MCR p15, 0, r1, c1, c0, 0	@ Write Control Register configuration data

	@ Invalidate L1 Caches
	@ Invalidate Instruction cache
	MOV r1, #0
	MCR p15, 0, r1, c7, c5, 0

	@ Invalidate Data cache
	@ to make the code general purpose, we calculate the
	@ cache size first and loop through each set + way
	MRC p15, 1, r0, c0, c0, 0	@ Read Cache Size ID
	LDR r3, =#0x1ff
	AND r0, r3, r0, LSR #13		@ r0 = no. of sets - 1
	MOV r1, #0			@ r1 = way counter way_loop
	way_loop:
	MOV r3, #0			@ r3 = set counter set_loop
	set_loop:
	MOV r2, r1, LSL #30
	ORR r2, r3, LSL #5 		@ r2 = set/way cache operation format
	MCR p15, 0, r2, c7, c6, 2 	@ Invalidate line described by r2
	ADD r3, r3, #1 			@ Increment set counter
	CMP r0, r3 			@ Last set reached yet?
	BGT set_loop 			@ if not, iterate set_loop
	ADD r1, r1, #1 			@ else, next
	CMP r1, #4 			@ Last way reached yet?
	BNE way_loop 			@ if not, iterate way_loop
	
	@ Invalidate TLB
	MCR p15, 0, r1, c8, c7, 0

	@ Aqui é criada uma L1 translation table na RAM que divide
	@ todo o espaço de endereçamento de 4GB em seções de 1 MB,
	@ todas com Full Access e Strongly Ordered
   	LDR r0, =0xDE2			@ Atribui-se ao R0 parte do descriptor
   	LDR r1, =ttb_address    	@ Atribui-se ao R1 endereço base
   	                            	@ da L1 tranlastion table
   	LDR r3, = 4095         		@ R3 se torna o contador para o loop
	
	write_pte:                  	@ Label do loop para escrita das 
                                	@ page table entry (PTE) da translation table
    	ORR r2, r0, r3, LSL #20     	@ Atribui-se ao R2 OR entre o endereço
                                    	@ e os bits padrão da PTE
   	STR r2, [r1, r3, LSL #2]    	@ Escreve-se a PTE na translation table
   	                                @ (endereço de escrita é o ttb_address somado
   	                                @ com contador e multiplicado por 4)
   	SUB r3, r3, #1              	@ Decrementa-se contador do loop
   	CMP r3, #-1                 	@ Faz-se a comparação para verificar
                                    	@ se loop acabou
	BNE write_pte               	@ Caso o loop não tenha acabado,
	                                @ escreve mais uma pte

	@ Faz-se a primeira entrada da tranlastion table
	@ cacheable, normal, write-back, write allocate
	BIC r0, r0, #0xC		@ Limpa-se CB bits
	ORR r0, r0, #0X4 		@ Write-back, write allocate
	BIC r0, r0, #0x7000 		@ Limpa-se TEX bits
	ORR r0, r0, #0x5000 		@ Faz-se TEX write-back e write allocate
	ORR r0, r0, #0x10000 		@ Torna compartilhável
	STR r0, [r1]			@ Escreve-se na primeira entrada

	@ Inicializa a MMU
   	MOV r1,#0x0
    	MCR p15, 0, r1, c2, c0, 2	@ Escrita do Translation Table Base Control Register
   	LDR r1, =ttb_address		@ Atribui-se ao R1 endereço base
   	                            	@ da L1 tranlastion table
   	MCR p15, 0, r1, c2, c0, 0	@ Escreve-se no reg 1 do coprocessor 15 o que ha 
                              		@ em r1 (endereco base da tranlastion table)

	@ In this simple example, we don't use TRE or Normal Memory Remap Register.
	@ Set all Domains to Client
	LDR r1, =0x55555555
	MCR p15, 0, r1, c3, c0, 0 @ Write Domain Access Control Register
	
	@ Enable MMU
	MRC p15, 0, r1, c1, c0, 0	@ Atribui-se ao R1 o valor do registrador 1 do    
		                	@ coprocessor 15
	ORR r1, r1, #0x1           	@ Atribui-se ao bit 0 em R1 o valor 1, para 
		               		@ ligar a MMU 
	MCR p15, 0, r1, c1, c0, 0	@ Escreve-se no reg 1 do coprocessor 15 
		                	@ o que há em R1, habilitando a MMU

	@ Go to C program
	LDR sp, =stack_top      	@ Atribui-se o endereco armazenado pela 
	                        	@ variavel stack_top (valor definido
					@ no linker script)
	BL c_entry          		@ Desvia-se para a funcao c_entry
					@ no codigo test.c 
                            		@ copiando o endereco para a próxima
					@ instrução em R14
	B .
