/**
 * File:    esp8266.c
 * Author:  Wolfgang Stubig <w.stubig@firmaplus.de>
 * Version: v0.0.2
 *
 * structure based on ESP8266_PIC (v0.1) by Camil Staps <info@camilstaps.nl>
 * Website: http://github.com/camilstaps/ESP8266_PIC
 *
 * See:     esp8266.h
 *
 * C library for interfacing the ESP8266 WiFi transceiver module (esp-01)
 * with a STM32F4 microcontroller. Should be used with the HAL Library.
 */

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "stm32_udid.h"
#include "esp8266.h"

/* private functions */
void get_boundary_http_header(char *);
// Wait for any response on the input
unsigned long wait_response(uint16_t);


char stm32_udid[] = UDID_TEMPLATE;

_Bool esp8266_PlusStore_API_connect(){
	uint8_t c;


    if(HAL_UART_Transmit(&huart1, (uint8_t *) API_ATCMD_1, sizeof(API_ATCMD_1)-1, 10) != HAL_OK)
		return FALSE;

    // wait for received "Connected\r\n" ?
    while(HAL_UART_Receive(&huart1, &c, 1, 100 ) == HAL_OK);

/*
    if(esp8266_wait_response(100) != ESP8266_CONNECT || ESP8266_Already_CONNECTed){
		return FALSE;
	}
    if(esp8266_wait_response(100) != ESP8266_OK  and ESP826_> ){
		return FALSE;
	}
*/

    if(HAL_UART_Transmit(&huart1, (uint8_t *) API_ATCMD_2, sizeof(API_ATCMD_2)-1, 10) != HAL_OK)
		return FALSE;

    // wait for received ">\r\n" ??
    while(HAL_UART_Receive(&huart1, &c, 1, 100 ) == HAL_OK);

    return TRUE;
}

void esp8266_PlusStore_API_prepare_request_header(char *path, _Bool prepare_range_request){
    // make path http request ready
    for (char* p = path; (p = strchr(p, ' ')); ++p) {
        *p = '+';
    }

    http_request_header[0] = '\0';

    strcat(http_request_header, API_ATCMD_3);
    strcat(http_request_header, path);
    strcat(http_request_header, API_ATCMD_4);
    strcat(http_request_header, stm32_udid);
    strcat(http_request_header, API_ATCMD_5);

    if(prepare_range_request)
        strcat(http_request_header, API_ATCMD_6a);
    else
        strcat(http_request_header, API_ATCMD_6b);
}

void esp8266_PlusStore_API_close_connection(){
	uint8_t c;
    HAL_UART_Transmit(&huart1, (uint8_t *)"+++", sizeof("+++") - 1, 10);
    while(HAL_UART_Receive(&huart1, &c, 1, 100 ) == HAL_OK);
}

uint32_t esp8266_PlusStore_API_range_request(char *path, uint32_t range_count, http_range *range, uint8_t *ext_buffer){
	uint32_t response_size = 0;
	uint16_t expected_size = 0;
	uint8_t c;
	char boundary[] = {'\r','\n','-','-', RANGE_BOUNDARY_TEMPLATE , '\r','\n'};

	esp8266_PlusStore_API_prepare_request_header(path, TRUE );

	for (uint32_t i = 0; i < range_count; i++) {
 	    if (i > 0)
            strcat(http_request_header, ",");
        sprintf(http_request_header, "%s%lu-%lu" ,http_request_header, range[i].start, range[i].stop  );
        expected_size += ( range[i].stop + 1 - range[i].start );
 	}
    strcat(http_request_header, (char *)"\r\n\r\n");

    HAL_UART_Transmit(&huart1, (uint8_t*) http_request_header, strlen(http_request_header), 50);
    if(range_count > 1){
    	get_boundary_http_header(&boundary[4]);
    }
    esp8266_skip_http_response_header(); // skip normal http-header or first boundary + multipart-header
    while( response_size < expected_size ){
    	if(HAL_UART_Receive(&huart1, &c, 1, 15000 ) != HAL_OK){
    		break;
    	}
    	ext_buffer[response_size] = c;
    	if(range_count > 1 && response_size > RANGE_BOUNDARY_SIZE && strncmp((char *) &ext_buffer[response_size - RANGE_BOUNDARY_SIZE], boundary, RANGE_BOUNDARY_SIZE) == 0 ){
   			response_size -= RANGE_BOUNDARY_SIZE;
   			esp8266_skip_http_response_header(); //skip multipart-header
    	}
    	response_size++;
    }

    if(range_count > 1 && response_size > RANGE_BOUNDARY_SIZE){
			response_size -= RANGE_BOUNDARY_SIZE;
    }
    return response_size;
}

uint32_t esp8266_PlusStore_API_file_request(uint8_t *ext_buffer, char *path, uint32_t start_pos, uint32_t length ){
	uint32_t bytes_read = 0;
	uint32_t max_range_pos = start_pos + length - 1;
	uint32_t request_count = ( length + ( MAX_RANGE_SIZE - 1 ) )  / MAX_RANGE_SIZE;
	http_range range[1];

	esp8266_PlusStore_API_connect();
	for (uint32_t i = 0; i < request_count; i++) {
		range[0].start = start_pos + ( i * MAX_RANGE_SIZE);
		range[0].stop = range[0].start + (MAX_RANGE_SIZE -1);
		if(range[0].stop > max_range_pos){
			range[0].stop = max_range_pos;
		}
		bytes_read += esp8266_PlusStore_API_range_request(path, 1, range, &ext_buffer[(range[0].start - start_pos)]);
	}
	esp8266_PlusStore_API_close_connection();
	return bytes_read;
}

int esp8266_PlusROM_API_connect(){
	uint8_t c;
	int offset = strlen((char *)buffer) + 1;

	http_request_header[0] = '\0';
	strcat(http_request_header, (char *)"AT+CIPSTART=\"TCP\",\"");
    strcat(http_request_header, (char *)&buffer[offset]);
    strcat(http_request_header, (char *)"\",80\r\n");

    HAL_UART_Transmit(&huart1, (uint8_t*) http_request_header, strlen(http_request_header), 50);
    HAL_UART_Receive(&huart1, &c, 1, 5000 ); // wait up to 5 seconds for first byte
    while(HAL_UART_Receive(&huart1, &c, 1, 150 ) == HAL_OK){ } // todo wait for "Connected\r\n"

	http_request_header[0] = '\0';
	strcat(http_request_header, (char *)"POST /");
    strcat(http_request_header, (char *)buffer);
    strcat(http_request_header, (char *)" HTTP/1.0\r\nHost: ");
    strcat(http_request_header, (char *)&buffer[offset]);
    strcat(http_request_header, (char *)"\r\nConnection: keep-alive\r\nContent-Type: application/octet-stream\r\nPlusStore-ID: v" VERSION " ");
    strcat(http_request_header, (char *)stm32_udid);
    strcat(http_request_header, (char *)"\r\nContent-Length:    \r\n\r\n");
    offset = strlen(http_request_header);

    HAL_UART_Transmit(&huart1, (uint8_t*) API_ATCMD_2, sizeof(API_ATCMD_2)-1, 20);
    HAL_UART_Receive(&huart1, &c, 1, 5000 ); // wait up to 5 seconds for first byte
    while(HAL_UART_Receive(&huart1, &c, 1, 150 ) == HAL_OK){ } // todo wait for ">\r\n"
    return offset;
}

uint16_t esp8266_skip_http_response_header(){
	int count = 0;
	uint16_t content_length = 0;
	char line[20] = "";
	uint8_t c;
	while(HAL_UART_Receive(&huart1, &c, 1, 15000 ) == HAL_OK){
       	if( c == '\n' ){
       		if (count == 1){
       			break;
       		}else if(count > 16 && strncasecmp("content-length: ", line, 16) == 0){
   		        content_length = (uint16_t) atoi(&line[16]);
       		}
       		count = 0;
       	}else{
       		if(count < 20){
       			line[count] = c;
       		}
       		count++;
       	}
	}
	return content_length;
}

void get_boundary_http_header(char * buffer){
	int count = 0;
	uint8_t c;
	while(HAL_UART_Receive(&huart1, &c, 1, 15000 ) == HAL_OK){
       	if( c == '\n' ){
       		if (count == 1){
       			esp8266_skip_http_response_header(); // first row in multipart response is empty
       			break;
       		}
       		count = 0;
       	}else{
       		if(count > 44 && count < 58){
       			buffer[count - 45] = c;
       		}
       		count++;
       	}
	}
}

/**
  * @brief ESP8266 Initialization Function
  * @param None
  * @retval None
  */
void Initialize_ESP8266()
{
	int count = 0;

	// esp8266 bootup (usually 300ms), wait for ATE0 -> OK response up to 4 Seconds..
	do{
		HAL_Delay(1000);
	    esp8266_print((unsigned char *)"ATE0\r\n");
	}while(wait_response(100) != ESP8266_OK && count++ < 4);

    // connect to accesspoint mode
    esp8266_print((unsigned char *)"AT+CWMODE=1\r\n");
    wait_response(100);

	// Single connection
    esp8266_print((unsigned char *)"AT+CIPMUX=0\r\n");
    wait_response(100);

	// Transparent transmission mode (without +IPD,xx:)
    esp8266_print((unsigned char *)"AT+CIPMODE=1\r\n");
    wait_response(100);

    // wait for esp8266 to connect..
	// Test if connected to AP (6 times with 1s delay, for startup)
	count = 0;
    do{
		HAL_Delay(1000);
    }while( esp8266_is_connected() == FALSE && count++ < 6);

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
    esp8266_print((unsigned char *)"AT\r\n");
    return (wait_response(100) == ESP8266_OK);
}

/**
 * Restart the module
 *
 * This sends the `AT+RST` command to the ESP and waits until there is a
 * response.
 *
 * @return true if the module restarted properly
 */
_Bool esp8266_restart(void) {
    esp8266_print((unsigned char *)"AT+RST\r\n");
    if (wait_response(100) != ESP8266_OK) {
        return FALSE;
    }
    return (wait_response(5000) == ESP8266_READY);
}


_Bool esp8266_wifi_list(MENU_ENTRY **dst, int *num_menu_entries){
	uint8_t  ATCMD1[]  = "AT+CWLAP\r\n", c;
	int count = 0;
	_Bool is_entry_row;
	uint8_t pos = 0;
    if( HAL_UART_Transmit(&huart1, ATCMD1, sizeof(ATCMD1)-1, 10) != HAL_OK){
		return FALSE;
	}
	if(HAL_UART_Receive(&huart1, &c, 1, 15000 ) == HAL_OK){
    	do{
            if(count == 0){ // first char defines if its an entry row with SSID or Header Row
            	is_entry_row = (c == '+' ) ? 1 : 0;
                (*dst)->type = Sub_Menu;
                (*dst)->filesize = 0U;
                pos=0;
                while(pos < 32){
                	(*dst)->entryname[pos++] = 30; // ASCII record separator 32x illegal SSID Char..
                }
                (*dst)->entryname[32] = '\0';
                pos = 0;
            }else if( is_entry_row ){
            	if( count > 10 && count < 43 ){ // Wifi
            		if (c == '"'){ // TODO howto find not escaped " , and \ in ESP8266 CWLAP response !!
            			(*dst)++;
                        (*num_menu_entries)++;
                        count = 43; // ugly
            		}else{
            			(*dst)->entryname[pos++] = c;
            		}
            	}
            }
            if (c == '\n'){
                count = 0;
            }else{
                count++;
            }
    	}while(HAL_UART_Receive(&huart1, &c, 1, 150 ) == HAL_OK);

    	return TRUE;
	}
	return FALSE;
}


_Bool esp8266_wifi_connect(char *ssid, char *password ){
	http_request_header[0] = 0;
    strcat(http_request_header, "AT+CWJAP=\"");
    strcat(http_request_header, ssid);
    strcat(http_request_header, "\",\"");
    strcat(http_request_header, password);
    strcat(http_request_header, "\"\r\n");
	HAL_UART_Transmit(&huart1, (uint8_t *) http_request_header, strlen(http_request_header), 50);
	if(wait_response(15000) == ESP8266_OK){
    	return TRUE;
    	/*  WIFI CONNECTED<\r><\n>
    	 *  WIFI GOT IP<\r><\n>
    	 *  <\r><\n>
    	 *  OK
    	 */
	}
	return FALSE;
}

_Bool esp8266_is_connected(void){
	uint8_t count = 0;
	unsigned char c;
   	esp8266_print((unsigned char *)"AT+CWJAP?\r\n");
	count = 0;
   	if(HAL_UART_Receive(&huart1, &c,1, 150 ) == HAL_OK){
   		while(HAL_UART_Receive(&huart1, &c,1, 10 ) == HAL_OK){
   	   		count++;
   		}
   	}
   	return (count > 28); // "No AP\r\n\r\nOK\r\n" -> Not Connected !
}

/**
 * Output a string to the ESP module.
 * @param ptr A pointer to the string to send.
 */
void esp8266_print(unsigned char *ptr) {
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

unsigned long wait_response(uint16_t timeout) {
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

void generate_udid_string(){
	int i;
	uint8_t c;
	for (int j = 2; j > -1; j--){
		uint32_t content_len = STM32_UDID[j];
		i = (j * 8) + 7;
		while (content_len != 0 && i > -1) {
			c = content_len % 16;
			stm32_udid[i--] = (c > 9)? (c-10) + 'a' : c + '0';
			content_len = content_len/16;
		}
	}
}
