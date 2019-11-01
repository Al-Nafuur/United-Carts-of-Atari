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


//**Function to send one byte of date to UART**//
void _esp8266_put_char(unsigned char bt)
{
	 HAL_UART_Transmit(&huart1, &bt, 1, HAL_UART_TIMEOUT_SEND);
}


//**Function to get one byte of date from UART**//
unsigned char _esp8266_get_char(void)
{
	unsigned char c;
	HAL_UART_Receive(&huart1, &c, 1, HAL_UART_TIMEOUT_RECEIVE );
    return c; //receive the value and send it to main function
}


//**Function to convert string to byte**//
void ESP8266_send_string(unsigned char* st_pt)
{
	 HAL_UART_Transmit(&huart1, st_pt, strlen((char *)st_pt), HAL_UART_TIMEOUT_SEND);
}



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

/**
 * Set the WiFi mode.
 *
 * ESP8266_STATION : Station mode
 * ESP8266_SOFTAP : Access point mode
 *
 * This sends the AT+CWMODE command to the ESP module.
 *
 * @param mode an ORed bitmask of ESP8266_STATION and ESP8266_SOFTAP
 */
void esp8266_set_mode(unsigned char mode) {
    _esp8266_print((unsigned char *)"AT+CWMODE=");
    _esp8266_put_char(mode + '0');
    _esp8266_print((unsigned char *)"\r\n");
    _esp8266_wait_response(100);
}

/**
 * Get the WiFi mode.
 *
 * ESP8266_STATION : Station mode
 * ESP8266_SOFTAP : Access point mode
 *
 * This sends the AT+CWMODE? command to the ESP module.
 *
 * @param mode an ORed bitmask of ESP8266_STATION and ESP8266_SOFTAP
 */
/*
unsigned char esp8266_get_mode() {
	char mode;
    _esp8266_print((unsigned char *)"AT+CWMODE?\r\n");
    _esp8266_wait_for((unsigned char *) ':');
    mode = _esp8266_get_char();
    _esp8266_wait_response();
    return mode;
}
*/
/**
 * Connect to an access point.
 *
 * This sends the AT+CWJAP command to the ESP module.
 *
 * @param ssid The SSID to connect to
 * @param pass The password of the network
 * @return an ESP status code, normally either ESP8266_OK or ESP8266_FAIL
 */
unsigned char esp8266_connect(unsigned char* ssid, unsigned char* pass) {
    _esp8266_print((unsigned char *)"AT+CWJAP=\"");
    _esp8266_print(ssid);
    _esp8266_print((unsigned char *)"\",\"");
    _esp8266_print(pass);
    _esp8266_print((unsigned char *)"\"\r\n");
    return _esp8266_wait_response(10000);
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
 * Disconnect from the access point.
 *
 * This sends the AT+CWQAP command to the ESP module.
 */
void esp8266_disconnect(void) {
    _esp8266_print((unsigned char *)"AT+CWQAP\r\n");
    _esp8266_wait_for((unsigned char *)"OK");
}

/**
 * Store the current local IPv4 address.
 *
 * This sends the AT+CIFSR command to the ESP module.
 *
 * The result will not be stored as a string but byte by byte. For example, for
 * the IP 192.168.0.1, the value of store_in will be: {0xc0, 0xa8, 0x00, 0x01}.
 *
 * @param store_in a pointer to an array of the type unsigned char[4]; this
 * array will be filled with the local IP.
 */
void esp8266_ip(unsigned char* store_in) {
    _esp8266_print((unsigned char *)"AT+CIFSR\r\n");
    unsigned char received;
    do {
        received = _esp8266_get_char();
    } while (received < '0' || received > '9');
    for (unsigned char i = 0; i < 4; i++) {
        store_in[i] = 0;
        do {
            store_in[i] = 10 * store_in[i] + received - '0';
            received = _esp8266_get_char();
        } while (received >= '0' && received <= '9');
        received = _esp8266_get_char();
    }
    _esp8266_wait_for((unsigned char *)"OK");
}

/**
 * Open a TCP or UDP connection.
 *
 * This sends the AT+CIPSTART command to the ESP module.
 *
 * @param protocol Either ESP8266_TCP or ESP8266_UDP
 * @param ip The IP or hostname to connect to; as a string
 * @param port The port to connect to
 *
 * @return true iff the connection is opened after this.

_Bool esp8266_start(unsigned char protocol, char* ip, unsigned char port) {
    _esp8266_print((unsigned char *)"AT+CIPSTART=\"");
    if (protocol == ESP8266_TCP) {
        _esp8266_print((unsigned char *)"TCP");
    } else {
        _esp8266_print((unsigned char *)"UDP");
    }
    _esp8266_print((unsigned char *)"\",\"");
    _esp8266_print((unsigned char *)ip);
    _esp8266_print((unsigned char *)"\",");
    unsigned char port_str[5] = "\0\0\0\0";
    sprintf((char *)port_str, "%u", port);
    _esp8266_print(port_str);
    _esp8266_print((unsigned char *)"\r\n");
    if (_esp8266_wait_response() != ESP8266_OK) {
        return FALSE;
    }
    if (_esp8266_wait_response() != ESP8266_CONNECT) {
        return FALSE;
    }
    return TRUE;
}
 */
// Send data (AT+CIPSEND)
/**
 * Send data over a connection.
 *
 * This sends the AT+CIPSEND command to the ESP module.
 *
 * @param data The data to send
 *
 * @return true iff the data was sent correctly.

_Bool esp8266_send(unsigned char* data) {
    unsigned char length_str[6] = "\0\0\0\0\0";
    sprintf((char *)length_str, "%u", strlen((char *)data));
    _esp8266_print((unsigned char *)"AT+CIPSEND=");
    _esp8266_print(length_str);
    _esp8266_print((unsigned char *)"\r\n");
    while (_esp8266_get_char() != '>');
    _esp8266_print(data);
    if (_esp8266_wait_response() == ESP8266_OK) {
        return 1;
    }
    return 0;
}
 */
/**
 * Read a string of data that is sent to the ESP8266.
 *
 * This waits for a +IPD line from the module. If more bytes than the maximum
 * are received, the remaining bytes will be discarded.
 *
 * @param store_in a pointer to a character array to store the data in
 * @param max_length maximum amount of bytes to read in
 * @param discard_headers if set to true, we will skip until the first \r\n\r\n,
 * for HTTP this means skipping the headers.
 */
void esp8266_receive(unsigned char* store_in, uint16_t max_length, _Bool discard_headers) {
    _esp8266_wait_for((unsigned char *)"+IPD,");
    uint16_t length = 0;
    unsigned char received = _esp8266_get_char();
    do {
        length = length * 10 + received - '0';
        received = _esp8266_get_char();
    } while (received >= '0' && received <= '9');

    if (discard_headers) {
        length -= _esp8266_wait_for((unsigned char *)"\r\n\r\n");
    }

    if (length < max_length) {
        max_length = length;
    }

    /*sprintf(store_in, "%u,%u:%c%c", length, max_length, _esp8266_get_char(), _esp8266_get_char());
    return;*/

    uint16_t i;
    for (i = 0; i < max_length; i++) {
        store_in[i] = _esp8266_get_char();
    }
    store_in[i] = 0;
    for (; i < length; i++) {
        _esp8266_get_char();
    }
    _esp8266_wait_for((unsigned char *)"OK");
}

/**
 * Output a string to the ESP module.
 *
 * This is a function for internal use only.
 *
 * @param ptr A pointer to the string to send.
 */
void _esp8266_print(unsigned char *ptr) {
	 HAL_UART_Transmit(&huart1, ptr, strlen((char *)ptr), HAL_UART_TIMEOUT_SEND);
}

/**
 * Wait until we found a string on the input.
 *
 * Careful: this will read everything until that string (even if it's never
 * found). You may lose important data.
 *
 * @param string
 *
 * @return the number of characters read
 */
inline uint16_t _esp8266_wait_for(unsigned char *string) {
    unsigned char so_far = 0;
    unsigned char received;
    uint16_t counter = 0;
    do {
        received = _esp8266_get_char();
        counter++;
        if (received == string[so_far]) {
            so_far++;
        } else {
            so_far = 0;
        }
    } while (string[so_far] != 0);
    return counter;
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
