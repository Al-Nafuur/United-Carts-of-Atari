all: debug-clock.bin debug-elapsed.bin

debug-clock.bin: debug.c vcsLib.h
	arm-none-eabi-gcc -r -mlong-calls -fno-exceptions -march=armv7-m *.c -odebug-clock.bin -O2 -Wall -DARG_TYPE=MP_CLOCK_HZ
	arm-none-eabi-strip debug-clock.bin -d -R.comment -R.ARM.attributes
	arm-none-eabi-ld debug-clock.bin vcsMock.a -odebug-clock-linked.elf -Tstm32f4_flash.ld


debug-elapsed.bin: debug.c vcsLib.h
	arm-none-eabi-gcc -r -mlong-calls -fno-exceptions -march=armv7-m *.c -odebug-elapsed.bin -O2 -Wall -DARG_TYPE=MP_ELAPSED
	arm-none-eabi-strip debug-elapsed.bin -d -R.comment -R.ARM.attributes
	arm-none-eabi-ld debug-elapsed.bin vcsMock.a -odebug-elapsed-linked.elf -Tstm32f4_flash.ld

clean:
	rm *.bin -f
	rm *.elf -f