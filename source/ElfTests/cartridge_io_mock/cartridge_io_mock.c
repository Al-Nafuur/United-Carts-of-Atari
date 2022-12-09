#include <stdint.h>

volatile uint16_t* const ADDR_IDR  = (volatile uint16_t* const)0x40000010;
volatile uint8_t* const DATA_IDR = (volatile uint8_t* const)0x40000020;
volatile uint8_t* const DATA_ODR = (volatile uint8_t* const)0x40000030;
volatile uint16_t* const DATA_MODER = (volatile uint16_t* const)0x40000040;