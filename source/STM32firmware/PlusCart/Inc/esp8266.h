/**
 * File:    esp8266.h
 * Author:  Wolfgang Stubig <w.stubig@firmaplus.de>
 * Version: v0.0.1
 *
 * See:     esp8266.c
 *
 * C library for interfacing the ESP8266 WiFi transceiver module (esp-01)
 * with a STM32F4 microcontroller. Should be used with the HAL Library.
 */

#include <stdint.h>
#include <string.h>
#include "stm32f4xx_hal.h"


#ifndef ESP8266_H
#define	ESP8266_H

#ifdef	__cplusplus
extern "C" {
#endif

/** Some constants **/

/* Hash Values of ESP8266 Response messages */
#define ESP8266_NO_RESPONSE                    5381UL // inital hash value
#define ESP8266_OK                          5862591UL // OK
#define ESP8266_READY                  210726483418UL // Ready
#define ESP8266_ERROR                  210672417103UL // Error
//#define ESP8266_WIFI_DISCONNECT 8577780109829502590UL
//#define ESP8266_WIFI_CONNECTED 12557760956336869543UL
//#define ESP8266_WIFI_GOT_IP    13849395132461575191UL
//#define ESP8266_BUSY_SENDING     249883165265657893UL // busy s...
//#define ESP8266_BUSY_PROCESSING  249883165265550082UL // busy p...
#define ESP8266_CONNECT             229419557091567UL
#define ESP8266_CLOSED                6952104274271UL
#define ESP8266_FAIL                     6384029761UL

#define HAL_UART_TIMEOUT_SEND    50
#define HAL_UART_TIMEOUT_RECEIVE 10

#define TRUE    1
#define FALSE   0


/** Should be written by the user for input from / output to the ESP module **/

void Initialize_ESP8266();

/** Function prototypes **/

// Check if the module is started (AT)
_Bool esp8266_is_started(void);
// Restart module (AT+RST)
_Bool esp8266_restart(void);

// Enabled/disable command echoing (ATE)
void esp8266_echo_commands(_Bool);

// Is connected to AP (AT+CWJAP?)
_Bool esp8266_is_connected(void);

// Disconnect from AP (AT+CWQAP)
void esp8266_disconnect(void);

// Print a string to the output
void _esp8266_print(unsigned char *);

// Wait for any response on the input
unsigned long _esp8266_wait_response(uint16_t);

#ifdef	__cplusplus
}
#endif

#endif	/* ESP8266_H */
