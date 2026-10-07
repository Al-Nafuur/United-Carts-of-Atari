#include "../../STM32firmware/PlusCart/Inc/vcsLib.h"
#include "cartridge_io.h"

// Value provided by linker when linking in 4k rom binary
// Just ignore the size and end for now and assume it's a valid 4k binary blob
extern uint8_t _binary_4k_rom_bin_start[];
// extern uint32_t _binary_rom_bin_size;
// extern uint8_t* _binary_rom_bin_end;

int elf_main()
{
	uint16_t addr, addr_prev = 0;
	uint8_t* buffer = (uint8_t*)_binary_4k_rom_bin_start;
	uint16_t resetVector = *((uint16_t*)&buffer[0xffc]) & 0x1fff;
	vcsJsr6(resetVector);

	// Wait for the JSR to complete and put the first byte on the bus to give the driver time to get going
	while (ADDR_IN != resetVector)
		;
	DATA_OUT = buffer[resetVector & 0xfff];
	while (ADDR_IN == resetVector)
		;

	while (1)
	{
		while ((addr = ADDR_IN) != addr_prev)
			addr_prev = addr;

		if (addr & 0x1000)
		{
			// A12 high
			DATA_OUT = buffer[addr & 0xfff];
			SET_DATA_MODE_OUT;
		}
		else
		{
			SET_DATA_MODE_IN;
		}
	}
	return 0;
}

