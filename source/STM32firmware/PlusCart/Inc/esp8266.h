/**
 *
 * See:     esp8266.c
 *
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
#define  API_ATCMD_1a  "AT+CIPSTART=%c,\"TCP\",\"" PLUSSTORE_API_HOST "\",80\r\n"
#define  API_ATCMD_2  "AT+CIPSEND\r\n"
#define  API_ATCMD_3  "GET /api.php?p="
#define  API_ATCMD_4  " HTTP/1.0\r\nHost: " PLUSSTORE_API_HOST "\r\nPlusStore-ID: v" VERSION " "
#define  API_ATCMD_5  "\r\nConnection: keep-alive\r\n"
#define  API_ATCMD_6a "Range: bytes="
#define  API_ATCMD_6b "\r\n"

/* Hash Values of ESP8266 Response messages */
#define ESP8266_NO_RESPONSE                       5381UL // initial hash value
#define ESP8266_OK                             5862591UL // "OK"
#define ESP8266_READY_TO_WRITE_TCP             5861987UL // "> "
#define ESP8266_READY                     210726483418UL // "ready"
#define ESP8266_ERROR                     210672417103UL // "ERROR"
//#define ESP8266_WIFI_DISCONNECT   8577780109829502590UL
//#define ESP8266_WIFI_CONNECTED   12557760956336869543UL
//#define ESP8266_WIFI_GOT_IP      13849395132461575191UL
//#define ESP8266_BUSY_SENDING       249883165265657893UL // busy s...
//#define ESP8266_BUSY_PROCESSING    249883165265550082UL // busy p...
#define ESP8266_SEND_OK                229439828825865UL // "SEND OK"
#define ESP8266_CONNECT                229419557091567UL // "CONNECT"
#define ESP8266_ALREADY_CONNECTED  8346027424717406042UL // "ALREADY CONNECTED"
#define ESP8266_CLOSED                   6952104274271UL // "CLOSED"
#define ESP8266_FAIL                        6384029761UL // "FAIL"
#define ESP8266_WPS_SUCCESS       13356836868472365895UL // "wps success,connecting ap ..."


#define HAL_UART_TIMEOUT_SEND    180
#define HAL_UART_TIMEOUT_RECEIVE 100

#define PLUSSTORE_CONNECT_TIMEOUT          5000
#define PLUSSTORE_RESPONSE_START_TIMEOUT  25000
#define PLUSROM_API_CONNECT_TIMEOUT        PLUSSTORE_CONNECT_TIMEOUT


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

void esp8266_init(void) __attribute__((section(".flash01")));

/** Function prototypes **/

_Bool esp8266_PlusStore_API_connect(void) __attribute__((section(".flash01")));
void esp8266_PlusStore_API_prepare_request_header(char *, _Bool, _Bool ) __attribute__((section(".flash01")));
void esp8266_PlusStore_API_end_transmission(void) __attribute__((section(".flash01")));

int esp8266_PlusROM_API_connect(unsigned int) __attribute__((section(".flash01")));

uint16_t esp8266_skip_http_response_header(void) __attribute__((section(".flash01")));

// Check if the module is started (AT)
_Bool esp8266_is_started(void);
// Restart module (AT+RST)
_Bool esp8266_reset(_Bool) __attribute__((section(".flash01")));
_Bool esp8266_wifi_list(MENU_ENTRY **, int *);
_Bool esp8266_wifi_connect(char *, char *);
_Bool esp8266_wps_connect(void) __attribute__((section(".flash01")));

uint32_t esp8266_PlusStore_API_range_request( char *, uint32_t, http_range *, uint8_t *) __attribute__((section(".flash01")));
uint32_t esp8266_PlusStore_API_file_request( uint8_t *, char *, uint32_t, uint32_t ) __attribute__((section(".flash01")));

// Is connected to AP (AT+CWJAP?)
_Bool esp8266_is_connected(void) __attribute__((section(".flash01")));

// Disconnect from AP (AT+CWQAP)
void esp8266_disconnect(void) __attribute__((section(".flash01")));

// Print a string to the output __attribute__ ((noinline)) ?
void esp8266_print(char *) __attribute__((section(".flash01")));

void esp8266_AT_WiFiManager() __attribute__((section(".flash01")));

void generate_udid_string(void) __attribute__((section(".flash01")));

#ifdef	__cplusplus
}
#endif

#endif	/* ESP8266_H */
