#include <string.h>

#include "cartridge_firmware.h"

#include "text.h"
#include "wait_spinner.h"
#include "reboot_into_cartbin.h"
#include "text78bin.h"

// These are the colours between the top title bar and the rest of the text lines...

#define BACK_COL_NTSC 0x92
#define BACK_COL_PAL 0xD2

int numMenuItemsPerPage;

static char menu_header[CHARS_PER_LINE] __attribute__((section(".ccmram#")));
static char pendingStatusMessage[STATUS_MESSAGE_LENGTH] __attribute__((section(".ccmram#")));
static unsigned char menu_status[STATUS_MAX] __attribute__((section(".ccmram#")));

// Save these when creating menu so we can change pages later
static MENU_ENTRY *pMenuEntries;
static uint8_t currentPage;
static int menuEntriesCount;
static bool isConnected;
static uint8_t *plusStoreStatus;
uint8_t max_page_index;
uint8_t items_on_act_page;
uint8_t colubk;

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

const uint8_t textColour[2][14] = {

	{
		// NTSC...

		// see MENU_ENTRY_Type

		0x0a, // C8,//Leave_Menu,
			  //  --> ..
			  //  --> (Go Back)
			  //  .txt file

		0x2a, // 2A,//Sub_Menu,
		0x0a, // 48, //Cart_File,
		0x0A, // Input_Field,
		0x0A, // Keyboard_Char,
		0x0A, // keyboard row
		0X0A, // Menu_Action,
		0x0A, // Delete_Keyboard_Char,
		0x0A, // Offline_Cart_File,
		0x0A, // Offline_Sub_Menu,

		0xCA, // 8C, //Setup_Menu
			  //  --> "Setup"
			  //  --> "Set TV Mode"
			  //  --> "Set Font Style"
			  //  --> "WiFi Setup"
			  //		--> individual WiFi IDs

		// 0x2A	// header line

		0x0a, // 46, // Leave SubKeyboard Menu
		0x0A, // SD_Cart_File,
		0x0A, // SD_Sub_Menu,
	},

	{
		// PAL...

		//	0, //Root_Menu = -1,
		0x0A, // Leave_Menu,
		0x2A, // 4A, //Sub_Menu,
		0x0a, // 68, //Cart_File,
		0x0A, // Input_Field,
		0x0A, // Keyboard_Char,
		0x0A, // keyboard row
		0x0A, // Menu_Action,
		0x0A, // Delete_Keyboard_Char,
		0x0A, // Offline_Cart_File,
		0x0A, // Offline_Sub_Menu,

		0x3a, // BC, //Setup_Menu

		// 0x0A	// header line

		0x0A, // Leave SubKeyboard Menu
		0x0A, // SD_Cart_File,
		0x0A, // SD_Sub_Menu,
	},

};

void handleInput(int *SelectedIndex, uint8_t swcha_prev, uint8_t swcha, uint8_t inpt4_prev, uint8_t inpt4);

char cvtToNum(char *p)
{
	const char *digits = "0123456789ABCDEF";
	return (char)(strchr(digits, *p) - digits);
}

void createMenuForAtari(
	MENU_ENTRY *menu_entries,
	uint8_t page_id,
	int num_menu_entries,
	bool is_connected,
	uint8_t *plus_store_status)
{
	uint8_t menu_string[CHARS_PER_LINE];
	uint8_t sc, entry, odd_even;
	size_t str_len;
	pMenuEntries = menu_entries;
	menuEntriesCount = num_menu_entries;
	isConnected = is_connected;
	plusStoreStatus = plus_store_status;
	currentPage = page_id;
	numMenuItemsPerPage = SetRowDensity(user_settings.line_spacing);
	uint8_t max_page = (uint8_t)((num_menu_entries - 1) / numMenuItemsPerPage);
	max_page_index = max_page;
	uint8_t items_on_last_page = (uint8_t)((num_menu_entries % numMenuItemsPerPage) ? (num_menu_entries % numMenuItemsPerPage) : numMenuItemsPerPage);
	items_on_act_page = (uint8_t)((page_id < max_page) ? numMenuItemsPerPage : items_on_last_page);

	unsigned int offset = (unsigned int)(numMenuItemsPerPage * page_id);

	memset(menu_header, ' ', sizeof(menu_header) / sizeof(char));

	// Display paging information

	int showEllipsis = -1;
	int pageIcon = -1;
	int wifiIcon = -1;
	int accountIcon = -1;
	uint8_t i = CHARS_PER_LINE - 3; // Leave room for mode status icon

#if USE_WIFI
	i -= 4; // Leave space for the 2 status icons
	accountIcon = (*plus_store_status == '1') ? 0 : 1;
	wifiIcon = is_connected ? 0 : 1;
#endif

	// Page info
	if (max_page > 0)
	{

		uint8_t pagePos = i;
		i--;

		max_page++;
		while (max_page != 0)
		{
			menu_header[i--] = (char)((max_page % 10) + '0');
			max_page = max_page / 10;
		}
		menu_header[i--] = PATH_SEPERATOR;

		page_id++;
		while (page_id != 0)
		{
			menu_header[i--] = (char)((page_id % 10) + '0');
			page_id = page_id / 10;
		}

		// if the position would cause character glitching in 2-char page, then shift everything left

		if ((i & 1) == 0)
		{
			for (uint8_t j = 8; j > 0; j--)
				menu_header[pagePos - j] = menu_header[pagePos - j + 1];
			i--;
		}

		pageIcon = i >> 1;
		i -= 2;
	}

	// "..." truncated status message
	// first, remove %XX encodings for visuals

	char *vp = pendingStatusMessage;
	for (char *p = pendingStatusMessage; *p; p++)
	{
		if (*p == '%')
		{
			*vp++ = (char)(cvtToNum(p + 1) * 16 + cvtToNum(p + 2));
			p += 2;
		}
		else
		{
			*vp++ = *p;
		}
	}
	int cpySize = (int)vp - (int)pendingStatusMessage;
	*vp = 0;

	// now truncate path string to last visible n characters
	// put an "..." at the front of long status lines, and shift start point...

	vp = pendingStatusMessage;

	if (strlen(pendingStatusMessage) > i)
	{
		vp = pendingStatusMessage + strlen(pendingStatusMessage) - i;
		*vp = ' ';
		*(vp + 1) = ' ';
		showEllipsis = 1;
		cpySize = i;
	}

	strncpy(menu_header, vp, cpySize);

	uint8_t colourSet = user_settings.tv_mode == TV_MODE_NTSC ? 0 : 1;
	int fontIndex = user_settings.font_style;
	// Start of menu page generation
	colubk = user_settings.tv_mode == TV_MODE_NTSC ? BACK_COL_NTSC : BACK_COL_PAL;
	ClearBuffers(colubk & 0xf0, colubk);
	for (entry = 0; entry <= numMenuItemsPerPage; entry++)
	{
		uint8_t colup = 0xa;
		if (!entry)
		{
			PrintHeader(fontIndex, colup, showEllipsis, pageIcon, wifiIcon, accountIcon, menu_header);
		}
		else
		{
			unsigned int list_entry = entry + offset - 1;
			if (list_entry < num_menu_entries)
			{
				colup = textColour[colourSet][menu_entries[list_entry].type];
				PrintRow(fontIndex, entry - 1, colup, menu_entries[list_entry].entryname);
			}
		}
	}
}

void set_menu_status_msg(const char *message)
{
	// memset(pendingStatusMessage, 0, sizeof(pendingStatusMessage)/sizeof(char));
	strncpy(pendingStatusMessage, message, sizeof(pendingStatusMessage) / sizeof(char) - 1);
}

void set_menu_status_byte(enum eStatus_bytes_id byte_id, uint8_t status_byte)
{
	menu_status[byte_id] = status_byte;
}

bool reboot_into_cartridge()
{
	set_menu_status_byte(STATUS_StatusByteReboot, 1);
	if (LockStatus == Locked7800)
	{
		// Console must be rebooted before 2600 ROMs can be launched
		return false;
	}

	__disable_irq();
	EndWaitSpinner();

	vcsNop2();
	// Update lock status if needed
	if (LockStatus == Unlocked7800)
	{
		// Lock into 2600 mode
		lock2600mode();
	}
	for (int i = 0; i < REBOOT_INTO_CARTBIN_ARG_SIZE; i++)
	{
		vcsWrite5(REBOOT_INTO_CARTBIN_ARG_START + i, Reboot_into_cartBin[i]);
	}
	vcsJmpToRam3(REBOOT_INTO_CARTBIN_ARG_START);

	return true;
}

int hasInitialized = 0;
RAM_FUNC int emulate_firmware_cartridge()
{
	if (hasInitialized == 0)
	{
		hasInitialized = 1;
		numMenuItemsPerPage = SetRowDensity(user_settings.line_spacing);
		return CART_CMD_ROOT_DIR;
	}

	// Always highlight top row
	SetRowBackground(0, 0x55);
	int SelectedIndex = 0;
	DefineControlVars;

	__disable_irq();
	EndWaitSpinner();
	vcsNop2();
	if (LockStatus == Locked2600)
	{
		// Init TIA and RIOT RAM
		vcsLda2(0);
		for (int i = 0; i < 256; i++)
		{
			vcsSta3((unsigned char)i);
		}
		vcsCopyOverblankToRiotRam();
		vcsWrite5(0x81, 13);
		vcsStartOverblank();
		while (1)
		{

			vcsEndOverblank();
			for (int i = 0; i < 4; i++)
			{
				vcsSta3(WSYNC);
			}

			DisplayText();

			vcsWrite5(VBLANK, 2);
			vcsSta3(WSYNC);
			UpdateControlVars;
			if (Joy0_Fire && Joy0_Fire_Changed)
			{
				StartWaitSpinner();
				__enable_irq();
				return currentPage * numMenuItemsPerPage + SelectedIndex;
			}
			else
			{
				vcsStartOverblank();
				handleInput(&SelectedIndex, swcha_prev, swcha, inpt4_prev, inpt4);
			}
		}
	}
	else // 7800
	{
		// Copy Kernel
		for (int i = 0; i < TEXT78BIN_ARG_KERNEL_SIZE; i++)
		{
			vcsWrite6((uint16_t)(TEXT78BIN_ARG_LOAD + i), Text78Bin[i]);
		}
		// Transfer control
		vcsJmpToRam3(TEXT78BIN_ARG_KERNEL);

		while (1)
		{
			DisplayText78();

			// Should be in VBLANK soon

			swcha_prev = swcha;
			inpt4_prev = inpt4;
			swcha = vcsSnoopRead(SWCHA);
			inpt4 = vcsSnoopRead(INPT4);
			if (Joy0_Fire && Joy0_Fire_Changed)
			{
				EndWaitSpinner();
				StartWaitSpinner();
				__enable_irq();
				return currentPage * numMenuItemsPerPage + SelectedIndex;
			}
			else
			{
				handleInput(&SelectedIndex, swcha_prev, swcha, inpt4_prev, inpt4);
			}
		}
	}

	return 0;
}

void handleInput(int *SelectedIndex, uint8_t swcha_prev, uint8_t swcha, uint8_t inpt4_prev, uint8_t inpt4)
{
	// Only process one direction per frame to avoid running out of vblank cycles on pointless actions
	if (Joy0_Down_Changed && Joy0_Down)
	{
		SetRowBackground(*SelectedIndex, colubk);

		if (*SelectedIndex < items_on_act_page - 1)
		{
			(*SelectedIndex)++;
		}
		else if (currentPage < max_page_index)
		{
			*SelectedIndex = 0;
			createMenuForAtari(pMenuEntries, currentPage + 1, menuEntriesCount, isConnected, plusStoreStatus);
		}

		SetRowBackground(*SelectedIndex, 0x55);
	}
	else if (Joy0_Up_Changed && Joy0_Up)
	{
		SetRowBackground(*SelectedIndex, colubk);
		if (*SelectedIndex > 0)
		{
			(*SelectedIndex)--;
		}
		else if (currentPage > 0)
		{
			*SelectedIndex = 0;
			createMenuForAtari(pMenuEntries, currentPage - 1, menuEntriesCount, isConnected, plusStoreStatus);
		}

		SetRowBackground(*SelectedIndex, 0x55);
	}
	else if (Joy0_Right_Changed && Joy0_Right)
	{
		SetRowBackground(*SelectedIndex, colubk);
		if (currentPage < max_page_index)
		{
			*SelectedIndex = 0;
			createMenuForAtari(pMenuEntries, currentPage + 1, menuEntriesCount, isConnected, plusStoreStatus);
		}

		SetRowBackground(*SelectedIndex, 0x55);
	}
	else if (Joy0_Left_Changed && Joy0_Left)
	{
		SetRowBackground(*SelectedIndex, colubk);
		if (currentPage > 0)
		{
			*SelectedIndex = 0;
			createMenuForAtari(pMenuEntries, currentPage - 1, menuEntriesCount, isConnected, plusStoreStatus);
		}

		SetRowBackground(*SelectedIndex, 0x55);
	}
}
