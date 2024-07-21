main:
	nasm boot.asm -f bin -o boot.bin

high:
	gcc -ffreestanding -c kernel.c -o kernel.o
	ld -o kernel.bin -Ttext 0x1000 kernel.o --oformat binary

concat: 
	cat boot.bin kernel.bin > os-image

boot: 
	qemu-system-i386 os-image

display:
	od -t x1 -A n boot.bin