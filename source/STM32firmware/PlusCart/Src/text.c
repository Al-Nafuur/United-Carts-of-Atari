#include "text.h"
#include "vcsLib.h"
#include "text78bin.h"

static const int RowCountLookup[] = {14, 12, 10};
static const int topPadLookup[] = {1, 2, 3};
static const int botPadLookup[] = {0, 1, 3};

static void kernelA(int line, uint8_t textBuffer[18]);
static void kernelB(int line, uint8_t textBuffer[18]);
void PrintEllipsis(int font, int line);
void PrintIcon(int icon, int line, int column);
void PrintIcon2600(int icon, int line, int column);
void PrintIcon7800(int icon, int line, int column);
static void PrintSmall(int font, int line, int topMargin, int botMargin, uint8_t colup, const char *ptext);

static int frameCount = 0;
static int density = 0;

NO_INIT uint8_t textBuffer[RowWidthBytes * TextLinesCount * 2]; // 7800 needs 1 byte per character
NO_INIT uint8_t textColuBK[TextLinesCount];
NO_INIT uint8_t textColuP[TextLinesCount];

// lookup tables to convert 2600 nibbles to 160a bytes
const uint8_t color1lookup[16] = {0x00, 0x01, 0x04, 0x05,
								  0x10, 0x11, 0x14, 0x15,
								  0x40, 0x41, 0x44, 0x45,
								  0x50, 0x51, 0x54, 0x55};

void ClearBuffers(uint8_t headerColubk, uint8_t rowsColubk)
{
	uint32_t *pBuffer = (uint32_t *)&textBuffer[0];
	for (int i = 0; i < TextLinesCount * 9; i++)
	{
		pBuffer[i] = 0;
	}
	for (int i = 0; i < 16; i++)
	{
		textColuBK[i] = headerColubk;
		textColuP[i] = 0;
	}
	for (int i = 16; i < TextLinesCount; i++)
	{
		textColuBK[i] = rowsColubk;
		textColuP[i] = 0;
	}
}

void SetRowBackground(int row, uint8_t colubk)
{
	int topMargin = topPadLookup[density];
	int botMargin = botPadLookup[density];
	int lineCount = 12 + topMargin + botMargin;
	int startLine = 20 + (density ? 1 : 0) + (row * lineCount);
	for (int i = startLine; i < startLine + lineCount; i++)
	{
		textColuBK[i] = colubk;
	}
}

int SetRowDensity(int newDensity)
{
	density = newDensity;
	return RowCountLookup[density];
}

void PrintHeader(int font, uint8_t colup, int ellipsis, int page, int wifi, int account, const char *ptext)
{
	int topMargin = 3;
	int botMargin = 1;
	PrintSmall(font, 0, topMargin, botMargin, colup, ptext);
	if (ellipsis >= 0)
	{
		PrintEllipsis(font, topMargin);
	}
	if (page >= 0)
	{
		PrintIcon(2, topMargin, page);
	}
	if (wifi >= 0)
	{
		PrintIcon(wifi, topMargin, 15);
	}
	if (account >= 0)
	{
		PrintIcon(3 + account, topMargin, 16);
	}
	PrintIcon(5 + LockStatus, topMargin, 17);
}

void PrintRow(int font, int row, uint8_t colup, const char *ptext)
{
	int topMargin = topPadLookup[density];
	int botMargin = botPadLookup[density];
	int rowHeight = 12 + topMargin + botMargin;
	int line = 20 + (density ? 1 : 0) + (row * rowHeight);
	PrintSmall(font, line, topMargin, botMargin, colup, ptext);
}

void PrintSmall(int font, int line, int topMargin, int botMargin, uint8_t colup, const char *ptext)
{
	if (topMargin > 0)
	{
		textColuP[line] = colup | 1;
	}

	int columnIncrement;
	int rowBytesCount;
	if (LockStatus == Locked2600)
	{
		columnIncrement = 1;
		rowBytesCount = RowWidthBytes;
	}
	else
	{
		columnIncrement = 2;
		rowBytesCount = RowWidthChars;
	}
	int columnIndex = (line + topMargin) * rowBytesCount;
	for (int x = 0; x < RowWidthChars; x += 2)
	{
		int index = columnIndex;
		int leftCharIndex = ptext[x] - '!';
		int rightCharIndex = ptext[x + 1] - '!';
		uint32_t topLeft = ptext[x] < '!' ? 0 : FontTops[font][leftCharIndex];
		uint32_t topRight = ptext[x] == 0 || ptext[x + 1] < '!' ? 0 : FontTops[font][rightCharIndex];

		// Blit the first 30 pixels
		int shift = 29;
		for (int y = 0; y < GlyphHeight; y++)
		{
			if (LockStatus == Locked2600)
			{
				textBuffer[index] = (((topLeft >> shift) & 0x7) << 4) | ((topRight >> shift) & 7);
			}
			else
			{
				textBuffer[index] = color1lookup[((topLeft >> shift) & 0x7)];
				textBuffer[index + 1] = color1lookup[((topRight >> shift) & 7)];
			}

			shift -= 3;
			if (shift < 0)
			{
				// Load in the bottom 4 bits
				shift = 0;
				topLeft = (topLeft << 4) | ((ptext[x] < '!' ? 0 : FontBottoms[font][leftCharIndex / 2]) >> (leftCharIndex & 1 ? 4 : 0));
				topRight = (topRight << 4) | ((ptext[x + 1] < '!' ? 0 : FontBottoms[font][rightCharIndex / 2]) >> (rightCharIndex & 1 ? 4 : 0));
			}
			index += rowBytesCount;
		}
		if (ptext[x] == 0 || ptext[x + 1] == 0)
		{
			break;
		}
		columnIndex += columnIncrement;
	}
}

void PrintEllipsis(int font, int line)
{
	int rowBytesCount = (LockStatus == Locked2600) ? RowWidthBytes : RowWidthChars;
	int index = line * rowBytesCount;
	for (int y = 0; y < GlyphHeight; y++)
	{
		textBuffer[index] = Ellipsis[font][y];
		index += rowBytesCount;
	}
}

void PrintIcon(int icon, int line, int column)
{
	if (LockStatus == Locked2600)
	{
		PrintIcon2600(icon, line, column);
	}
	else
	{
		PrintIcon7800(icon, line, column);
	}
}
void PrintIcon2600(int icon, int line, int column)
{
	int rowBytesCount = RowWidthBytes;
	int index = line * rowBytesCount + column;
	for (int y = 0; y < GlyphHeight; y++)
	{
		textBuffer[index] = Icons[icon][y];
		index += rowBytesCount;
	}
}

void PrintIcon7800(int icon, int line, int column)
{
	int rowBytesCount = RowWidthChars;
	int index = line * rowBytesCount + column * 2;
	for (int y = 0; y < GlyphHeight; y++)
	{
		textBuffer[index] = color1lookup[Icons[icon][y] >> 4];
		textBuffer[index + 1] = color1lookup[Icons[icon][y] & 0xf];
		index += rowBytesCount;
	}
}

void DisplayText()
{
	frameCount++;
	int frameToggle = frameCount & 1;

	vcsSta3(WSYNC);
	vcsSta3(HMOVE); //	sta HMOVE
	vcsLdx2(0);		//	lda #$0
	vcsStx3(ENAM0);
	vcsStx3(ENAM1);
	vcsStx3(ENABL);
	vcsStx3(GRP0);
	vcsStx3(GRP1);
	vcsLda2(textColuBK[0]);
	vcsSta3(COLUBK);
	vcsSta3(COLUPF);
	vcsJmp3();
	if (frameToggle)
	{
		vcsJmp3();
		vcsWrite5(HMP1, 0xe0);
	}
	else
	{
		vcsLda2(0xf0);
		vcsSta4(HMP1);
	}
	vcsSta4(RESPONE); //	sta RESP1
	vcsLda2(0x0e);
	vcsSta3(COLUP0);
	vcsSta3(COLUP1);
	vcsLda2(3);
	vcsSta3(NUSIZ0);
	vcsSta3(NUSIZ1);
	vcsStx3(VDELP0);
	vcsStx3(VDELP1);
	vcsSta3(WSYNC); //	sta WSYNC

	vcsSta3(HMOVE); //	sta HMOVE
	vcsWrite5(VBLANK, 0);
	vcsJmp3();
	vcsNop2n(19);
	vcsSta3(HMCLR); //	sta HMCLR
	vcsNop2n(9);
	// Need to position P0 just right in blank lines to avoid it showing up on the next line in the left margin
	if (frameToggle)
	{
		vcsJmp3();
		vcsSta3(RESP0);
		for (int j = 0; j < TextLinesCount;)
		{
			kernelB(j, &textBuffer[j * 18]);
			j++;
			kernelA(j, &textBuffer[j * 18]);
			j++;
		}
	}
	else
	{
		vcsSta3(RESP0);
		vcsJmp3();
		for (int j = 0; j < TextLinesCount;)
		{
			kernelA(j, &textBuffer[j * 18]);
			j++;
			kernelB(j, &textBuffer[j * 18]);
			j++;
		}
	}
	vcsNop2();
}

// 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ
// 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7
static void kernelA(int line, uint8_t textBuffer[18])
{
	vcsSta3(HMOVE);
	vcsWrite5(COLUBK, textColuBK[line]);
	vcsNop2();
	vcsLdy2(textBuffer[13] << 1);	// qqq_rrr_
	vcsWrite5(GRP0, textBuffer[0]); // _000_111
	vcsLda2(textBuffer[6] << 1);	// ccc_ddd_
	vcsSta3(GRP1);
	vcsSta3(RESP0);
	if (textColuP[line] & 1)
	{
		vcsWrite5(COLUP0, textColuP[line]);
		vcsWrite5(COLUP1, textColuP[line]);
	}
	else
	{
		vcsWrite5(GRP0, textBuffer[2]); // _444_555
		vcsWrite5(GRP0, textBuffer[4]); // _888_999
	}
	vcsWrite5(HMP1, 0x90);
	vcsLdx2(textBuffer[10] << 1);		 // kkk_lll_
	vcsWrite5(GRP1, textBuffer[8] << 1); // ggg_hhh_
	vcsStx4(GRP1);
	vcsSta3(RESP0);
	vcsSty3(GRP0);
	vcsSta3(RESP0);
	vcsWrite5(GRP0, textBuffer[15] << 1); // uuu_vvv_
	vcsWrite5(GRP0, textBuffer[17] << 1); // yyy_zzz_
	vcsJmp3();							  //	SLEEP 3
	vcsSta3(RESP0);						  //	sta RESP0
}

static void kernelB(int line, uint8_t textBuffer[18])
{
	vcsSta3(HMOVE);
	vcsWrite5(COLUBK, textColuBK[line]);
	vcsWrite5(GRP1, textBuffer[7]); // _eee_fff
	vcsLdx2(textBuffer[11]);		// _mmm_nnn
	vcsWrite5(HMP1, 0x70);
	vcsWrite5(GRP0, textBuffer[1] << 1); // 222_333_
	vcsSta3(RESP0);
	if (textColuP[line] & 1)
	{
		vcsWrite5(COLUP0, textColuP[line]);
		vcsWrite5(COLUP1, textColuP[line]);
	}
	else
	{
		vcsWrite5(GRP0, textBuffer[3] << 1); // 666_777_
		vcsWrite5(GRP0, textBuffer[5] << 1); // aaa_bbb_
	}
	vcsWrite5(GRP0, textBuffer[12]); // _ooo_ppp
	vcsWrite5(GRP1, textBuffer[9]);	 // _iii_jjj
	vcsSta3(RESP0);
	vcsStx3(GRP1);
	vcsSta3(RESP0);
	vcsWrite5(GRP0, textBuffer[14]); // _sss_ttt
	vcsWrite5(GRP0, textBuffer[16]); // _www_xxx
	vcsJmp3();
	vcsSta3(RESP0);
	vcsJmp3();
}

RAM_FUNC int DisplayText78(int itemsCount)
{
	// Copy Kernel
	for (int i = 0; i < TEXT78BIN_ARG_KERNEL_SIZE; i++)
	{
		vcsWrite6((uint16_t)(TEXT78BIN_ARG_LOAD + i), Text78Bin[i]);
	}
	// Transfer control
	vcsJmpToRam3(TEXT78BIN_ARG_KERNEL);
	int SelectedIndex = 0;
	DefineControlVars;

	while (1)
	{
		int line = 0;
		int bufferOffset = 0;
		for (int i = 0; i < 13; i++)
		{
			for (uint16_t addr = i < 12 ? 0x1fc0 : 0x1bc0; addr > 0x1000; addr -= 0x0100)
			{
				vcsInjectDmaData(0x1fb0, 1, &textColuBK[line++]);
				vcsInjectDmaData(addr, 18, &textBuffer[bufferOffset]);
				bufferOffset += RowWidthBytes;
				vcsInjectDmaData(addr, 18, &textBuffer[bufferOffset]);
				bufferOffset += RowWidthBytes;
			}
		}

		// Should be in VBLANK soon

		swcha_prev = swcha;
		inpt4_prev = inpt4;
		swcha = vcsSnoopRead(SWCHA);
		inpt4 = vcsSnoopRead(INPT4);
		if (Joy0_Fire && Joy0_Fire_Changed)
		{
			return SelectedIndex;
		}
		else
		{
			if (Joy0_Down_Changed && Joy0_Down)
			{
				SetRowBackground(SelectedIndex, 0x80);
				SelectedIndex++;
				if (SelectedIndex >= itemsCount)
				{
					SelectedIndex = 0;
				}

				SetRowBackground(SelectedIndex, 0x55);
			}
			if (Joy0_Up_Changed && Joy0_Up)
			{
				SetRowBackground(SelectedIndex, 0x80);
				SelectedIndex--;
				if (SelectedIndex < 0)
				{
					SelectedIndex = itemsCount - 1;
				}

				SetRowBackground(SelectedIndex, 0x55);
			}
		}
	}
}