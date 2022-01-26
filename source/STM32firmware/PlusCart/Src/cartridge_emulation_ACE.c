#include <string.h>
#include <stdbool.h>
#include <stdio.h>
#include "flash.h"
#include "cartridge_emulation_ACE.h"
#include "cartridge_firmware.h"

// Adapted from the Unocart ACE scheme by ZackAttack.
// ACE Implementation - For Pluscart. Adapted by Marco Johannes.
// Uses the same header format as the Unocart scheme, except with a uinque magic number for Pluscart.
// This header must exist at the beginning of every valid ace file
// The bootloader automatically offsets the entry point if the user ROM is not at 0x0802000

typedef struct __attribute__((packed)) {
	uint8_t magic_number[8]; // Always ascii "ACE-PC00" for Pluscart ACE files
	uint8_t driver_name[16]; // emulators care about this
	uint32_t driver_version; // emulators care about this
	uint32_t rom_size;		 // size of ROM to be copied to flash, 996KB max
	uint32_t rom_checksum;	 // used to verify if flash already contains valid image
	uint32_t entry_point;	 // Absolute address of execution. This is 0x0802000 + the rom's ARM code segment offset.
} ACEFileHeader;

// ACE for Pluscart - Other forms of ACE are not supported and could do bad things
static const unsigned char MagicNumber[] = "ACE-PC00";

int is_pluscart_ace_cartridge(unsigned int image_size, uint8_t *buffer)
{
	if(image_size < sizeof(ACEFileHeader))
		return 0;


	ACEFileHeader * header = (ACEFileHeader *)buffer;
	if (header->rom_size > (896*1024)) return 0;

	// Check magic number
	for(int i = 0; i < 8; i++)
	{
		if(MagicNumber[i] != header->magic_number[i])
			return 0;
	}

	return 1;
}

int launch_ace_cartridge( const char* filename, uint32_t image_size, uint8_t* buffer, MENU_ENTRY *d,int header_length, bool withPlusFunctions, uint32_t* CCMPTR)
{

	ACEFileHeader header = *((ACEFileHeader *)buffer);

	uint8_t* cart_rom = 0; //Set NULL pointer for now
	void *EntryVector = 0; //Set NULL pointer for now

	//Write to flash memory, or if offline run directly from flash.
	if(d->type == Cart_File ){

#if USE_WIFI

		cart_rom = (uint8_t*)flash_download((char*)filename, d->filesize, 0, true); //Download whole game into the next flash sector.
		EntryVector = cart_rom - 0x08020200  + header.entry_point; //Adjust vector dependent on position in ROM
#else
		return 0;
#endif
	}else if(d->type == Offline_Cart_File ){

		cart_rom = (uint8_t*)(d->flash_base_address+512); //Rom from flash only (ignore RAM and CCM download), 512 = header for tar used in offline flash
		EntryVector = (void*)(d->flash_base_address+512 - 0x08020200  + header.entry_point);//Adjust vector dependent on position in ROM
	} else {

		return 0;
	}

    unsigned major = 0, minor = 0, bugfix = 0;
    sscanf(VERSION, "%u.%u.%u", &major, &minor, &bugfix); //Split up the Pluscart version number string into numeric form

	//Setup pointers to be passed to ACE code in the beginning of buffer RAM. It is optional for the ACE application to use them though.
	uint32_t* buffer32 = (uint32_t*)(0x20000000); //Create 32-bit pointer to buffer memory
	*buffer32 = (uint32_t)cart_rom; //Declare the start position of the cart in flash. This changes depending on the state of the user's offline roms.
	buffer32++;
	*buffer32 = (uint32_t)(CCMPTR);//Declare the usage of CCM Memory so ACE application can use remainder, and not disturb the pluscart variables.
	buffer32++;
	*buffer32 = (uint32_t)(&reboot_into_cartridge); //Pass function pointer for reboot_into_cartridge
	buffer32++;
	*buffer32 = (uint32_t)(&emulate_firmware_cartridge); //Pass function pointer for emulate_firmware_cartridge
	buffer32++;
	*buffer32 = (uint32_t)(SystemCoreClock);//Pass the system clock frequency for time dependent functions
	buffer32++;
	*buffer32 = (uint32_t)((major<<16)+(minor<<8)+bugfix);//Pass the Pluscart Firmware version number to the ACE application,encoded as  "00",major,minior,bugfix as a UINT32.
	
//Stock code uses "EntryVector" below. Use emulate_ACEROM_cartridge for potentially quicker test cycle for ACE code in test firmware.
	((void (*)())EntryVector)(); /*Uncomment this line to run in ACE mode (code in ROM)*/
//	emulate_ACEROM_cartridge();  /*Uncomment this line to run in firmware mode(code in Pluscart fimrware) */

	return 1;
}
