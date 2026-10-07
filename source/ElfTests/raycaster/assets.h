#include <stdint.h>

#define MapWidth 40
#define MapHeight 40

extern const unsigned char reverseByte[256];

extern const int SineLookup[128];

extern int8_t map[MapWidth][MapHeight];

extern uint8_t heights[40];
extern uint8_t colors[40];
