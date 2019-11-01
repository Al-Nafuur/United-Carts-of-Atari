/**
 * File:    esp8266.c
 * Author:  Wolfgang Stubig <w.stubig@firmaplus.de>
 * Version: v0.0.1
 *
 * See:     esp8266.h
 *
 * C library for interfacing the ESP8266 WiFi transceiver module (esp-01)
 * with a STM32F4 microcontroller. Should be used with the HAL Library.
 */

#include "esp8266.h"
#include <string.h>

extern UART_HandleTypeDef huart1;

/**
  * @brief ESP8266 Initialization Function
  * @param None
  * @retval None
  */
void Initialize_ESP8266()
{
	int count = 0;

	// Wait for ATE0 -> OK Response 4 Seconds ?
	HAL_Delay(1500);
	do{
		HAL_Delay(1000);
	    _esp8266_print((unsigned char *)"ATE0\r\n");
	    count++;
	}while(_esp8266_wait_response(100) != ESP8266_OK && count < 4);

	//if(count == 4 )
	// return;

    // connect to accesspoint mode
    _esp8266_print((unsigned char *)"AT+CWMODE=1\r\n");
    _esp8266_wait_response(100);

	// Single connection
    _esp8266_print((unsigned char *)"AT+CIPMUX=0\r\n");
    _esp8266_wait_response(100);

	// Transparent transmission mode (without +IPD,xx:)
    _esp8266_print((unsigned char *)"AT+CIPMODE=1\r\n");
    _esp8266_wait_response(100);

}
//________UART module Initialized__________//


/**
 * Check if the module is started
 *
 * This sends the `AT` command to the ESP and waits until it gets a response.
 *
 * @return true if the module is started, false if something went wrong
 */
_Bool esp8266_is_started(void) {
    _esp8266_print((unsigned char *)"AT\r\n");
    return (_esp8266_wait_response(100) == ESP8266_OK);
}

/**
 * Restart the module
 *
 * This sends the `AT+RST` command to the ESP and waits until there is a
 * response.
 *
 * @return true iff the module restarted properly
 */
_Bool esp8266_restart(void) {
    _esp8266_print((unsigned char *)"AT+RST\r\n");
    if (_esp8266_wait_response(100) != ESP8266_OK) {
        return FALSE;
    }
    return (_esp8266_wait_response(5000) == ESP8266_READY);
}

/**
 * Enable / disable command echoing.
 *
 * Enabling this is useful for debugging: one could sniff the TX line from the
 * ESP8266 with his computer and thus receive both commands and responses.
 *
 * This sends the ATE command to the ESP module.
 *
 * @param echo whether to enable command echoing or not
 */
void esp8266_echo_commands(_Bool echo) {
    if (echo) {
        _esp8266_print((unsigned char *)"ATE1\r\n");
    } else {
        _esp8266_print((unsigned char *)"ATE0\r\n");
    }
    _esp8266_wait_response(100);
}


_Bool esp8266_is_connected(void){
	// Test if Connected to AP (5 Times with 1s delay, for Startup)
	uint8_t tried = 0, count = 0;
	unsigned char c;
    while( ++tried < 5){
    	_esp8266_print((unsigned char *)"AT+CWJAP?\r\n");
		count = 0;
    	while(HAL_UART_Receive(&huart1, &c,1, 10 ) == HAL_OK){
    		count++;
    	}
    	if (count < 30){ // "\r\nOK\r\n" Not Connected !
    		HAL_Delay(1000);
    	}else{
    		return TRUE;
    	}
    }
	return FALSE;
}

/**
 * Output a string to the ESP module.
 * @param ptr A pointer to the string to send.
 */
void _esp8266_print(unsigned char *ptr) {
	 HAL_UART_Transmit(&huart1, ptr, strlen((char *)ptr), HAL_UART_TIMEOUT_SEND);
}


/**
 * Wait until we received the ESP is done and sends its response.
 *
 * This is a function for internal use only.
 *
 * Currently the following responses are implemented:
 *  * OK
 *  * ready
 *  * ERROR
 *  * Busy s...
 *  * Busy p...
 *  * CONNECT
 *  * CLOSE
 *
 * Not implemented yet:
 *  * DNS fail (or something like that)
 *
 * @param timeout uint16_t timeout for HAL_UART_Receive.
 *
 * @return a constant from esp8266.h describing the status response.
 */

unsigned long _esp8266_wait_response(uint16_t timeout) {
    uint8_t counter = 0;
    unsigned long hash = ESP8266_NO_RESPONSE;
    unsigned char c;

    while(HAL_UART_Receive(&huart1, &c, 1, timeout ) == HAL_OK){
		if(c == '\n'){
			if(counter < 8){
				switch (hash){
					case (unsigned long)ESP8266_OK:
					case (unsigned long)ESP8266_CONNECT:
					case (unsigned long)ESP8266_CLOSED:
					case (unsigned long)ESP8266_READY:
					case (unsigned long)ESP8266_ERROR:
					case (unsigned long)ESP8266_FAIL:
//					case (unsigned long)ESP8266_WIFI_DISCONNECT:
//					case (unsigned long)ESP8266_WIFI_CONNECTED:
//					case (unsigned long)ESP8266_WIFI_GOT_IP:
//					case (unsigned long)ESP8266_BUSY_SENDING:
//					case (unsigned long)ESP8266_BUSY_PROCESSING:
						return hash;
						break;
				}
			}
			counter = 0;
			hash = ESP8266_NO_RESPONSE;
		}else if( counter < 8 && c != '\r'){
			counter++;
	        hash = ((hash << 5) + hash) + c; /* hash * 33 + c */
		}
	}
	return hash;
}
