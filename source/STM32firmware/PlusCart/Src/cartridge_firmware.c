#include <string.h>

#include "cartridge_firmware.h"

#include "firmware_pal_rom.h"
#include "firmware_pal60_rom.h"
#include "firmware_ntsc_rom.h"
#include "font.h"

// These are the colours between the top title bar and the rest of the text lines...

#define BACK_COL_NTSC     0x92
#define BACK_COL_PAL      0xb2

#define t2c(fontType, l, r, s) \
	sharedFont[ convertAsciiToCharnum(fontType, l) * 12 + s ] << 4 | \
	sharedFont[ convertAsciiToCharnum(fontType, r) * 12 + s ]


static char menu_header[32]__attribute__((section(".ccmram")));
static char menu_status[7]__attribute__((section(".ccmram")));
static unsigned const char *firmware_rom = firmware_ntsc_rom;


const uint8_t start_bank[]__attribute__((section(".flash01")))   = { 0xd8, 0x8d, 0xf4, 0xff, 0x4c, 0x37, 0x12, 0x9d, 0xf5, 0xff };
const uint8_t end_bank[] __attribute__((section(".flash01")))    = { 0x8d, 0xf4, 0xff, 0x4c, 0x43, 0x10, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0a, 0x10, 0x0a, 0x10 };

const uint8_t switch_bank[]__attribute__((section(".flash01")))  = { 0x4c, 0x07, 0x10};

// with VCS RAM Color
const uint8_t textline_start_even[]__attribute__((section(".flash01"))) = { 0xa5, 0x83, 0x85, 0x09, 0xa9, 0x0c, 0x8d, 0x06, 0x00, 0xea};
const uint8_t textline_start_odd[]__attribute__((section(".flash01")))  = { 0x85, 0x2a, 0xa5, 0x83, 0x85, 0x09, 0xa9, 0x0c, 0xea, 0x85, 0x07};


const uint8_t next_scanline_a[]__attribute__((section(".flash01"))) = { 0x85, 0x2a, 0x04, 0x00, 0xea, 0xea, 0xea, 0xea, 0xea};
const uint8_t next_scanline_b[]__attribute__((section(".flash01"))) = { 0xea, 0xea, 0xea, 0xea, 0xea, 0xea, 0xea};
const uint8_t kernel_a[]__attribute__((section(".flash01"))) = { 0xa2, 0x30, 0xa9, 0x10, 0x85, 0x1c, 0xa9, 0x60, 0x85, 0x1b, 0xa0, 0x00, 0x8e, 0x1b, 0x00, 0xea, 0xa2, 0x04, 0xa9, 0x00, 0x85, 0x1c, 0xa9, 0x80, 0x8d, 0x1c, 0x00, 0x85, 0x10, 0x84, 0x1b, 0x85, 0x10,0x8e, 0x1b, 0x00, 0xa9, 0xce, 0x8d, 0x1b, 0x00, 0xa2, 0x80, 0x86, 0x21, 0xea, 0x85, 0x10};
const uint8_t kernel_b[]__attribute__((section(".flash01"))) = { 0xa0, 0x03, 0xa9, 0x60, 0x85, 0x1c, 0xa2, 0x03, 0xa9, 0x77, 0x85, 0x1b, 0xa9, 0x52, 0x85, 0x1b, 0xa9, 0x50, 0x8d, 0x1b, 0x00, 0x86, 0x1c, 0x85, 0x10, 0x84, 0x1c, 0x85, 0x10, 0xa9, 0x1f, 0x8d, 0x1b, 0x00, 0xa9, 0x74, 0x85, 0x1b, 0xa2, 0x00, 0x86, 0x21, 0x8d, 0x2a, 0x00, 0x85, 0x10};

const uint8_t header_bottom[]__attribute__((section(".flash01")))   = { 0x85, 0x02, 0xa9, 0xb2, 0x85, 0x02, 0x85, 0x09, 0x85, 0x02, 0x85, 0x02, 0x85, 0x02, 0x85, 0x09, 0x85, 0x02, /*0x85, 0x02, 0x85, 0x02, 0x85, 0x02*/ };
const uint8_t normal_bottom[]__attribute__((section(".flash01")))   = { 0x85, 0x02 };
const uint8_t normal_top[]__attribute__((section(".flash01")))      = { 0x85, 0x02 /*, 0x85, 0x02*/ };
const uint8_t exit_kernel[]__attribute__((section(".flash01")))     = { 0x4c, 0x00, 0x10};
const uint8_t end_kernel_even[]__attribute__((section(".flash01"))) = { 0x86, 0x1b, 0x86, 0x1c};
const uint8_t end_kernel_odd[]__attribute__((section(".flash01")))  = { 0xa2, 0x00};

uint8_t * my_font;

uint8_t * bufferp;


void inline add_end_kernel(bool is_even);
void inline add_next_scanline(bool is_a);
void inline add_start_bank(int bank_id);
void inline add_end_bank(int bank_id);
void inline add_textline_start(bool even, uint8_t entry, bool isFolder);
void inline add_kernel_a(uint8_t fontType, uint8_t scanline, uint8_t * text);
void inline add_kernel_b(uint8_t fontType, uint8_t scanline, uint8_t * text);
void inline add_header_bottom();
void inline add_normal_bottom();
void inline add_normal_top();
void inline add_exit_kernel();




/*
 * Functions to append to the buffer the const "templates"
 * and fill in the dynamic values
 */
void add_start_bank(int bank_id){
    bufferp =  &buffer[ (bank_id - 1) * 0x1000];
    memcpy( bufferp, start_bank, sizeof(start_bank));
    bufferp[8] += bank_id;
    bufferp += sizeof(start_bank);
}

void add_end_bank(int bank_id){
    uint16_t next_bank = 0x1000 * bank_id ;
    memcpy( bufferp, switch_bank, sizeof(switch_bank));
    bufferp = &buffer[ next_bank - 0x12];
    memcpy( bufferp, end_bank, sizeof(end_bank));
}

void add_textline_start(bool even, uint8_t entry, bool isFolder){
    if(even){
        memcpy( bufferp, textline_start_even, sizeof(textline_start_even));
        bufferp[1]  += entry;
        if(isFolder) bufferp[5] = 0x0e;
        bufferp += sizeof(textline_start_even);
    } else {
        memcpy( bufferp, textline_start_odd, sizeof(textline_start_odd));
        bufferp[3]  += entry;
        if(isFolder) bufferp[7] = 0x0e;
        bufferp += sizeof(textline_start_odd);
    }
}

//displays: 00--00--11--11--11----00--00--00
void add_kernel_a(uint8_t fontType, uint8_t scanline, uint8_t * text){
    memcpy( bufferp, kernel_a, sizeof(kernel_a));

    if (fontType > 3)
    	fontType = 0;				// cater for uninit'd font

    bufferp[1]  = t2c(fontType, text[4], text[5], scanline);          // #{3}
    bufferp[3]  = t2c(fontType, text[8], text[9], scanline);          // #{4}
    bufferp[7]  = t2c(fontType, text[0], text[1], scanline);          // #{2}
    bufferp[11] = (t2c(fontType, text[22], text[23], scanline)) << 1; // #{7} << 1
    bufferp[17] = (t2c(fontType, text[26], text[27], scanline)) << 1; // #{8} << 1
    bufferp[19] = t2c(fontType, text[12], text[13], scanline);        // #{5}
    bufferp[23] = t2c(fontType, text[16], text[17], scanline);        // #{6}
    bufferp[37] = (t2c(fontType, text[30], text[31], scanline)) << 1; // #{9} << 1

    bufferp += sizeof(kernel_a);
}

//displays: --00--00--11--11--1100--00--00--
void add_kernel_b(uint8_t fontType, uint8_t scanline, uint8_t * text){
    memcpy( bufferp, kernel_b, sizeof(kernel_b));

    if (fontType > 3)
    	fontType = 0;				// cater for uninit'd font

    bufferp[1]  = t2c(fontType, text[18], text[19], scanline);        // #{6}
    bufferp[3]  = t2c(fontType, text[10], text[11], scanline);        // #{4}
    bufferp[7]  = t2c(fontType, text[14], text[15], scanline);        // #{5}
    bufferp[9]  = t2c(fontType, text[2], text[3], scanline);          // #{2}
    bufferp[13] = t2c(fontType, text[6], text[7], scanline);          // #{3}
    bufferp[17] = t2c(fontType, text[20], text[21], scanline);        // #{7}
    bufferp[30] = t2c(fontType, text[24], text[25], scanline);        // #{8}
    bufferp[35] = t2c(fontType, text[28], text[29], scanline);        // #{9}

    bufferp += sizeof(kernel_b);
}

void add_end_kernel(bool is_even){
    if(! is_even){
        memcpy( bufferp, end_kernel_odd, sizeof(end_kernel_odd));
        bufferp += sizeof(end_kernel_odd);
    }
    memcpy( bufferp, end_kernel_even, sizeof(end_kernel_even));
    bufferp += sizeof(end_kernel_even);
}

void add_next_scanline(bool is_a){
    if(is_a){
        memcpy( bufferp, next_scanline_a, sizeof(next_scanline_a));
        bufferp += sizeof(next_scanline_a);
    }else{
        memcpy( bufferp, next_scanline_b, sizeof(next_scanline_b));
        bufferp += sizeof(next_scanline_b);
    }
}

void add_header_bottom(){
    memcpy( bufferp, header_bottom, sizeof(header_bottom));
    if(user_settings.tv_mode == TV_MODE_NTSC)
    	bufferp[3] = BACK_COL_NTSC;

    bufferp += sizeof(header_bottom);
}

void add_normal_bottom(){
    memcpy( bufferp, normal_bottom, sizeof(normal_bottom));
    bufferp += sizeof(normal_bottom);
}
void add_normal_top(){
    memcpy( bufferp, normal_top, sizeof(normal_top));
    bufferp += sizeof(normal_top);
}
void add_exit_kernel(){
    memcpy( bufferp, exit_kernel, sizeof(exit_kernel));
    bufferp += sizeof(exit_kernel);
}

void createMenuForAtari( MENU_ENTRY * menu_entries, uint8_t page_id, int num_menu_entries, bool paging_required, bool is_connected, uint8_t * plus_store_status){
	// create 7 banks of bytecode for the ATARI to execute.

	uint8_t menu_string[32];
    uint8_t bank = 1, sc, entry, odd_even, str_len;
    uint8_t max_page = (num_menu_entries - 1) / NUM_MENU_ITEMS_PER_PAGE;
    uint8_t items_on_last_page = (num_menu_entries % NUM_MENU_ITEMS_PER_PAGE) ? (num_menu_entries % NUM_MENU_ITEMS_PER_PAGE) : NUM_MENU_ITEMS_PER_PAGE;
    uint8_t items_on_act_page = (page_id < max_page) ? NUM_MENU_ITEMS_PER_PAGE : items_on_last_page;
    bufferp = &buffer[0];
	memset(buffer, 0xff, 28*1024);
    unsigned int offset = NUM_MENU_ITEMS_PER_PAGE * page_id;

	set_menu_status_byte(CurPage, (char)page_id);
	set_menu_status_byte(MaxPage, (char)max_page);
	set_menu_status_byte(ItemsOnActPage, (char)items_on_act_page);
    if( max_page > 0 ){
    	uint8_t i = STATUS_MESSAGE_LENGTH - 1;
    	max_page++;
        while(max_page != 0) {
            menu_header[i--] =  (max_page % 10) + '0';
            max_page = max_page/10;
        }
    	menu_header[i--] = '/';

    	page_id++;
        while(page_id != 0) {
        	menu_header[i--] =  (page_id % 10) + '0';
        	page_id = page_id/10;
        }
        if(i % 2 == 0)
        	menu_header[i--] = ' ';
    	menu_header[i--] = CHAR_R_Page;
    	menu_header[i] = CHAR_L_Page;
    }
    if(is_connected == true){
    	menu_header[STATUS_MESSAGE_LENGTH + 1] = CHAR_L_Wifi;
    	menu_header[STATUS_MESSAGE_LENGTH + 2] = CHAR_R_Wifi;
    }else{
    	menu_header[STATUS_MESSAGE_LENGTH + 1] = CHAR_L_NoWifi; //CHAR_L_NoWifi;
    	menu_header[STATUS_MESSAGE_LENGTH + 2] = CHAR_R_NoWifi; //CHAR_R_NoWifi;
    }
    if(plus_store_status[0] == '1'){
    	menu_header[STATUS_MESSAGE_LENGTH + 3] = CHAR_L_Account;
    	menu_header[STATUS_MESSAGE_LENGTH + 4] = CHAR_R_Account;
    }else{
    	menu_header[STATUS_MESSAGE_LENGTH + 3] = CHAR_L_NoAccount;
    	menu_header[STATUS_MESSAGE_LENGTH + 4] = CHAR_R_NoAccount;
    }


	add_start_bank(bank);
	for( odd_even = 0; odd_even < 2; odd_even++){
        memcpy( bufferp, normal_bottom, sizeof(normal_bottom));
        bufferp += sizeof(normal_bottom);

       	for ( entry = 0; entry < (NUM_MENU_ITEMS_PER_PAGE + 1); entry++){
            bool is_kernel_a = bank < 4, isFolder = false;
            int list_entry = entry + offset - 1;
            if(entry == 0){
                memcpy(menu_string, menu_header, 32);

                // TITLE BAR - set to user font -- OR hardwire to specific font if required
                menu_entries[offset - 1].font = FONT_TJZ; // user_settings.font_style; // <-- OR, font # hardwire
                isFolder = true;
            }else if(list_entry < num_menu_entries){
            	str_len = strlen(menu_entries[list_entry].entryname);
                memcpy(menu_string, menu_entries[list_entry].entryname, str_len);
            	memset(&menu_string[str_len], ' ', (32 - str_len));
            	isFolder = ( menu_entries[list_entry].type != Offline_Cart_File && menu_entries[list_entry].type != Cart_File );
            }else{
            	memset(menu_string, ' ', 32);
            }
    		for (uint8_t i=0; i < 32; i++) {
    			if(menu_string[i] < 32 || menu_string[i] > HIGHEST_ASCII_CHAR)
    				menu_string[i] = 32;
    		}
            add_textline_start(is_kernel_a , entry, isFolder);
            for (sc = 0; sc < CHAR_HEIGHT; sc++){
                if(is_kernel_a){
                    add_kernel_a(menu_entries[list_entry].font, sc,  menu_string );
                }else{
                    add_kernel_b(menu_entries[list_entry].font, sc, menu_string );
                }
                if(sc<11)
                    add_next_scanline(is_kernel_a);

                is_kernel_a = ! is_kernel_a;
        	}
        	add_end_kernel(is_kernel_a);

        	if( entry == 0){
        	    add_header_bottom();
        	} else if(entry == 4 || entry == 9 || entry == 12 ){
                if(entry > 4){
        	        add_normal_bottom();
        	        if(entry == 12){
        	            add_exit_kernel();
        	        }
                }
                add_end_bank(bank);
                bank++;

                add_start_bank(bank);
                if(entry == 4){
        	        add_normal_bottom();
                }
                if(entry != 12)
        	        add_normal_top();

            } else {
        	    add_normal_bottom();
        	    add_normal_top();
        	}
    	}
	}
    add_end_bank(bank);
}





void set_menu_status_msg(const char* message) {
	uint8_t msg_len = strlen(message);
    memset(menu_header, ' ', 32 );
	menu_header[0] = '\0';
    strncat(menu_header, message, STATUS_MESSAGE_LENGTH);
    if(msg_len < STATUS_MESSAGE_LENGTH)
    	menu_header[msg_len] = 32;
}

void set_menu_status_byte(uint8_t byte_id, char status_byte) {
	menu_status[byte_id] = status_byte;
}

void set_tv_mode(int tv_mode) {
	switch (tv_mode) {
		case TV_MODE_NTSC:
			firmware_rom = firmware_ntsc_rom;
			break;

		case TV_MODE_PAL:
			firmware_rom = firmware_pal_rom;
			break;

		case TV_MODE_PAL60:
			firmware_rom = firmware_pal60_rom;
			break;
	}
}

//void set_my_font(int new_font) {
//	my_font = (uint8_t *)font[new_font];
//}

// We require the menu to do a write to $1FF4 to unlock the comms area.
// This is because the 7800 bios accesses this area on console startup, and we wish to ignore these
// spurious reads until it has started the cartridge in 2600 mode.
bool comms_enabled = false;

int emulate_firmware_cartridge() {
	__disable_irq();	// Disable interrupts
	uint16_t addr, addr_prev = 0;
	uint8_t data = 0, data_prev = 0;
	unsigned const char *bankPtr = &firmware_rom[0];
	while (1)
	{
		while ((addr = ADDR_IN) != addr_prev)
			addr_prev = addr;
		// got a stable address
		if (addr & 0x1000)
		{ // A12 high
			if (comms_enabled)
			{	// normal mode, once the cartridge code has done its init.
				// on a 7800, we know we are in 2600 mode now.
				if (addr > 0x1FF4 && addr <= 0x1FFB){	// bank-switch
					bankPtr = &buffer[(addr-0x1FF5)*4*1024];
					DATA_OUT = ((uint16_t)bankPtr[addr&0xFFF]);
				}else if (addr == 0x1FF4){
					bankPtr = &firmware_rom[0];
					DATA_OUT = ((uint16_t)bankPtr[addr&0xFFF]);
				}else if (addr == CART_CMD_HOTSPOT){	// atari 2600 has send an command
					while (ADDR_IN == addr) { data_prev = data; data = DATA_IN; }
					addr = data_prev;
					break;
				}else if(addr > CART_STATUS_BYTES_START - 1 && addr < CART_STATUS_BYTES_END + 1 ){
					DATA_OUT = ((uint16_t)menu_status[addr - CART_STATUS_BYTES_START]);
				}else if(addr > CART_STATUS_BYTES_END ){
					DATA_OUT = ((uint16_t)end_bank[addr - (CART_STATUS_BYTES_END + 1)]);
				}else{
					DATA_OUT = ((uint16_t)bankPtr[addr&0xFFF]);
				}
				SET_DATA_MODE_OUT
				// wait for address bus to change
				while (ADDR_IN == addr) ;
				SET_DATA_MODE_IN
			}
			else
			{	// prior to an access to $1FF4, we might be running on a 7800 with the CPU at
				// ~1.8MHz so we've got less time than usual - keep this short.
				if(addr > CART_STATUS_BYTES_END ){
					DATA_OUT = ((uint16_t)end_bank[addr - (CART_STATUS_BYTES_END + 1)]);
				}else {
					DATA_OUT = ((uint16_t)bankPtr[addr&0xFFF]);
				}
				SET_DATA_MODE_OUT
				// wait for address bus to change
				while (ADDR_IN == addr) ;
				SET_DATA_MODE_IN

				if (addr == 0x1FF4) // we should move this comm enable hotspot because it is in the bankswitch area..
					comms_enabled = true;
			}
		}
	}

	__enable_irq();
	return addr;
}

bool reboot_into_cartridge() {
	set_menu_status_byte(StatusByteReboot, 1);

	return emulate_firmware_cartridge() == CART_CMD_START_CART;
}
