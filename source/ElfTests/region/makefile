region: region.c
	arm-none-eabi-gcc -r -mlong-calls -fno-exceptions -march=armv6-m region.c -o region.bin -O3 -Wall -lgcc
	arm-none-eabi-strip region.bin -d -R.comment -R.ARM.attributes