raycaster: raycaster.c
	arm-none-eabi-gcc -r -mlong-calls -fno-exceptions -march=armv7-m *.c -oraycaster.bin -O2 -Wall
	arm-none-eabi-strip raycaster.bin -d -R.comment -R.ARM.attributes
	arm-none-eabi-ld raycaster.bin vcsMock.a -oraycaster-linked.elf -Tstm32f4_flash.ld
