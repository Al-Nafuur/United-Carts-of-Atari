/**
 * File:    esp8266.h
 * Author:  Wolfgang Stubig <w.stubig@firmaplus.de>
 * Version: v0.0.1
 *
 * structure based on ESP8266_PIC (v0.1) by Camil Staps <info@camilstaps.nl>
 * Website: http://github.com/camilstaps/ESP8266_PIC
 *
 * See:     esp8266.c
 *
 * C library for interfacing the ESP8266 WiFi transceiver module (esp-01)
 * with a STM32F4 microcontroller. Should be used with the HAL Library.
 */

#include <stdint.h>
#include "global.h"


#ifndef ESP8266_H
#define	ESP8266_H

#ifdef	__cplusplus
extern "C" {
#endif

/** API connect/request **/
#define  API_ATCMD_1  "AT+CIPSTART=\"TCP\",\"" PLUSSTORE_API_HOST "\",80\r\n"
#define  API_ATCMD_2  "AT+CIPSEND\r\n"
#define  API_ATCMD_3  "GET /api.php?p="
#define  API_ATCMD_4  " HTTP/1.0\r\nHost: " PLUSSTORE_API_HOST "\r\nPlusStore-ID: v" VERSION " "
#define  API_ATCMD_5  "\r\nConnection: keep-alive\r\n"
#define  API_ATCMD_6a "Range: bytes="
#define  API_ATCMD_6b "\r\n"

/** Some constants **/
#define UDID_TEMPLATE "000000000000000000000000"

/* Hash Values of ESP8266 Response messages */
#define ESP8266_NO_RESPONSE                    5381UL // initial hash value
#define ESP8266_OK                          5862591UL // OK

#define ESP8266_READY                  210726483418UL // ready
#define ESP8266_ERROR                  210672417103UL // ERROR
//#define ESP8266_WIFI_DISCONNECT 8577780109829502590UL
//#define ESP8266_WIFI_CONNECTED 12557760956336869543UL
//#define ESP8266_WIFI_GOT_IP    13849395132461575191UL
//#define ESP8266_BUSY_SENDING     249883165265657893UL // busy s...
//#define ESP8266_BUSY_PROCESSING  249883165265550082UL // busy p...
#define ESP8266_CONNECT             229419557091567UL
#define ESP8266_CLOSED                6952104274271UL
#define ESP8266_FAIL                     6384029761UL
#define ESP8266_WPS_SUCCESS    13356836868472365895UL // wps success,connecting ap ...


#define HAL_UART_TIMEOUT_SEND    50
#define HAL_UART_TIMEOUT_RECEIVE 10

#define MAX_RANGE_SIZE           4096
#define RANGE_BOUNDARY_SIZE        19
#define RANGE_BOUNDARY_TEMPLATE  '_','_','_','_','_','_','_','_','_','_','_','_','_'

#define TRUE    1
#define FALSE   0

typedef struct {
	uint32_t start;
	uint32_t stop;
} http_range;


/** Should be written by the user for input from / output to the ESP module **/

void Initialize_ESP8266(void);

/** Function prototypes **/

_Bool esp8266_PlusStore_API_connect(void);
void esp8266_PlusStore_API_prepare_request_header(char *, _Bool, _Bool );
void esp8266_PlusStore_API_close_connection(void);

int esp8266_PlusROM_API_connect(unsigned int);

uint16_t esp8266_skip_http_response_header(void);

// Check if the module is started (AT)
_Bool esp8266_is_started(void);
// Restart module (AT+RST)
_Bool esp8266_reset(_Bool);
_Bool esp8266_wifi_list(MENU_ENTRY **, int *);
_Bool esp8266_wifi_connect(char *, char *);
_Bool esp8266_wps_connect(void);

uint32_t esp8266_PlusStore_API_range_request( char *, uint32_t, http_range *, uint8_t *);
uint32_t esp8266_PlusStore_API_file_request( uint8_t *, char *, uint32_t, uint32_t );

// Is connected to AP (AT+CWJAP?)
_Bool esp8266_is_connected(void);

// Disconnect from AP (AT+CWQAP)
void esp8266_disconnect(void);

// Print a string to the output
void esp8266_print(unsigned char *);

void generate_udid_string(void);

#ifdef	__cplusplus
}
#endif

#endif	/* ESP8266_H */
