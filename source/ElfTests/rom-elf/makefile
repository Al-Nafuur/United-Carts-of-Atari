rom_elf: rom_elf.c
	arm-none-eabi-gcc -r -mlong-calls -fno-exceptions -march=armv6-m rom_elf.c -o rom_elf.o -O3 -Wall -lgcc
	arm-none-eabi-ld -r rom_elf.o -b binary 4k_rom.bin -orom_elf.bin
	arm-none-eabi-strip rom_elf.bin -d -R.comment -R.ARM.attributes

