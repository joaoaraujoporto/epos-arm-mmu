all: arm

run: arm qemu

arm:
	arm-none-eabi-as -mcpu=cortex-a9 -g startup.s -o startup.o
	arm-none-eabi-gcc -c -mcpu=cortex-a9 -g test.c -o test.o
	arm-none-eabi-ld -T test.ld test.o startup.o -o test.elf
	arm-none-eabi-objcopy -O binary test.elf test.bin

qemu:
	qemu-system-arm -M realview-pbx-a9 -m 2048M -nographic -kernel test.bin

clean:
	rm *o *bin *elf *~
