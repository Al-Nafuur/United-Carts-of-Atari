region: region.c
	arm-none-eabi-gcc -r -mlong-calls -fno-exceptions -march=armv7-m *.c -oregion.bin -O2 -Wall
	arm-none-eabi-strip region.bin -d -R.comment -R.ARM.attributes
	arm-none-eabi-ld region.bin vcsMock.a -oregion-linked.elf -Tstm32f4_flash.ld
