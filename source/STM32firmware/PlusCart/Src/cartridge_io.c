#include "cartridge_io.h"

// if no HARDWARE_TYPE, leave undefined for now. ELF loader will handle defining at load time
#ifdef HARDWARE_TYPE
 #if HARDWARE_TYPE == UNOCART
   volatile uint8_t* const  DATA_IDR = &(((uint8_t*)(&GPIOE->IDR))[1]);
   volatile uint8_t* const DATA_ODR = &(((uint8_t*)(&GPIOE->ODR))[1]);
   volatile uint16_t* const DATA_MODER = &(((uint16_t*)(&GPIOE->MODER))[1]);
 #elif HARDWARE_TYPE == PLUSCART
   #include "stm32f4xx.h"
   volatile uint8_t* const DATA_IDR = ((uint8_t*)(&GPIOC->IDR));
   volatile uint8_t* const DATA_ODR = ((uint8_t*)(&GPIOC->ODR));
   volatile uint16_t* const DATA_MODER = ((uint16_t*)(&GPIOC->MODER));
 #endif
  volatile uint16_t* const ADDR_IDR = ((uint16_t*)(&GPIOD->IDR));
#endif


uint16_t EXIT_SWCHB_ADDR = SWCHB;
