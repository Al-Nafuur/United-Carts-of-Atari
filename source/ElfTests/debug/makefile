all: debug-clock.bin debug-elapsed.bin

debug-clock.bin: debug.c
	arm-none-eabi-gcc -r -mlong-calls -fno-exceptions -march=armv6-m *.c -o debug-clock.bin -O3 -Wall -lgcc -DARG_TYPE=MP_CLOCK_HZ
	arm-none-eabi-strip debug-clock.bin -d -R.comment -R.ARM.attributes

debug-elapsed.bin: debug.c
	arm-none-eabi-gcc -r -mlong-calls -fno-exceptions -march=armv6-m *.c -o debug-elapsed.bin -O3 -Wall -lgcc -DARG_TYPE=MP_ELAPSED
	arm-none-eabi-strip debug-elapsed.bin -d -R.comment -R.ARM.attributes

clean:
	rm *.bin -f
	rm *.elf -f