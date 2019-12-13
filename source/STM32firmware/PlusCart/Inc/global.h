#ifndef GLOBAL_H
#define GLOBAL_H

#include <stdint.h>
#include "stm32f4xx_hal.h"

#define VERSION                   "0.8.0"
#define PLUSSTORE_API_HOST        "pluscart.firmaplus.de"

extern UART_HandleTypeDef huart1;
extern uint8_t c;
extern char http_request_header[];

extern uint8_t buffer[];
extern unsigned int cart_size_bytes;
extern uint8_t tv_mode;
#endif // GLOBAL_H
