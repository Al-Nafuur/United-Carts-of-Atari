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

#include <stdlib.h>
#include <stdbool.h>
#include "cartridge_emulation.h"
#include "cartridge_setup.h"
#include "cartridge_emulation_3F.h"
#include "cartridge_firmware.h"

void emulate_3F_cartridge( const char* filename, uint32_t image_size, uint8_t* buffer, MENU_ENTRY *d)
{
/*	setup_cartridge_image();
	if (cart_size_bytes > 0x010000) return;
	uint8_t* cart_rom = buffer;
*/
	cartridge_layout * layout = (cartridge_layout *) malloc( sizeof(  cartridge_layout ));

    if (!setup_cartridge_image(filename, image_size, buffer, layout, d, base_type_3F)) return;


//    uint8_t banks = (uint8_t)(( image_size / 2048 ) - 1);
//    uint8_t *bank = layout->banks[banks];

	int cartPages = (int) image_size/2048;
	uint16_t addr, addr_prev = 0, addr_prev2 = 0;
	uint8_t data = 0, data_prev = 0;
	unsigned char *bankPtr = layout->banks[0];
	unsigned char *fixedPtr = layout->banks[cartPages-1];
	bool joy_status = false;

	if (!reboot_into_cartridge()) return;
	__disable_irq();	// Disable interrupts

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
			if (addr & 0x800)
				DATA_OUT = fixedPtr[addr&0x7FF];
			else
				DATA_OUT = bankPtr[addr&0x7FF];
			SET_DATA_MODE_OUT
			// wait for address bus to change
			while (ADDR_IN == addr) ;
			SET_DATA_MODE_IN
		}
		else
		{	// A12 low, read last data on the bus before the address lines change
			if (addr == 0x003F)
			{	// switch bank
				while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
				//int newPage = data_prev % cartPages; //data_prev>>8
				bankPtr = layout->banks[data_prev % cartPages];
			}
			else if(addr == EXIT_SWCHB_ADDR){
				while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
				if( !(data_prev & 0x1) && joy_status)
					break;
			}else if(addr == SWCHA){
				while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
				joy_status = !(data_prev & 0x80);
			}
		}
	}

	exit_cartridge(addr, addr_prev);
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
			data = data_prev;
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
			DATA_OUT = data;
			SET_DATA_MODE_OUT
			// wait for address bus to change
			while (ADDR_IN == addr) ;
			SET_DATA_MODE_IN
		}
	}
 */
