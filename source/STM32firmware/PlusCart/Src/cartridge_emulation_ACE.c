#include <string.h>
#include <stdbool.h>
#include <stdio.h>
#include "flash.h"
#include "cartridge_emulation_ACE.h"
#include "cartridge_firmware.h"

#define ACE_MAJOR_REV 1
#define ACE_MINOR_REV 0
#define ACE_BUGFIX_REV 0


// Adapted from the Unocart ACE scheme by ZackAttack.
// ACE Implementation - For Pluscart. Adapted by Marco Johannes.
// Uses the same header format as the Unocart scheme, except with a uinque magic number for Pluscart.
// This header must exist at the beginning of every valid ACE file
// The bootloader automatically offsets the entry point if the user ROM is not at 0x0802000. For dynamic handling of user's offline rom storage.

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

	//Write to flash memory, or if offline ROM then run directly from flash.
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

	//Setup virtual arguments to be passed to ACE code in the beginning of buffer RAM. It is optional for the ACE application to use all of them though.
	uint32_t* buffer32 = (uint32_t*)(0x20000000); //Set up temporary buffer pointer for writing arguments
	*buffer32 = (uint32_t)cart_rom; //1. Declare the start position of the cart in flash as a 32 bit pointer. This changes depending on the state of the user's offline roms.
	buffer32++;
	*buffer32 = (uint32_t)(CCMPTR);//2. Declare the usage of CCM Memory so ACE application can use remainder, and not disturb the Pluscart variables.
	buffer32++;
	*buffer32 = (uint32_t)(&reboot_into_cartridge); //3. Pass Pluscart library function pointer for reboot_into_cartridge. Used for bootstrapping the 2600 system before running the ACE application.
	buffer32++;
	*buffer32 = (uint32_t)(&emulate_firmware_cartridge); //4. Pass Pluscart library function pointer for emulate_firmware_cartridge. Used to exit out of a 2600 rom and back into the Pluscart menu.
	buffer32++;
	*buffer32 = (uint32_t)(SystemCoreClock);//5. Pass the system clock frequency for time dependent functions.
	buffer32++;
	*buffer32 = (uint32_t)((ACE_MAJOR_REV<<16)+(ACE_MINOR_REV<<8)+ACE_BUGFIX_REV);//6. Pass the ACE Interface version number to the ACE application,encoded as  "00",major,minior,bugfix as a UINT32. The ACE code can then accept or reject compatibility before execution.
	buffer32++;
	*buffer32 = (uint32_t)((major<<16)+(minor<<8)+bugfix);//7. Pass the Pluscart Firmware version number to the ACE application,encoded as  "00",major,minior,bugfix as a UINT32. The ACE code can then accept or reject compatibility before execution.
	buffer32++;
	*buffer32 = (uint32_t)(0xACE42600);//8. Argument list termination magic number

//Stock code uses "EntryVector" below, this jumps to the function pointer set in the ACE header(and adjusted by the bootloader dependent on the state of offline roms).
//The ROM based ACE code has no arguments. However, "virtual" arguments are passed in the form of a uint32_t lookup table in buffer memory (0x20000000). It is optional for the ROM ace code to use all of the arguments.
//This arrangement exists so that the ARM stack is unchanged for future versions of ACE which might pass more virtual arguments. In c, functions need to have the exact same number and type of arguments in their library code as from the function that called them.
	
	return ((int (*)())EntryVector)(); /*Uncomment this line to run in ACE mode (code in ROM)*/
//	emulate_ACEROM_cartridge();  /*Uncomment this line to run in firmware mode(code in Pluscart fimrware) */

}