#ifndef CARTRIDGE_IO_H
#define CARTRIDGE_IO_H

#include <stdint.h>

#define SWCHB          0x282

#ifdef HARDWARE_TYPE
 #if HARDWARE_TYPE == UNOCART
   #include "stm32f4xx.h"
   #define CONTROL_IN GPIOC->IDR
 #endif
#endif

extern volatile uint16_t* const ADDR_IDR;
extern volatile uint8_t* const DATA_IDR;
extern volatile uint8_t* const DATA_ODR;
extern volatile uint16_t* const DATA_MODER;

#define ADDR_IN (*ADDR_IDR)
#define DATA_IN (*DATA_IDR)
#define DATA_IN_BYTE (*DATA_IDR & 0xFF) // TODO deprecate this
#define DATA_OUT *DATA_ODR
#define SET_DATA_MODE_IN *DATA_MODER = 0x0000;
#define SET_DATA_MODE_OUT *DATA_MODER = 0x5555;
#define SET_DATA_MODE(m) *DATA_MODER = (m);

// Used to control exit function
extern uint16_t EXIT_SWCHB_ADDR;


#endif // CARTRIDGE_IO_H
