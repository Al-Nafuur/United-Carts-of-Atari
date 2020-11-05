#include <string.h>

#include "cartridge_firmware.h"

#include "firmware_pal_rom.h"
#include "firmware_pal60_rom.h"
#include "firmware_ntsc_rom.h"
#include "font.h"
#include "global.h"


#define PATCH 0

// These are the colours between the top title bar and the rest of the text lines...

#define BACK_COL_NTSC     0x92
#define BACK_COL_PAL      0xD4

#define HEADER_BACK_COL_NTSC     0x20
#define HEADER_BACK_COL_PAL      0x40

#define t2c(fontType, l, r, s) \
	(uint8_t)(sharedFont[ convertAsciiToCharnum(fontType, l) * 12 + s ] << 4 | \
	sharedFont[ convertAsciiToCharnum(fontType, r) * 12 + s ])


static char menu_header[CHARS_PER_LINE/* + 2*/]__attribute__((section(".ccmram")));
static unsigned char menu_status[STATUS_MAX]__attribute__((section(".ccmram")));
static unsigned const char *firmware_rom = firmware_ntsc_rom;

const uint8_t start_bank[]__attribute__((section(".flash01"))) = {
#define PATCH_START_BANK 8

		0xd8,					// cld
		0x8d, 0xf4, 0xff,		// sta HOTSPOT
		0x4c, 0x37, 0x12,		// jmp ContDrawScreen
		0x9d, 0xf5, 0xff// sta $FFF5,x					*** PATCH LOW BYTE OF ADDRESS ***

		};

const uint8_t end_bank[] __attribute__((section(".flash01"))) = {

		0x8d, 0xf4, 0xff,		// sta HOTSPOT
		0x4c, 0x43, 0x10,		// jmp $1043					???

		0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0a, 0x10, 0x0a, 0x10	// ??
	};

const uint8_t switch_bank[]__attribute__((section(".flash01"))) = {

0x4c, 0x07, 0x10		// jmp SwitchBank

		};


const uint8_t textline_start_even[]__attribute__((section(".flash01"))) = {
#define PATCH_EVEN_LINE_BACKCOL 1

		0xa5, PATCH,			// lda PATCH  ($83+entry)		(*** PATCHED ***)
		0x85, 0x09,				// sta COLUBK

	//		SLEEP 8

		0xea,
		0xea,
		0xea,
		0xea,
	};

const uint8_t textline_start_odd[]__attribute__((section(".flash01"))) = {
#define PATCH_LINE_BACKCOL 3

		0x85, 0x2a,				// sta HMOVE
		0xa5, PATCH,			// lda PATCH  ($83+entry)		(*** PATCHED ***)
		0x85, 0x09,				// sta COLUBK

		0x04, 0x00,				// nop 0			SLEEP 7
		0xea,					// nop
		0xea,					// nop
	};

const uint8_t next_scanline_a[]__attribute__((section(".flash01"))) = {

		0x85, 0x2a,				// sta HMOVE

		0x04, 0x00,				// nop 0			SLEEP 13
		0xea,					// nop
		0xea,					// nop
		0xea,					// nop
		0xea,					// nop
		0xea					// nop
	};

const uint8_t next_scanline_b[]__attribute__((section(".flash01"))) = {

		0xea,					// nop				SLEEP 14
		0xea,					// nop
		0xea,					// nop
		0xea,					// nop
		0xea,					// nop
		0xea,					// nop
		0xea					// nop
	};

const uint8_t kernel_a[]__attribute__((section(".flash01"))) = {

#define PATCH_A_1	1
#define PATCH_A_2 	3
#define PATCH_A_3 	7
#define PATCH_A_4 	11
#define PATCH_A_5 	17
#define PATCH_A_6 	19
#define PATCH_A_7 	23
#define PATCH_A_8 	37

		0xa2, PATCH,			// ldx #??			(*** PATCHED ***) @1
		0xa9, PATCH,			// lda #??			(*** PATCHED ***) @3
		0x85, 0x1c,				// sta GRP1
		0xa9, PATCH,			// lda #??			(*** PATCHED ***) @7
		0x85, 0x1b,				// sta GRP0
		0xa0, PATCH,			// ldy #??			(*** PATCHED ***) @11
		0x8e, 0x1b, 0x00,		// stx.w GRP0
		0xea,					// nop
		0xa2, PATCH,			// ldx #??			(*** PATCHED ***) @17
		0xa9, PATCH,			// lda #??			(*** PATCHED ***) @19
		0x85, 0x1c,				// sta GRP0
		0xa9, PATCH,			// lda #??			(*** PATCHED ***) @23
		0x8d, 0x1c, 0x00,		// sta GRP0
		0x85, 0x10,				// sta RESP0
		0x84, 0x1b,				// sty GRP0
		0x85, 0x10,				// sta RESP0
		0x8e, 0x1b, 0x00,		// stx.w GRP0
		0xa9, PATCH,			// lda #??			(*** PATCHED ***) @37
		0x8d, 0x1b, 0x00,		// sta GRP0
		0xa2, 0x80,				// ldx #$80
		0x86, 0x21,				// stx HMP1
		0xea,					// nop
		0x85, 0x10				// sta RESP0
		};

const uint8_t kernel_b[]__attribute__((section(".flash01"))) = {

#define PATCH_B_1 	1
#define PATCH_B_2	3
#define PATCH_B_3	7
#define PATCH_B_4	9
#define PATCH_B_5	13
#define PATCH_B_6	17
#define PATCH_B_7	30
#define PATCH_B_8	35

		0xa0, PATCH,			// ldy #??			(*** PATCHED ***) @1
		0xa9, PATCH,			// lda #??			(*** PATCHED ***) @3
		0x85, 0x1c,				// sta GRP1
		0xa2, PATCH,			// ldx #??			(*** PATCHED ***) @7
		0xa9, PATCH,			// lda #??			(*** PATCHED ***) @9
		0x85, 0x1b,				// sta GRP0
		0xa9, PATCH,			// lda #??			(*** PATCHED ***) @13
		0x85, 0x1b,				// sta GRP0
		0xa9, PATCH,			// lda #??			(*** PATCHED ***) @17
		0x8d, 0x1b, 0x00,		// sta GRP0
		0x86, 0x1c,				// stx GRP1
		0x85, 0x10,				// sta RESP0
		0x84, 0x1c,				// sty GRP0
		0x85, 0x10,				// sta RESP0
		0xa9, PATCH,			// lda #??			(*** PATCHED ***) @30
		0x8d, 0x1b, 0x00,		// sta GRP0
		0xa9, PATCH,			// lda #??			(*** PATCHED ***) @35
		0x85, 0x1b,				// sta GRP0
		0xa2, 0x00,				// ldx #0
		0x86, 0x21,				// stx HMP1
		0x8d, 0x2a, 0x00,		// sta HMOVE
		0x85, 0x10				// sta RESP0
		};

const uint8_t header_bottom[]__attribute__((section(".flash01"))) = {
#define PATCH_HEADER_BOTTOM_BACKGROUND_COLOUR 1
#define PATCH_HEADER_BOTTOM_TEXT_COLOUR 17

		0xa9, PATCH,			// lda #PATCHED BACK_COL	(*** PATCHED ***)
		0x85, 0x02,				// sta WSYNC
		0x85, 0x09,				// sta COLUBK

		0x85, 0x02,				// sta WSYNC
		0x85, 0x02,				// sta WSYNC
		0x85, 0x02,				// sta WSYNC
		0x85, 0x02,				// sta WSYNC
		0x85, 0x02,				// sta WSYNC

		0xa9, PATCH,			// lda #PATCHED TEXT_COL	(*** PATCHED ***)
		0x85, 0x06,				// sta COLUP0
		0x85, 0x07,				// sta COLUP1

		0x85, 0x02				// sta WSYNC
		};

const uint8_t normal_bottom[]__attribute__((section(".flash01"))) = {
	};

const uint8_t wsync[]__attribute__((section(".flash01"))) = { 0x85, 0x02// sta WSYNC
		};

const uint8_t text_colour[]__attribute__((section(".flash01"))) = {

#define PATCH_TEXT_COLOUR 1

		0xa9, 0x00,				// lda #??			 (*** PATCHED ***)
		0x85, 0x06,				// sta COLUP0
		0x85, 0x07				// sta COLUP1
		};

const uint8_t normal_top[]__attribute__((section(".flash01"))) = {
#define PATCH_NORMAL_TOP_TEXT_COLOUR 1

		0xa9, PATCH,			// lda #{1}			(*** PATCHED ***)
		0x85, 0x06,				// sta COLUP0
		0x85, 0x07,				// sta COLUP1
		0x85, 0x02,				// sta WSYNC
	};

const uint8_t exit_kernel[]__attribute__((section(".flash01"))) = {

// bottom of screen, switch BG to black after bottom of last menu line

		0xa9, 0x00,				// lda #0
		0x85, 0x09,				// sta COLUBK

		0x4c, 0x00, 0x10		// jmp $1000
		};

const uint8_t end_kernel_even[]__attribute__((section(".flash01"))) = {

0x86, 0x1b,				// stx GRP0
		0x86, 0x1c,				// stx GRP1
		};

const uint8_t restore_BG_colour[]__attribute__((section(".flash01"))) = {
#define PATCH_RESTORE_BG 1
		0xa9, PATCH,			// lda #??				(*** PATCHED ***)
		0x85, 0x09,				// sta COLUBK
		};

const uint8_t end_kernel_odd[]__attribute__((section(".flash01"))) = { 0xa2,
		0x00				// ldx #0
		};

uint8_t *my_font;

uint8_t *bufferp;

inline void add_end_kernel(bool is_even, uint8_t line);
inline void add_next_scanline(bool is_a);
inline void add_start_bank(uint8_t bank_id);
inline void add_end_bank(uint8_t bank_id);
inline void add_textline_start(bool even, uint8_t entry, bool isFolder);
inline void add_kernel_a(uint8_t fontType, uint8_t scanline, uint8_t *text);
inline void add_kernel_b(uint8_t fontType, uint8_t scanline, uint8_t *text);
inline void add_header_bottom(uint8_t colour);
inline void add_normal_bottom();
inline void add_text_colour(uint8_t colour);
inline void add_wsync();

inline void add_normal_top(uint8_t colour);
inline void add_exit_kernel();
inline void add_restore_BG_colour(uint8_t line);

// for colours see...
// https://www.randomterrain.com/atari-2600-memories-tia-color-charts.html

// COLOUR		NTSC		PAL
// 0			WHITE		WHITE
// 1			YELLOW		WHITE
// 2			ORANGE		YELLOW
// 3			RED			GREEN
// 4			PINKY		ORANGE
// 5			PURPLE		GREEN
// 6			PURPLE/BLUE	PINK
// 7			BLUE		PASTEL GREEN
// 8			AQUA		PINK/PURPLE
// 9			AQUA		AQUA
// A			PASTEL GREEN	PURPLE
// B			GREEN		BLUE
// C			GREEN		PURPLE
// D			OLIVE		PURPLE/BLUE
// E			YELLOW		WHITE
// F			ORANGE		WHITE

uint8_t textColour[2][12] = {

{	// NTSC...

		// see MENU_ENTRY_Type

				0xC8,//Leave_Menu,
				// --> ..
				// --> (Go Back)
				// .txt file

				0x2A,//Sub_Menu,
				0x48, //Cart_File,
				0x0A, //Input_Field,
				0x0A, //Keyboard_Char,
				0x0A, // keyboard row
				0X0A, //Menu_Action,
				0x0A, //Delete_Keyboard_Char,
				0x0A, //Offline_Cart_File,
				0x0A, //Offline_Sub_Menu,

				0X8C, //Setup_Menu
					  // --> "Setup"
					  // --> "Set TV Mode"
					  // --> "Set Font Style"
					  // --> "WiFi Setup"
					  //		--> individual WiFi IDs

				//0x2A	// header line

				0x46, // Leave SubKeyboard Menu
		},

		{	// PAL...

//	0, //Root_Menu = -1,
				0x5A,//Leave_Menu,
				0x4A, //Sub_Menu,
				0x88, //Cart_File,
				0x0A, //Input_Field,
				0x0A, //Keyboard_Char,
				0x0A, // keyboard row
				0x0A, //Menu_Action,
				0x0A, //Delete_Keyboard_Char,
				0x0A, //Offline_Cart_File,
				0x0A, //Offline_Sub_Menu,
				0xBC, //Setup_Menu

				//0x0A	// header line

				0x46, // Leave SubKeyboard Menu
		},

};

/*
 * Functions to append to the buffer the const "templates"
 * and fill in the dynamic values
 */
void add_start_bank(uint8_t bank_id) {
	bufferp = &buffer[(bank_id - 1) * 0x1000];
	memcpy(bufferp, start_bank, sizeof(start_bank));
	bufferp[PATCH_START_BANK] = (uint8_t)(bufferp[PATCH_START_BANK] + bank_id);
	bufferp += sizeof(start_bank);
}

void add_end_bank(uint8_t bank_id) {
	uint16_t next_bank = (uint16_t) (0x1000U * bank_id);
	memcpy(bufferp, switch_bank, sizeof(switch_bank));
	bufferp = &buffer[next_bank - 0x12];
	memcpy(bufferp, end_bank, sizeof(end_bank));
}

void add_textline_start(bool even, uint8_t entry, bool isFolder) {

	if (even) {
		memcpy(bufferp, textline_start_even, sizeof(textline_start_even));
		bufferp[PATCH_EVEN_LINE_BACKCOL] = (uint8_t)( 0x83 + entry);
		bufferp += sizeof(textline_start_even);
	} else {
		memcpy(bufferp, textline_start_odd, sizeof(textline_start_odd));
		bufferp[PATCH_LINE_BACKCOL] = (uint8_t)(0x83 + entry);
		bufferp += sizeof(textline_start_odd);
	}
}

//displays: 00--00--11--11--11----00--00--00
void add_kernel_a(uint8_t fontType, uint8_t scanline, uint8_t *text) {

//    add_text_colour(0x0A);
//    add_wsync();

	memcpy(bufferp, kernel_a, sizeof(kernel_a));

	if (fontType > 3)
		fontType = 0;				// cater for uninit'd font

	bufferp[PATCH_A_1] = t2c(fontType, text[4], text[5], scanline);      // #{3}
	bufferp[PATCH_A_2] = t2c(fontType, text[8], text[9], scanline);      // #{4}
	bufferp[PATCH_A_3] = t2c(fontType, text[0], text[1], scanline);      // #{2}
	bufferp[PATCH_A_4] = (uint8_t)((t2c(fontType, text[22], text[23], scanline)) << 1); // #{7} << 1
	bufferp[PATCH_A_5] = (uint8_t)((t2c(fontType, text[26], text[27], scanline)) << 1); // #{8} << 1
	bufferp[PATCH_A_6] = t2c(fontType, text[12], text[13], scanline);    // #{5}
	bufferp[PATCH_A_7] = t2c(fontType, text[16], text[17], scanline);    // #{6}
	bufferp[PATCH_A_8] = (uint8_t)((t2c(fontType, text[30], text[31], scanline)) << 1); // #{9} << 1

	bufferp += sizeof(kernel_a);
}

//displays: --00--00--11--11--1100--00--00--
void add_kernel_b(uint8_t fontType, uint8_t scanline, uint8_t *text) {
	memcpy(bufferp, kernel_b, sizeof(kernel_b));

	if (fontType > 3)
		fontType = 0;				// cater for uninit'd font

	bufferp[PATCH_B_1] = t2c(fontType, text[18], text[19], scanline);    // #{6}
	bufferp[PATCH_B_2] = t2c(fontType, text[10], text[11], scanline);    // #{4}
	bufferp[PATCH_B_3] = t2c(fontType, text[14], text[15], scanline);    // #{5}
	bufferp[PATCH_B_4] = t2c(fontType, text[2], text[3], scanline);      // #{2}
	bufferp[PATCH_B_5] = t2c(fontType, text[6], text[7], scanline);      // #{3}
	bufferp[PATCH_B_6] = t2c(fontType, text[20], text[21], scanline);    // #{7}
	bufferp[PATCH_B_7] = t2c(fontType, text[24], text[25], scanline);    // #{8}
	bufferp[PATCH_B_8] = t2c(fontType, text[28], text[29], scanline);    // #{9}

	bufferp += sizeof(kernel_b);
}

void add_end_kernel(bool is_even, uint8_t line) {

	//add_restore_BG_colour(line);

	if (!is_even) {
		memcpy(bufferp, end_kernel_odd, sizeof(end_kernel_odd));
		bufferp += sizeof(end_kernel_odd);
	}
	memcpy(bufferp, end_kernel_even, sizeof(end_kernel_even));
	bufferp += sizeof(end_kernel_even);
}

void add_restore_BG_colour(uint8_t line) {
	memcpy(bufferp, restore_BG_colour, sizeof(restore_BG_colour)); // hacked/hardwired colour until can use the array...

	bufferp[PATCH_RESTORE_BG] =
			user_settings.tv_mode == TV_MODE_NTSC ?
			BACK_COL_NTSC :
													BACK_COL_PAL;
//    if (line > 0)
//    	bufferp[PATCH_RESTORE_BG] += 2;

	bufferp += sizeof(restore_BG_colour);
}

void add_next_scanline(bool is_a) {
	if (is_a) {
		memcpy(bufferp, next_scanline_a, sizeof(next_scanline_a));
		bufferp += sizeof(next_scanline_a);
	} else {
		memcpy(bufferp, next_scanline_b, sizeof(next_scanline_b));
		bufferp += sizeof(next_scanline_b);
	}
}

void add_header_bottom(uint8_t colour) {
	memcpy(bufferp, header_bottom, sizeof(header_bottom));
	bufferp[PATCH_HEADER_BOTTOM_BACKGROUND_COLOUR] =
			user_settings.tv_mode == TV_MODE_NTSC ? BACK_COL_NTSC : BACK_COL_PAL;
	bufferp[PATCH_HEADER_BOTTOM_TEXT_COLOUR] = colour;
	bufferp += sizeof(header_bottom);
}

void add_normal_bottom() {
	memcpy(bufferp, normal_bottom, sizeof(normal_bottom));
	bufferp += sizeof(normal_bottom);
}

void add_normal_top(uint8_t colour) {
	memcpy(bufferp, normal_top, sizeof(normal_top));
	bufferp[PATCH_NORMAL_TOP_TEXT_COLOUR] = colour;
	bufferp += sizeof(normal_top);
}

void add_text_colour(uint8_t colour) {
	memcpy(bufferp, text_colour, sizeof(text_colour));
	bufferp[PATCH_TEXT_COLOUR] = colour;
	bufferp += sizeof(text_colour);
}

void add_wsync() {
	memcpy(bufferp, wsync, sizeof(wsync));
	bufferp += sizeof(wsync);
}

void add_exit_kernel() {

	// Set HEADER font colour
	add_text_colour(0x0C);			//white in PAL/NTSC

	memcpy(bufferp, exit_kernel, sizeof(exit_kernel));
	bufferp += sizeof(exit_kernel);
}

void createMenuForAtari(
		MENU_ENTRY *menu_entries,
		uint8_t page_id,
		int num_menu_entries,
		bool paging_required,
		bool is_connected,
		uint8_t *plus_store_status) {

	// create 7 banks of bytecode for the ATARI to execute.

	uint8_t menu_string[CHARS_PER_LINE];
	uint8_t bank = 1, sc, entry, odd_even;
	size_t str_len;
	uint8_t max_page = (uint8_t)((num_menu_entries - 1) / NUM_MENU_ITEMS_PER_PAGE);
	uint8_t items_on_last_page = (uint8_t)((num_menu_entries % NUM_MENU_ITEMS_PER_PAGE) ?
					(num_menu_entries % NUM_MENU_ITEMS_PER_PAGE) : NUM_MENU_ITEMS_PER_PAGE);
	uint8_t items_on_act_page = (uint8_t)((page_id < max_page) ? NUM_MENU_ITEMS_PER_PAGE : items_on_last_page);

	bufferp = buffer;
	memset(buffer, 0xff, 28 * 1024);

	unsigned int offset = (unsigned int)(NUM_MENU_ITEMS_PER_PAGE * page_id);

	set_menu_status_byte(STATUS_CurPage, page_id);
	set_menu_status_byte(STATUS_MaxPage, max_page);
	set_menu_status_byte(STATUS_ItemsOnActPage, items_on_act_page);

	// Display paging information

	if (max_page > 0) {
		uint8_t i = STATUS_MESSAGE_LENGTH - 1;
		max_page++;
		while (max_page != 0) {
			menu_header[i--] = (char)((max_page % 10) + '0');
			max_page = max_page / 10;
		}
		menu_header[i--] = PATH_SEPERATOR;

		page_id++;
		while (page_id != 0) {
			menu_header[i--] = (char)((page_id % 10) + '0');
			page_id = page_id / 10;
		}
		if (i % 2 == 0)
			menu_header[i--] = ' ';
		menu_header[i--] = CHAR_R_Page;
		menu_header[i] = CHAR_L_Page;
	}

	if (is_connected == true) {
		menu_header[CHARS_PER_LINE - 1 - 3] = CHAR_L_Wifi;
		menu_header[CHARS_PER_LINE - 1 - 2] = CHAR_R_Wifi;
	} else {
		menu_header[CHARS_PER_LINE - 1 - 3] = CHAR_L_NoWifi; //CHAR_L_NoWifi;
		menu_header[CHARS_PER_LINE - 1 - 2] = CHAR_R_NoWifi; //CHAR_R_NoWifi;
	}
	if (plus_store_status[0] == '1') {
		menu_header[CHARS_PER_LINE - 1 - 1] = CHAR_L_Account;
		menu_header[CHARS_PER_LINE - 1 - 0] = CHAR_R_Account;
	} else {
		menu_header[CHARS_PER_LINE - 1 - 1] = CHAR_L_NoAccount;
		menu_header[CHARS_PER_LINE - 1 - 0] = CHAR_R_NoAccount;
	}


	uint8_t colourSet = user_settings.tv_mode == TV_MODE_NTSC ? 0 : 1;

	// Start of menu page generation

	add_start_bank(bank);

	for (odd_even = 0; odd_even < 2; odd_even++) {

		for (entry = 0; entry <= NUM_MENU_ITEMS_PER_PAGE; entry++) {
			bool is_kernel_a = bank < 4, isFolder = false;
			unsigned int list_entry = entry + offset;

			menu_entries[list_entry].font = user_settings.font_style;

			if (entry == 0) {		// header line

				add_text_colour(0x0A);
				add_wsync();

				memcpy(menu_string, menu_header, CHARS_PER_LINE);

				// If you want a different font for header line, set it here
				// menu_entries[list_entry].font = user_settings.font_style; // <-- OR, font # hardwire

				isFolder = true;

			} else {

				list_entry--;

				memset(menu_string, ' ', CHARS_PER_LINE);

				if (list_entry < num_menu_entries) {
					str_len = strlen(menu_entries[list_entry].entryname);
					memcpy(menu_string, menu_entries[list_entry].entryname, str_len);
					isFolder = (menu_entries[list_entry].type != Offline_Cart_File
							&& menu_entries[list_entry].type != Cart_File);
				}
			}

			for (uint8_t i = 0; i < CHARS_PER_LINE; i++)
				if (menu_string[i] < ' ' || menu_string[i] >= CHAR_MAX)
					menu_string[i] = ' ';

			add_textline_start(is_kernel_a, entry, isFolder);
			for (sc = 0; sc < CHAR_HEIGHT; sc++) {

				is_kernel_a ?
					add_kernel_a(menu_entries[list_entry].font, sc, menu_string) :
					add_kernel_b(menu_entries[list_entry].font, sc, menu_string);

				if (sc < CHAR_HEIGHT - 1)
					add_next_scanline(is_kernel_a);

				is_kernel_a = !is_kernel_a;
			}
			add_end_kernel(is_kernel_a, entry);

			if (entry == 0) {
				add_header_bottom(textColour[colourSet][(int) (menu_entries[list_entry + 1].type)]);

			} else {


				if (entry == 4 || entry == 9 || entry == NUM_MENU_ITEMS_PER_PAGE) {
					if (entry > 4) {
						add_normal_bottom(entry);
						if (entry == NUM_MENU_ITEMS_PER_PAGE) {
							add_exit_kernel();
						}
					}
					add_end_bank(bank);
					bank++;

					add_start_bank(bank);
					if (entry == 4) {
						add_normal_bottom(entry);
					}

				} else
					add_normal_bottom(entry);

				if (entry != NUM_MENU_ITEMS_PER_PAGE)
					add_normal_top(textColour[colourSet][(int)(menu_entries[list_entry+1].type)]);

			}
		}
	}
	add_end_bank(bank);
}

void set_menu_status_msg(const char *message) {
	size_t msg_len = strlen(message);
	memset(menu_header, ' ', CHARS_PER_LINE);
	strncpy(menu_header, message, msg_len > STATUS_MESSAGE_LENGTH ? STATUS_MESSAGE_LENGTH : msg_len);
}

void set_menu_status_byte(enum eStatus_bytes_id byte_id, uint8_t status_byte) {
	menu_status[byte_id] = status_byte;
}

void set_tv_mode(int tv_mode) {
	switch (tv_mode) {

	case TV_MODE_PAL:
		firmware_rom = firmware_pal_rom;
		break;

	case TV_MODE_PAL60:
		firmware_rom = firmware_pal60_rom;
		break;

	default:
	case TV_MODE_NTSC:
		firmware_rom = firmware_ntsc_rom;
		break;
	}
}

// We require the menu to do a write to $1FF4 to unlock the comms area.
// This is because the 7800 bios accesses this area on console startup, and we wish to ignore these
// spurious reads until it has started the cartridge in 2600 mode.
bool comms_enabled = false;

int emulate_firmware_cartridge() {
	__disable_irq();	// Disable interrupts
	uint16_t addr, addr_prev = 0;
	uint8_t data = 0, data_prev = 0;
	unsigned const char *bankPtr = &firmware_rom[0];

	while (1) {
		while ((addr = ADDR_IN) != addr_prev)
			addr_prev = addr;

		// got a stable address
		if (addr & 0x1000) { // A12 high
			if (comms_enabled) {

				// normal mode, once the cartridge code has done its init.
				// on a 7800, we know we are in 2600 mode now.

				// Quick-check range to prevent normal access doing 5+ comparisons...

				if (addr >= CART_CMD_HOTSPOT) {

					if (addr > 0x1FF4 && addr <= 0x1FFB) {	// bank-switch
						bankPtr = &buffer[(addr - 0x1FF5) * 4 * 1024];
						DATA_OUT = bankPtr[addr & 0xFFF];
					}

					else if (addr == 0x1FF4) {
						bankPtr = &firmware_rom[0];
						DATA_OUT = bankPtr[addr & 0xFFF];
					}

					else if (addr == CART_CMD_HOTSPOT) {// atari 2600 has send an command
						while (ADDR_IN == addr) {
							data_prev = data;
							data = DATA_IN;
						}
						addr = data_prev;
						break;
					}

					else if (addr > CART_STATUS_BYTES_START - 1
							&& addr < CART_STATUS_BYTES_END + 1) {
						DATA_OUT = menu_status[addr - CART_STATUS_BYTES_START];
					}

					else if (addr > CART_STATUS_BYTES_END) {
						DATA_OUT = end_bank[addr - (CART_STATUS_BYTES_END + 1)];
					} else {
						DATA_OUT = bankPtr[addr & 0xFFF];
					}

				} else
					DATA_OUT = bankPtr[addr & 0xFFF];

			} else {// prior to an access to $1FF4, we might be running on a 7800 with the CPU at
					// ~1.8MHz so we've got less time than usual - keep this short.
				if (addr > CART_STATUS_BYTES_END) {
					DATA_OUT = end_bank[addr - (CART_STATUS_BYTES_END + 1)];
				} else {
					DATA_OUT = bankPtr[addr & 0xFFF];
				}
				if (addr == 0x1FF4) // we should move this comm enable hotspot because it is in the bankswitch area..
					comms_enabled = true;
			}

			SET_DATA_MODE_OUT
			while ((addr_prev = ADDR_IN) == addr)
				;
			SET_DATA_MODE_IN
		}
	}

	__enable_irq();
	return addr;
}

bool reboot_into_cartridge() {
	set_menu_status_byte(STATUS_StatusByteReboot, 1);

	return emulate_firmware_cartridge() == CART_CMD_START_CART;
}
