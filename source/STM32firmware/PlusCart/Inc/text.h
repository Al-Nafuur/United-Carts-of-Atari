#include <stdint.h>
#include "fonts.h"
#include "vcsLib.h"

#define RowWidthBytes 18
#define RowWidthChars RowWidthBytes * 2
#define GlyphHeight 12
// There is a top line that's always empty due to setup and vblank.
#define TextLinesCount 204

void ClearBuffers(uint8_t headerColubk, uint8_t rowsColubk);

void SetRowBackground(int row, uint8_t colubk);
int SetRowDensity(int density);

void PrintHeader(int font, uint8_t colup, int ellipsis, int page, int wifi, int account, const char *ptext);
void PrintRow(int font, int row, uint8_t colup, const char *ptext);

void DisplayText();
void DisplayText78();
