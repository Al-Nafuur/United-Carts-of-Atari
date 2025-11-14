raycaster: raycaster.c
	arm-none-eabi-gcc -r -mlong-calls -fno-exceptions -march=armv6-m *.c -o raycaster.bin -O3 -Wall -lgcc
	arm-none-eabi-strip raycaster.bin -d -R.comment -R.ARM.attributes
