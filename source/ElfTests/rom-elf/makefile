rom_elf: rom_elf.c
	arm-none-eabi-gcc -r -mlong-calls -fno-exceptions -march=armv7-m *.c -orom_elf.o -O2 -Wall
	arm-none-eabi-ld -r rom_elf.o -b binary 4k_rom.bin -orom_elf.bin
	arm-none-eabi-strip rom_elf.bin -d -R.comment -R.ARM.attributes
	arm-none-eabi-ld rom_elf.bin vcsMock.a cartridge_io_mock.a -orom_elf-linked.elf -Tstm32f4_flash.ld
