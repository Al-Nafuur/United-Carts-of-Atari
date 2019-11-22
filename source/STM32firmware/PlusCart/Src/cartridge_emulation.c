/*
 * cartridge_emulation.c
 *
 *  Created on: 03.11.2019
 *      Author: stubig
 */

/*************************************************************************
 * Cartridge Emulation
 *************************************************************************/
#include <ctype.h>
#include <stdlib.h>
#include "cartridge_emulation.h"
#include "cartridge_firmware.h"

extern uint8_t c;
extern UART_HandleTypeDef huart1;


void emulate_2k_4k_cartridge( int header_length, _Bool withPlusFunctions, int mask) {
	setup_cartridge_image();

	__disable_irq();	// Disable interrupts

	uint16_t addr, addr_prev = 0, data = 0, data_prev = 0;
	setup_plus_rom_functions();

	while (1)
	{
		while ((addr = ADDR_IN) != addr_prev)
			addr_prev = addr;
		// got a stable address
		if (addr & 0x1000)
		{ // A12 high
			if(withPlusFunctions && addr > 0x1ff0 && addr < 0x1ff4){
				if(addr == 0x1ff2 ){// read from receive buffer
					DATA_OUT = ((uint16_t)receive_buffer[receive_buffer_read_pointer]);//<<8;
				    SET_DATA_MODE_OUT
					// if there is more data on the receive_buffer
					if(receive_buffer_read_pointer != receive_buffer_write_pointer )
					  receive_buffer_read_pointer++;
					// wait for address bus to change
					while (ADDR_IN == addr){}
					SET_DATA_MODE_IN
				}else if(addr == 0x1ff1){ // write to send Buffer and start Request !!
					while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
					if(huart_state == No_Transmission)
					  huart_state = Send_Start;
					out_buffer[out_buffer_write_pointer] = data_prev;//>>8;
				}else if(addr == 0x1ff3){ // read receive Buffer length
					DATA_OUT = ((uint16_t)(receive_buffer_write_pointer - receive_buffer_read_pointer));//<<8;
					SET_DATA_MODE_OUT
					// wait for address bus to change
					while (ADDR_IN == addr){}
					SET_DATA_MODE_IN
				}else{ // if(addr == 0x1ff0){ // write to send Buffer
					while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
					out_buffer[out_buffer_write_pointer++] = data_prev;//>>8;
				}
			 }else{
					DATA_OUT = ((uint16_t)cart_rom[addr&mask]);
					SET_DATA_MODE_OUT
					// wait for address bus to change
					while (ADDR_IN == addr) ;
					SET_DATA_MODE_IN
			 }
	    }else if(withPlusFunctions){
	      while (ADDR_IN == addr) {
	    	  process_transmission();
	      }
	    }
	}
	__enable_irq();
}

/* 'Standard' Bankswitching
 * ------------------------
 * Used by F8(8k), F6(16k), F4(32k), EF(64k)
 * and F8SC(8k), F6SC(16k), F4SC(32k), EFSC(64k)
 *
 * SC variants have 128 bytes of RAM:
 * RAM read port is $1080 - $10FF, write port is $1000 - $107F.
 */
void emulate_FxSC_cartridge(int header_length, _Bool withPlusFunctions, uint16_t lowBS, uint16_t highBS, int isSC)
{
	setup_cartridge_image_with_ram();

	__disable_irq();	// Disable interrupts
	uint16_t addr, addr_prev = 0, data = 0, data_prev = 0;
	unsigned char *bankPtr = &cart_rom[0];

	setup_plus_rom_functions();

	while (1)
	{
		while ((addr = ADDR_IN) != addr_prev)
			addr_prev = addr;
		// got a stable address
		if (addr & 0x1000)
		{ // A12 high
			if(withPlusFunctions && addr > 0x1ff0 && addr < 0x1ff4){
				if(addr == 0x1ff2 ){// read from receive buffer
					DATA_OUT = ((uint16_t)receive_buffer[receive_buffer_read_pointer]);
				    SET_DATA_MODE_OUT
					// if there is more data on the receive_buffer
					if(receive_buffer_read_pointer != receive_buffer_write_pointer )
					  receive_buffer_read_pointer++;
					// wait for address bus to change
					while (ADDR_IN == addr){}
					SET_DATA_MODE_IN
				}else if(addr == 0x1ff1){ // write to send Buffer and start Request !!
					while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
					if(huart_state == No_Transmission)
					  huart_state = Send_Start;
					out_buffer[out_buffer_write_pointer] = data_prev;//>>8;
				}else if(addr == 0x1ff3){ // read receive Buffer length
					DATA_OUT = ((uint16_t)(receive_buffer_write_pointer - receive_buffer_read_pointer));
					SET_DATA_MODE_OUT
					// wait for address bus to change
					while (ADDR_IN == addr){}
					SET_DATA_MODE_IN
				}else{ // if(addr == 0x1ff0){ // write to send Buffer
					while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
					out_buffer[out_buffer_write_pointer++] = data_prev;
				}
			}else{
				if (addr >= lowBS && addr <= highBS)	// bank-switch
					bankPtr = &cart_rom[(addr-lowBS)*4*1024];

				if (isSC && (addr & 0x1F00) == 0x1000)
				{	// SC RAM access
					if (addr & 0x0080)
					{	// a read from cartridge ram
						DATA_OUT = ((uint16_t)cart_ram[addr&0x7F]);//<<8;
						SET_DATA_MODE_OUT
						// wait for address bus to change
						while (ADDR_IN == addr) ;
						SET_DATA_MODE_IN
					}
					else
					{	// a write to cartridge ram
						// read last data on the bus before the address lines change
						while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
						cart_ram[addr&0x7F] = data_prev;//>>8;
					}
				}
				else
				{	// normal rom access
					DATA_OUT = ((uint16_t)bankPtr[addr&0xFFF]);//<<8;
					SET_DATA_MODE_OUT
					// wait for address bus to change
					while (ADDR_IN == addr) ;
					SET_DATA_MODE_IN
				}

			}
	    }else if(withPlusFunctions){
	      while (ADDR_IN == addr) {
	    	  process_transmission();
	      }
	    }
	}
	__enable_irq();
}

/* FA (CBS RAM plus) Bankswitching
 * -------------------------------
 * Similar to the above, but with 3 ROM banks for a total of 12K
 * plus 256 bytes of RAM:
 * RAM read port is $1100 - $11FF, write port is $1000 - $10FF.
 */
void emulate_FA_cartridge()
{
	setup_cartridge_image_with_ram();

	__disable_irq();	// Disable interrupts
	uint16_t addr, addr_prev = 0, data = 0, data_prev = 0;
	unsigned char *bankPtr = &cart_rom[0];

	while (1)
	{
		while ((addr = ADDR_IN) != addr_prev)
			addr_prev = addr;
		// got a stable address
		if (addr & 0x1000)
		{ // A12 high
			if (addr >= 0x1FF8 && addr <= 0x1FFA)	// bank-switch
				bankPtr = &cart_rom[(addr-0x1FF8)*4*1024];

			if ((addr & 0x1F00) == 0x1100)
			{	// a read from cartridge ram
				DATA_OUT = ((uint16_t)cart_ram[addr&0xFF]);//<<8;
				SET_DATA_MODE_OUT
				// wait for address bus to change
				while (ADDR_IN == addr) ;
				SET_DATA_MODE_IN
			}
			else if ((addr & 0x1F00) == 0x1000)
			{	// a write to cartridge ram
				// read last data on the bus before the address lines change
				while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
				cart_ram[addr&0xFF] = data_prev;//>>8;
			}
			else
			{	// normal rom access
				DATA_OUT = ((uint16_t)bankPtr[addr&0xFFF]);//<<8;
				SET_DATA_MODE_OUT
				// wait for address bus to change
				while (ADDR_IN == addr) ;
				SET_DATA_MODE_IN
			}
		}
	}
	__enable_irq();
}

/* FE Bankswitching
 * ----------------
 * The text below is quoted verbatim from the source code of the Atari
 * 2600 emulator Stella (https://github.com/stella-emu) which was the
 * best reference that I could find for FE bank-switching.
 * The implementation below is based on this description, and the relevant
 * source files in Stella.
 */

/*
  Bankswitching method used by Activision's Robot Tank and Decathlon.

  This scheme was originally designed to have up to 8 4K banks, and is
  triggered by monitoring the address bus for address $01FE.  All released
  carts had only two banks, and this implementation assumes that (ie, ROM
  is always 8K, and there are two 4K banks).

  The following is paraphrased from the original patent by David Crane,
  European Patent Application # 84300730.3, dated 06.02.84:
  ---------------------------------------------------------------------------
  The twelve line address bus is connected to a plurality of 4K by eight bit
  memories.

  The eight line data bus is connected to each of the banks of memory, also.
  An address comparator is connected to the bus for detecting the presence of
  the 01FE address.  Actually, the comparator will detect only the lowest 12
  bits of 1FE, because of the twelve bit limitation of the address bus.  Upon
  detection of the 01FE address, a one cycle delay is activated which then
  actuates latch connected to the data bus.  The three most significant bits
  on the data bus are latched and provide the address bits A13, A14, and A15
  which are then applied to a 3 to 8 de-multiplexer.  The 3 bits A13-A15
  define a code for selecting one of the eight banks of memory which is used
  to enable one of the banks of memory by applying a control signal to the
  enable, EN, terminal thereof.  Accordingly, memory bank selection is
  accomplished from address codes on the data bus following a particular
  program instruction, such as a jump to subroutine.
  ---------------------------------------------------------------------------

  Note that in the general scheme, we use D7, D6 and D5 for the bank number
  (3 bits, so 8 possible banks).  However, the scheme as used historically
  by Activision only uses two banks.  Furthermore, the two banks it uses
  are actually indicated by binary 110 and 111, and translated as follows:

	binary 110 -> decimal 6 -> Upper 4K ROM (bank 1) @ $D000 - $DFFF
	binary 111 -> decimal 7 -> Lower 4K ROM (bank 0) @ $F000 - $FFFF

  Since the actual bank numbers (0 and 1) do not map directly to their
  respective bitstrings (7 and 6), we simply test for D5 being 0 or 1.
  This is the significance of the test '(value & 0x20) ? 0 : 1' in the code.

  NOTE: Consult the patent application for more specific information, in
		particular *why* the address $01FE will be placed on the address
		bus after both the JSR and RTS opcodes.

  @author  Stephen Anthony; with ideas/research from Christian Speckner and
		   alex_79 and TomSon (of AtariAge)
*/
void emulate_FE_cartridge()
{
	setup_cartridge_image();

	__disable_irq();	// Disable interrupts
	uint16_t addr, addr_prev = 0, data = 0, data_prev = 0;
	unsigned char *bankPtr = &cart_rom[0];
	int lastAccessWasFE = 0;

	while (1)
	{
		while ((addr = ADDR_IN) != addr_prev)
			addr_prev = addr;
		// got a stable address
		if (!(addr & 0x1000))
		{	// A12 low, read last data on the bus before the address lines change
			while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
			data = data_prev;//>>8;
		}
		else
		{ // A12 high
			data = bankPtr[addr&0xFFF];
			DATA_OUT = data;//<<8;
			SET_DATA_MODE_OUT
			// wait for address bus to change
			while (ADDR_IN == addr) ;
			SET_DATA_MODE_IN
		}
		// end of cycle
		if (lastAccessWasFE)
		{	// bank-switch - check the 5th bit of the data bus
			if (data & 0x20)
				bankPtr = &cart_rom[0];
			else
				bankPtr = &cart_rom[4 * 1024];
		}
		lastAccessWasFE = (addr == 0x01FE);
	}
	__enable_irq();
}

/* 3F (Tigervision) Bankswitching
 * ------------------------------
 * Generally 8K ROMs, containing 4 x 2K banks. The last bank is always mapped into
 * the upper part of the 4K cartridge ROM space. The bank mapped into the lower part
 * of the 4K cartridge ROM space is selected by the lowest two bits written to $003F
 * (or any lower address).
 * In theory this scheme supports up to 512k ROMs if we use all the bits written to
 * $003F - the code below should support up to MAX_CART_ROM_SIZE.
 *
 * Note - Stella restricts bank switching to only *WRITES* to $0000-$003f. But we
 * can't do this here and Miner 2049'er crashes (unless we restrict to $003f only).
 *
 * From an post by Eckhard Stolberg, it seems the switch would happen on a real cart
 * only when the access is followed by an access to an address between $1000 and $1FFF.
 *
 * 29/3/18 - The emulation below switches on access to $003f only, since the my prior
 * attempt at the banking scheme described by Eckhard Stolberg didn't work on a 7800.
 *
 * Refs:
 * http://atariage.com/forums/topic/266245-tigervision-banking-and-low-memory-reads/
 * http://atariage.com/forums/topic/68544-3f-bankswitching/
 */
void emulate_3F_cartridge()
{
	setup_cartridge_image();

	__disable_irq();	// Disable interrupts
	int cartPages = cart_size_bytes/2048;

	uint16_t addr, addr_prev = 0, addr_prev2 = 0, data = 0, data_prev = 0;
	unsigned char *bankPtr = &cart_rom[0];
	unsigned char *fixedPtr = &cart_rom[(cartPages-1)*2048];

	while (1)
	{
		while (((addr = ADDR_IN) != addr_prev) || (addr != addr_prev2))
		{	// new more robust test for stable address (seems to be needed for 7800)
			addr_prev2 = addr_prev;
			addr_prev = addr;
		}
		// got a stable address
		if (!(addr & 0x1000))
		{	// A12 low, read last data on the bus before the address lines change
			while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
			if (addr == 0x003F)
			{	// switch bank
				int newPage = (data_prev) % cartPages; //data_prev>>8
				bankPtr = &cart_rom[newPage*2048];
			}
		}
		else
		{ // A12 high
			if (addr & 0x800)
				DATA_OUT = ((uint16_t)fixedPtr[addr&0x7FF]);//<<8;
			else
				DATA_OUT = ((uint16_t)bankPtr[addr&0x7FF]);//<<8;
			SET_DATA_MODE_OUT
			// wait for address bus to change
			while (ADDR_IN == addr) ;
			SET_DATA_MODE_IN
		}
	}
	__enable_irq();
}

/* Scheme as described by Eckhard Stolberg. Didn't work on my test 7800, so replaced
 * by the simpler 3F only scheme above.
	while (1)
	{
		while ((addr = ADDR_IN) != addr_prev)
			addr_prev = addr;
		// got a stable address
		if (!(addr & 0x1000))
		{	// A12 low, read last data on the bus before the address lines change
			while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
			data = data_prev;//>>8;
			if (addr <= 0x003F) newPage = data % cartPages; else newPage = -1;
		}
		else
		{ // A12 high
			if (newPage >=0) {
				bankPtr = &cart_rom[newPage*2048];	// switch bank
				newPage = -1;
			}
			if (addr & 0x800)
				data = fixedPtr[addr&0x7FF];
			else
				data = bankPtr[addr&0x7FF];
			DATA_OUT = data;//<<8;
			SET_DATA_MODE_OUT
			// wait for address bus to change
			while (ADDR_IN == addr) ;
			SET_DATA_MODE_IN
		}
	}
 */

/* 3E (3F + RAM) Bankswitching
 * ------------------------------
 * This scheme supports up to 512k ROM and 256K RAM.
 * However here we only support up to MAX_CART_ROM_SIZE and MAX_CART_RAM_SIZE
 *
 * The text below is the best description of the mapping scheme I could find,
 * quoted from http://blog.kevtris.org/blogfiles/Atari%202600%20Mappers.txt
 */

/*
This works similar to 3F (Tigervision) above, except RAM has been added.  The range of
addresses has been restricted, too.  Only 3E and 3F can be written to now.

1000-17FF - this bank is selectable
1800-1FFF - this bank is the last 2K of the ROM

To select a particular 2K ROM bank, its number is poked into address 3F.  Because there's
8 bits, there's enough for 256 2K banks, or a maximum of 512K of ROM.

Writing to 3E, however, is what's new.  Writing here selects a 1K RAM bank into
1000-17FF.  The example (Boulderdash) uses 16K of RAM, however there's theoretically
enough space for 256K of RAM.  When RAM is selected, 1000-13FF is the read port while
1400-17FF is the write port.
*/
void emulate_3E_cartridge(int header_length, _Bool withPlusFunctions)
{
	setup_cartridge_image_with_ram();

	__disable_irq();	// Disable interrupts
	int cartROMPages = cart_size_bytes/2048;
	int cartRAMPages = 32;

	uint16_t addr, addr_prev = 0, addr_prev2 = 0, data = 0, data_prev = 0;
	unsigned char *bankPtr = &cart_rom[0];
	unsigned char *fixedPtr = &cart_rom[(cartROMPages-1)*2048];
	int bankIsRAM = 0;

	setup_plus_rom_functions();

	while (1)
	{
		while (((addr = ADDR_IN) != addr_prev) || (addr != addr_prev2))
		{	// new more robust test for stable address (seems to be needed for 7800)
			addr_prev2 = addr_prev;
			addr_prev = addr;
		}
		// got a stable address
		if (addr & 0x1000)
		{ // A12 high
			if (bankIsRAM && (addr & 0xC00) == 0x400)
			{	// we are accessing the RAM write addresses ($1400-$17FF)
				// read last data on the bus before the address lines change
				while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
				bankPtr[addr&0x3FF] = data_prev;//>>8;
	      }else if(addr == 0x1ff2 ){// read from receive buffer
	        DATA_OUT = ((uint16_t)receive_buffer[receive_buffer_read_pointer]);
	        SET_DATA_MODE_OUT
	        // if there is more data on the receive_buffer
	        if(receive_buffer_read_pointer != receive_buffer_write_pointer )
	          receive_buffer_read_pointer++;
	        // wait for address bus to change
	        while (ADDR_IN == addr){}
	        SET_DATA_MODE_IN
	      }else if(addr == 0x1ff1){ // write to send Buffer and start Request !!
	        while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
	        if(huart_state == No_Transmission)
	          huart_state = Send_Start;
	        out_buffer[out_buffer_write_pointer] = data_prev;//>>8;
	      }else if(addr == 0x1ff3){ // read receive Buffer length
	        DATA_OUT = (uint16_t) ((uint8_t)(receive_buffer_write_pointer - receive_buffer_read_pointer));
	        SET_DATA_MODE_OUT
	        // wait for address bus to change
	        while (ADDR_IN == addr){}
	        SET_DATA_MODE_IN
	      }else if(addr == 0x1ff0){ // write to send Buffer
	        while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
	        out_buffer[out_buffer_write_pointer++] = data_prev;

	      }else
			{	// reads to either ROM or RAM
				if (addr & 0x800)
				{	// upper 2k ($1800-$1FFF)
					data = fixedPtr[addr&0x7FF];	// upper 2k -> read fixed ROM bank
				}
				else
				{	// lower 2k ($1000-$17FF)
					if (!bankIsRAM)
						data = bankPtr[addr&0x7FF];	// read switching ROM bank
					else
						data = bankPtr[addr&0x3FF];	// must be RAM read
				}
				DATA_OUT = data;//<<8;
				SET_DATA_MODE_OUT
				// wait for address bus to change
				while (ADDR_IN == addr){process_transmission();}
				SET_DATA_MODE_IN
			}
		}
		else
		{	// A12 low, read last data on the bus before the address lines change
			while (ADDR_IN == addr) {
				data_prev = data; data = DATA_IN;
				process_transmission();
			}
			data = data_prev;//>>8;
			if (addr == 0x003F) {
				bankIsRAM = 0;
				bankPtr = &cart_rom[(data%cartROMPages)*2048];	// switch in ROM bank
			}
			else if (addr == 0x003E) {
				bankIsRAM = 1;
				bankPtr = &cart_ram[(data%cartRAMPages)*1024];	// switch in RAM bank
			}
		}
	}
	__enable_irq();
}

/* E0 Bankswitching
 * ------------------------------
 * The text below is the best description of the mapping scheme I could find,
 * quoted from http://blog.kevtris.org/blogfiles/Atari%202600%20Mappers.txt
 */

/*
Parker Brothers used this, and it was used on one other game (Tooth Protectors).  It
uses 8K of ROM and can map 1K sections of it.

This mapper has 4 1K banks of ROM in the address space.  The address space is broken up
into the following locations:

1000-13FF : To select a 1K ROM bank here, access 1FE0-1FE7 (1FE0 = select first 1K, etc)
1400-17FF : To select a 1K ROM bank, access 1FE8-1FEF
1800-1BFF : To select a 1K ROM bank, access 1FF0-1FF7
1C00-1FFF : This is fixed to the last 1K ROM bank of the 8K

Like F8, F6, etc. accessing one of the locations indicated will perform the switch.
*/
void emulate_E0_cartridge()
{
	setup_cartridge_image();

	__disable_irq();	// Disable interrupts
	uint16_t addr, addr_prev = 0;
	unsigned char curBanks[4] = {0,0,0,7};

	while (1)
	{
		while ((addr = ADDR_IN) != addr_prev)
			addr_prev = addr;
		// got a stable address
		if (addr & 0x1000)
		{ // A12 high

			if (addr >= 0x1FE0 && addr <= 0x1FF7)
			{	// bank-switching addresses
				if (addr <= 0x1FE7)	// switch 1st bank
					curBanks[0] = addr-0x1FE0;
				else if (addr >= 0x1FE8 && addr <= 0x1FEF)	// switch 2nd bank
					curBanks[1] = addr-0x1FE8;
				else if (addr >= 0x1FF0)	// switch 3rd bank
					curBanks[2] = addr-0x1FF0;
			}
			// fetch data from the correct bank
			int target = (addr & 0xC00) >> 10;
			DATA_OUT = ((uint16_t)cart_rom[curBanks[target]*1024 + (addr&0x3FF)]);//<<8;
			SET_DATA_MODE_OUT
			// wait for address bus to change
			while (ADDR_IN == addr) ;
			SET_DATA_MODE_IN
		}
	}
	__enable_irq();

}

/* 0840 Bankswitching
 * ------------------------------
 * 8k cartridge with two 4k banks.
 * The following description was derived from:
 * http://blog.kevtris.org/blogfiles/Atari%202600%20Mappers.txt
 *
 * Bankswitch triggered by access to an address matching the pattern below:
 *
 * A12		   A0
 * ----------------
 * 0 1xxx xBxx xxxx (x = don't care, B is the bank we select)
 *
 * If address AND $1840 == $0800, then we select bank 0
 * If address AND $1840 == $0840, then we select bank 1
 */
void emulate_0840_cartridge()
{
	setup_cartridge_image();

	__disable_irq();	// Disable interrupts
	uint16_t addr, addr_prev = 0, addr_prev2 = 0;
	unsigned char *bankPtr = &cart_rom[0];

	while (1)
	{
		while (((addr = ADDR_IN) != addr_prev) || (addr != addr_prev2))
		{	// new more robust test for stable address (seems to be needed for 7800)
			addr_prev2 = addr_prev;
			addr_prev = addr;
		}
		// got a stable address
		if (addr & 0x1000)
		{ // A12 high
			DATA_OUT = ((uint16_t)bankPtr[addr&0xFFF]);//<<8;
			SET_DATA_MODE_OUT
			// wait for address bus to change
			while (ADDR_IN == addr) ;
			SET_DATA_MODE_IN
		}
		else
		{
			if ((addr & 0x0840) == 0x0800) bankPtr = &cart_rom[0];
			else if ((addr & 0x0840) == 0x0840) bankPtr = &cart_rom[4*1024];
			// wait for address bus to change
			while (ADDR_IN == addr) ;
		}
	}
	__enable_irq();
}

/* CommaVid Cartridge
 * ------------------------------
 * 2K ROM + 1K RAM
 *  $F000-$F3FF 1K RAM read
 *  $F400-$F7FF 1K RAM write
 *  $F800-$FFFF 2K ROM
 */
void emulate_CV_cartridge()
{
	setup_cartridge_image_with_ram();

	__disable_irq();	// Disable interrupts
	uint16_t addr, addr_prev = 0, data = 0, data_prev = 0;

	while (1)
	{
		while ((addr = ADDR_IN) != addr_prev)
			addr_prev = addr;
		// got a stable address
		if (addr & 0x1000)
		{ // A12 high
			if (addr & 0x0800)
			{	// ROM read
				DATA_OUT = ((uint16_t)cart_rom[addr&0x7FF]);//<<8;
				SET_DATA_MODE_OUT
				// wait for address bus to change
				while (ADDR_IN == addr) ;
				SET_DATA_MODE_IN
			}
			else
			{	// RAM access
				if (addr & 0x0400)
				{	// a write to cartridge ram
					// read last data on the bus before the address lines change
					while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
					cart_ram[addr&0x3FF] = data_prev;//>>8;
				}
				else
				{	// a read from cartridge ram
					DATA_OUT = ((uint16_t)cart_ram[addr&0x3FF]);//<<8;
					SET_DATA_MODE_OUT
					// wait for address bus to change
					while (ADDR_IN == addr) ;
					SET_DATA_MODE_IN
				}
			}
		}
	}
	__enable_irq();
}

/* F0 Bankswitching
 * ------------------------------
 * 64K cartridge with 16 x 4K banks. An access to $1FF0 switches to the next
 * bank in sequence.
 */
void emulate_F0_cartridge()
{
	setup_cartridge_image();

	__disable_irq();	// Disable interrupts
	uint16_t addr, addr_prev = 0;
	int currentBank = 0;

	while (1)
	{
		while ((addr = ADDR_IN) != addr_prev)
			addr_prev = addr;
		// got a stable address
		if (addr & 0x1000)
		{ // A12 high
			if (addr == 0x1FF0)
				currentBank = (currentBank + 1) % 16;
			// ROM access
			DATA_OUT = ((uint16_t)cart_rom[(currentBank * 4096)+(addr&0xFFF)]);//<<8;
			SET_DATA_MODE_OUT
			// wait for address bus to change
			while (ADDR_IN == addr) ;
			SET_DATA_MODE_IN
		}
	}
	__enable_irq();
}

/* E7 Bankswitching
 * ------------------------------
 * 16K cartridge with additional RAM.
 * The text below is the best description of the mapping scheme I could find,
 * quoted from http://blog.kevtris.org/blogfiles/Atari%202600%20Mappers.txt
 */

/*
M-network wanted something of their own too, so they came up with what they called
"Big Game" (this was printed on the prototype ASICs on the prototype carts).  It
can handle up to 16K of ROM and 2K of RAM.

1000-17FF is selectable
1800-19FF is RAM
1A00-1FFF is fixed to the last 1.5K of ROM

Accessing 1FE0 through 1FE6 selects bank 0 through bank 6 of the ROM into 1000-17FF.
Accessing 1FE7 enables 1K of the 2K RAM, instead.

When the RAM is enabled, this 1K appears at 1000-17FF.  1000-13FF is the write port, 1400-17FF
is the read port.

1800-19FF also holds RAM. 1800-18FF is the write port, 1900-19FF is the read port.
Only 256 bytes of RAM is accessable at time, but there are four different 256 byte
banks making a total of 1K accessable here.

Accessing 1FE8 through 1FEB select which 256 byte bank shows up.
 */
void emulate_E7_cartridge()
{
	setup_cartridge_image_with_ram();

	__disable_irq();	// Disable interrupts
	uint16_t addr, addr_prev = 0, data = 0, data_prev = 0;
	unsigned char *bankPtr = &cart_rom[0];
	unsigned char *fixedPtr = &cart_rom[(8-1)*2048];
	unsigned char *ram1Ptr = &cart_ram[0];
	unsigned char *ram2Ptr = &cart_ram[1024];
	int ram_mode = 0;

	while (1)
	{
		while ((addr = ADDR_IN) != addr_prev)
			addr_prev = addr;
		// got a stable address
		if (addr & 0x1000)
		{ // A12 high
			if (addr & 0x0800)
			{	// higher 2k cartridge ROM area
				if ((addr & 0x0E00) == 0x0800)
				{	// 256 byte RAM access
					if (addr & 0x0100)
					{	// 1900-19FF is the read port
						DATA_OUT = ((uint16_t)ram1Ptr[addr&0xFF]);//<<8;
						SET_DATA_MODE_OUT
						// wait for address bus to change
						while (ADDR_IN == addr) ;
						SET_DATA_MODE_IN
					}
					else
					{	// 1800-18FF is the write port
						while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
						ram1Ptr[addr&0xFF] = data_prev;//>>8;
					}
				}
				else
				{	// fixed ROM bank access
					// check bankswitching addresses
					if (addr >= 0x1FE0 && addr <= 0x1FE7)
					{
						if (addr == 0x1FE7) ram_mode = 1;
						else
						{
							bankPtr = &cart_rom[(addr - 0x1FE0)*2048];
							ram_mode = 0;
						}
					}
					else if (addr >= 0x1FE8 && addr <= 0x1FEB)
						ram1Ptr = &cart_ram[(addr - 0x1FE8)*256];

					DATA_OUT = ((uint16_t)fixedPtr[addr&0x7FF]);//<<8;
					SET_DATA_MODE_OUT
					// wait for address bus to change
					while (ADDR_IN == addr) ;
					SET_DATA_MODE_IN
				}
			}
			else
			{	// lower 2k cartridge ROM area
				if (ram_mode)
				{	// 1K RAM access
					if (addr & 0x400)
					{	// 1400-17FF is the read port
						DATA_OUT = ((uint16_t)ram2Ptr[addr&0x3FF]);//<<8;
						SET_DATA_MODE_OUT
						// wait for address bus to change
						while (ADDR_IN == addr) ;
						SET_DATA_MODE_IN
					}
					else
					{	// 1000-13FF is the write port
						while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
						ram2Ptr[addr&0x3FF] = data_prev;//>>8;
					}
				}
				else
				{	// selected ROM bank access
					DATA_OUT = ((uint16_t)bankPtr[addr&0x7FF]);//<<8;
					SET_DATA_MODE_OUT
					// wait for address bus to change
					while (ADDR_IN == addr) ;
					SET_DATA_MODE_IN
				}
			}
		}
	}
	__enable_irq();
}

/* DPC (Pitfall II) Bankswitching
 * ------------------------------
 * Bankswitching like F8(8k)
 * DPC implementation based on:
 * - Stella (https://github.com/stella-emu) - CartDPC.cxx
 * - Kevin Horton's 2600 Mappers (http://blog.kevtris.org/blogfiles/Atari 2600 Mappers.txt)
 *
 * Note this is not a full implementation of DPC, but is enough to run Pitfall II and the music sounds ok.
 */

void emulate_DPC_cartridge()
{
	setup_cartridge_image();

	SysTick_Config(SystemCoreClock / 21000);	// 21KHz
	__disable_irq();	// Disable interrupts

	unsigned char prevRom = 0, prevRom2 = 0;
	int soundAmplitudeIndex = 0;
	unsigned char soundAmplitudes[8] = {0x00, 0x04, 0x05, 0x09, 0x06, 0x0a, 0x0b, 0x0f};

	uint16_t addr, addr_prev = 0, data = 0, data_prev = 0;
	unsigned char *bankPtr = &cart_rom[0], *DpcDisplayPtr = &cart_rom[8*1024];

	unsigned char DpcTops[8], DpcBottoms[8], DpcFlags[8];
	uint16_t DpcCounters[8];
	int DpcMusicModes[3], DpcMusicFlags[3];

	// Initialise the DPC's random number generator register (must be non-zero)
	int DpcRandom = 1;

	// Initialise the DPC registers
	for(int i = 0; i < 8; ++i)
		DpcTops[i] = DpcBottoms[i] = DpcCounters[i] = DpcFlags[i] = 0;

	DpcMusicModes[0] = DpcMusicModes[1] = DpcMusicModes[2] = 0;
	DpcMusicFlags[0] = DpcMusicFlags[1] = DpcMusicFlags[2] = 0;


	uint32_t lastSysTick = SysTick->VAL;
	uint32_t DpcClocks = 0;

	while (1)
	{
		while ((addr = ADDR_IN) != addr_prev)
			addr_prev = addr;

		// got a stable address
		if (addr & 0x1000)
		{ // A12 high

			if (addr < 0x1040)
			{	// DPC read
				int index = addr & 0x07;
				int function = (addr >> 3) & 0x07;

				// Update flag register for selected data fetcher
				if((DpcCounters[index] & 0x00ff) == DpcTops[index])
					DpcFlags[index] = 0xff;
				else if((DpcCounters[index] & 0x00ff) == DpcBottoms[index])
					DpcFlags[index] = 0x00;

				unsigned char result = 0;
				switch (function)
				{
					case 0x00:
					{
						if(index < 4)
						{	// random number read
							DpcRandom ^= DpcRandom << 3;
							DpcRandom ^= DpcRandom >> 5;
							result = (unsigned char)DpcRandom;
						}
						else
						{	// sound
							soundAmplitudeIndex = (DpcMusicModes[0] & DpcMusicFlags[0]);
							soundAmplitudeIndex |=  (DpcMusicModes[1] & DpcMusicFlags[1]);
							soundAmplitudeIndex |=  (DpcMusicModes[2] & DpcMusicFlags[2]);
							result = soundAmplitudes[soundAmplitudeIndex];;
						}
						break;
					}

					case 0x01:
					{	// DFx display data read
						result = DpcDisplayPtr[2047 - DpcCounters[index]];
						break;
					}

					case 0x02:
					{	// DFx display data read AND'd w/flag
						result = DpcDisplayPtr[2047 - DpcCounters[index]] & DpcFlags[index];
						break;
					}

					case 0x07:
					{	// DFx flag
						result = DpcFlags[index];
						break;
					}
				}

				DATA_OUT = ((uint16_t)result);
				SET_DATA_MODE_OUT
				// wait for address bus to change
				while (ADDR_IN == addr) ;
				SET_DATA_MODE_IN

				// Clock the selected data fetcher's counter if needed
				if ((index < 5) || ((index >= 5) && (!DpcMusicModes[index - 5])))
					DpcCounters[index] = (DpcCounters[index] - 1) & 0x07ff;
			}
			else if (addr < 0x1080)
			{	// DPC write
				int index = addr & 0x07;
				int function = (addr >> 3) & 0x07;

				while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
				unsigned char value = data_prev;
				switch (function)
				{
					case 0x00:
					{	// DFx top count
						DpcTops[index] = value;
						DpcFlags[index] = 0x00;
						break;
					}

					case 0x01:
					{	// DFx bottom count
						DpcBottoms[index] = value;
						break;
					}

					case 0x02:
					{	// DFx counter low
						DpcCounters[index] = (DpcCounters[index] & 0x0700) | value;
						break;
					}

					case 0x03:
					{	// DFx counter high
						DpcCounters[index] = ((uint16_t)(value & 0x07))  | (DpcCounters[index] & 0xff);
						if(index >= 5)
							DpcMusicModes[index - 5] = (value & 0x10) ? 0x7 : 0;
						break;
					}

					case 0x06:
					{	// Random Number Generator Reset
						DpcRandom = 1;
						break;
					}
				}
			}
			else
			{	// check bank-switch
				if (addr == 0x1FF8)
					bankPtr = &cart_rom[0];
				else if (addr == 0x1FF9)
					bankPtr = &cart_rom[4*1024];

				// normal rom access
				DATA_OUT = ((uint16_t)bankPtr[addr&0xFFF]);
				SET_DATA_MODE_OUT
				prevRom2 = prevRom;
				prevRom = bankPtr[addr&0xFFF];
				// wait for address bus to change
				while (ADDR_IN == addr) ;
				SET_DATA_MODE_IN
			}
		}
		else if((prevRom2 & 0xec) == 0x84) // Only do this when ZP write since there will be a full cycle available there
		{	// non cartridge access - e.g. sta wsync
			while (ADDR_IN == addr) {
				// should the DPC clock be incremented?
				uint32_t sysTick = SysTick->VAL;
				if (sysTick > lastSysTick)
				{	// the 21KHz clock has wrapped, so we increase the DPC clock
					DpcClocks++;
					// update the music flags here, since there isn't enough time when the music register
					// is being read.
					DpcMusicFlags[0] = (DpcClocks % (DpcTops[5] + 1))
							> DpcBottoms[5] ? 1 : 0;
					DpcMusicFlags[1] = (DpcClocks % (DpcTops[6] + 1))
							> DpcBottoms[6] ? 2 : 0;
					DpcMusicFlags[2] = (DpcClocks % (DpcTops[7] + 1))
							> DpcBottoms[7] ? 4 : 0;
				}
				lastSysTick = sysTick;
			}
		}
	}
	__enable_irq();
}

