/**
 * File:    esp8266.c
 * Author:  Wolfgang Stubig <w.stubig@firmaplus.de>
 * Version: v0.0.4
 *
 * structure based on ESP8266_PIC (v0.1) by Camil Staps <info@camilstaps.nl>
 * Website: http://github.com/camilstaps/ESP8266_PIC
 *
 * ESP8266 AT WiFi Manager templates based on:
 * https://github.com/tzapu/WiFiManager
 *
 * ESP8266 AT Webserver code inspired by:
 * https://os.mbed.com/users/programmer5/code/STM32-ESP8266-WEBSERVER//file/89cb04c5c613/main.cpp/
 *
 * C library for interfacing the ESP8266 WiFi transceiver module (esp-01)
 * with a STM32F4 micro controller. Should be used with the HAL Library.
 */
#include "global.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "stm32_udid.h"
#include "esp8266_AT_WifiManager.h"
#include "esp8266.h"
#include "md5.h"
#include "flash.h"

extern UART_HandleTypeDef huart1;

/* private functions */
uint64_t wait_response(uint32_t) __attribute__((section(".flash01")));
void set_standard_mode(void) __attribute__((section(".flash01")));
uint64_t esp8266_send_command(char *command, uint32_t timeout) __attribute__((section(".flash01")));

/* AT WiFi Manager */
void handle_http_requests() __attribute__((section(".flash01")));
uint8_t process_http_headline() __attribute__((section(".flash01")));
void send_requested_page_to_client(char id, const char* page, unsigned int len, bool close_connection) __attribute__((section(".flash01")));
void get_http_request_url_param_values(url_param * param_array , int len) __attribute__((section(".flash01")));
void generate_html_wifi_list(void) __attribute__((section(".flash01")));
void generate_html_wifi_info(void) __attribute__((section(".flash01")));
inline int ishex(char x) __attribute__((section(".flash01")));
void uri_decode( char *s ) __attribute__((section(".flash01")));
void connect_tcp_link(char link_id ) __attribute__((section(".flash01")));
bool init_send_tcp_link(char link_id, uint16_t bytes_to_send) __attribute__((section(".flash01")));
void close_tcp_link(char link_id) __attribute__((section(".flash01")));

char tmp_uart_buffer[50];
char esp8266_at_version[15];


int esp8266_file_list( char *path, MENU_ENTRY **dst, int *num_menu_entries, uint8_t *plus_store_status, char * status_message){
	int char_counter = 0, trim_path = 0;
	bool is_entry_row, is_status_row;
	uint8_t pos = 0, c;
	if( esp8266_PlusStore_API_connect() ){
		esp8266_PlusStore_API_prepare_request_header(path, false);

		esp8266_print(http_request_header);
		uint16_t bytes_read = 0, content_length = esp8266_skip_http_response_header();
		is_status_row = true;
		while(bytes_read < content_length){
			if(HAL_UART_Receive(&huart1, &c, 1, 15000 ) != HAL_OK){
				break;
			}
			if(is_status_row){
				if (c == '\n'){
					is_status_row = false;
					status_message[pos] = '\0';
					pos = 0;
				}else if(bytes_read < 1){
					plus_store_status[bytes_read] = (uint8_t)c;
				}else if(bytes_read < 2){
					trim_path = c - '0';
				}else{
					status_message[pos++] = c;
				}


			}else if((*num_menu_entries) < NUM_MENU_ITEMS){
				if(char_counter == 0){ // first char defines if its an entry row
					is_entry_row = (c >= '0' && c <= '9' ); // First char is entry.type '0' to '9'
					if(is_entry_row){
						(*dst)->type = c - 48;
					}
				}else if( is_entry_row ){
					if(char_counter == 1){
						(*dst)->filesize = 0U;
						pos = 0;
					}else if( char_counter < 8 ){ // get the filesize
						(*dst)->filesize = (*dst)->filesize * 10 + (uint8_t)( c - '0' );
					}else if( char_counter > 8 && char_counter < 41 && c != '\n'){ // filename/dirname should begin at index 9
						(*dst)->entryname[pos] = c;
						pos++;
					}
				}
				if (c == '\n'){
					if(is_entry_row){
						(*dst)->entryname[pos] = '\0';
						(*dst)->font = user_settings.font_style;
						(*dst)++;
						(*num_menu_entries)++;
					}
					char_counter = 0;
				}else{
					char_counter++;
				}
			}
			bytes_read++;
		}

		esp8266_PlusStore_API_end_transmission();
	}
	return trim_path;
}

void check_api_host(){
	if(user_settings.api_host[0] == 0xff){
		strcpy(user_settings.api_host, PLUSSTORE_API_HOST);
		flash_set_eeprom_user_settings(user_settings);
	}
}

bool esp8266_PlusStore_API_connect(){
	uint8_t c;
	while(HAL_UART_Receive(&huart1, &c, 1, 10 ) == HAL_OK);// first read old messages..

	http_request_header[0] = '\0';

    strcat(http_request_header, API_ATCMD_1);
    check_api_host();
    strcat(http_request_header, user_settings.api_host);
    strcat(http_request_header, API_ATCMD_1b);

	uint64_t resp = esp8266_send_command(http_request_header, PLUSSTORE_CONNECT_TIMEOUT);
	if( resp == ESP8266_CONNECT || resp == ESP8266_ALREADY_CONNECTED){
		esp8266_send_command(API_ATCMD_2, 200);
	    return true;
	}
    return false;
}

void esp8266_PlusStore_API_prepare_request_header(char *path, bool prepare_range_request){

	// ' ' --> '+' last check no space in http GET request!
	for (char* p = path; (p = strchr(p, ' ')); *p++ = '+');


    http_request_header[0] = '\0';

    strcat(http_request_header, API_ATCMD_3);
    strcat(http_request_header, path);
    strcat(http_request_header, API_ATCMD_4);
    check_api_host();
    strcat(http_request_header, user_settings.api_host);
    strcat(http_request_header, API_ATCMD_5);
    strcat(http_request_header, stm32_udid);
    strcat(http_request_header, API_ATCMD_6);

    size_t header_len = strlen(http_request_header);
    itoa(user_settings.first_free_flash_sector, (char *)&http_request_header[header_len++], 16); // 5 - C
    http_request_header[header_len++] = ',';
    itoa(user_settings.font_style, &http_request_header[header_len++], 10);                      // 0 - 3
    http_request_header[header_len++] = ',';
    itoa(user_settings.line_spacing, &http_request_header[header_len++], 10);                    // 0 - 2
    http_request_header[header_len++] = ',';
    itoa(user_settings.tv_mode, (char *)&http_request_header[header_len++], 10);                 // 1 - 3
    http_request_header[header_len] = '\0';

    if(STM32F4_FLASH_SIZE > 512U)
        strcat(http_request_header, ",1, ");
    else
        strcat(http_request_header, ",0, ");

    itoa(( HARDWARE_TYPE - 1 + (( MENU_TYPE - 1 ) << 1 ) + ( USE_SD_CARD << 2) + ( USE_WIFI << 3 )),
    		(char *)&http_request_header[(header_len+3)], 16);									// 0 - F

    strcat(http_request_header, API_ATCMD_7);

    if(prepare_range_request)
        strcat(http_request_header, API_ATCMD_8);
    else
        strcat(http_request_header, API_ATCMD_9);
}

void esp8266_PlusStore_API_end_transmission(){
	HAL_Delay(50);
	esp8266_send_command("+++", 1000);
	HAL_Delay(1200); // After "+++", please wait at least 1 second before sending next AT command.
	esp8266_send_command("AT+CIPCLOSE\r\n", 15000);
}

uint32_t esp8266_PlusStore_API_range_request(char *path, http_range range, uint8_t *ext_buffer){
	uint32_t response_size = 0;
	uint16_t expected_size =  (uint16_t) ( range.stop + 1 - range.start );
	uint8_t c;

	esp8266_PlusStore_API_prepare_request_header(path, true);

    sprintf(http_request_header, "%s%lu-%lu", http_request_header, range.start, range.stop);
    strcat(http_request_header, (char *)"\r\n\r\n");

	esp8266_print(http_request_header);

    esp8266_skip_http_response_header();
    while( response_size < expected_size ){
    	if(HAL_UART_Receive(&huart1, &c, 1, 15000 ) != HAL_OK){
    		break;
    	}
    	ext_buffer[response_size] = c;
    	response_size++;
    }

    return response_size;
}

uint32_t esp8266_PlusStore_API_file_request(uint8_t *ext_buffer, char *path, uint32_t start_pos, uint32_t length ){
	uint32_t bytes_read = 0, chunk_read = 0;
	uint32_t max_range_pos = start_pos + length - 1;
	uint32_t request_count = ( length + ( MAX_RANGE_SIZE - 1 ) )  / MAX_RANGE_SIZE;
	http_range range;

	esp8266_PlusStore_API_connect();
	for (uint32_t i = 0; i < request_count; i++) {
		range.start = start_pos + ( i * MAX_RANGE_SIZE);
		range.stop = range.start + (MAX_RANGE_SIZE -1);
		if(range.stop > max_range_pos){
			range.stop = max_range_pos;
		}
		chunk_read = esp8266_PlusStore_API_range_request(path, range, &ext_buffer[(range.start - start_pos)]);
		bytes_read += chunk_read;
		if(chunk_read != ( range.stop + 1 - range.start ))
			break;
	}
	esp8266_PlusStore_API_end_transmission();
	return bytes_read;
}

int esp8266_PlusROM_API_connect(unsigned int size){
	uint16_t * nmi_p = (uint16_t * )&buffer[size - 6];
	int i = nmi_p[0] - 0x1000;
	unsigned char device_id_hash[16];
	int offset = (int)strlen((char *)&buffer[i]) + 1 + i;

	md5( (unsigned char *)stm32_udid, 24, device_id_hash);

    esp8266_send_command("AT+CIPCLOSE\r\n", 5000);

    http_request_header[0] = '\0';
	strcat(http_request_header, (char *)"AT+CIPSTART=\"TCP\",\"");
    strcat(http_request_header, (char *)&buffer[offset]);
    strcat(http_request_header, (char *)"\",80,1\r\n");

    esp8266_send_command(http_request_header, PLUSROM_API_CONNECT_TIMEOUT);

	http_request_header[0] = '\0';
	strcat(http_request_header, (char *)"POST /");
    strcat(http_request_header, (char *)&buffer[i]);
    strcat(http_request_header, (char *)" HTTP/1.0\r\nHost: ");
    strcat(http_request_header, (char *)&buffer[offset]);
    strcat(http_request_header, (char *)"\r\nConnection: keep-alive\r\n"
                                        "Content-Type: application/octet-stream\r\n"
                                        "PlusROM-Info: agent=PlusCart;ver=" VERSION ";id=");

    char *ptr = &http_request_header[strlen(http_request_header)];
    for (i = 0; i < 16; i++) {
        ptr += sprintf(ptr, "%02X", device_id_hash[i]);
    }

    strcat(http_request_header, (char *)";nick=\r\nContent-Length:    \r\n\r\n");
    offset = (int)strlen(http_request_header);

    esp8266_send_command(API_ATCMD_2, 5000);
    return offset;
}

uint16_t esp8266_skip_http_response_header(){
	int count = 0;
	uint16_t content_length = 0;
	uint8_t c;
	while(HAL_UART_Receive(&huart1, &c, 1, PLUSSTORE_RESPONSE_START_TIMEOUT ) == HAL_OK){
       	if( c == '\n' ){
       		if (count == 1){
       			break;
       		}else if(count > 16 && strncasecmp("content-length: ", tmp_uart_buffer, 16) == 0){
   		        content_length = (uint16_t) atoi(&tmp_uart_buffer[16]);
       		}
       		count = 0;
       	}else{
       		if(count < 21){
       			tmp_uart_buffer[count] = c;
       		}
       		count++;
       	}
	}
	return content_length;
}

/**
  * @brief ESP8266 Initialization Function
  * @param None
  * @retval None
  */
void esp8266_init()
{
	int count = 0;

	// esp8266 bootup (usually 300ms), wait for ATE0 -> OK response up to 4 Seconds..
	do{
		HAL_Delay(1000);
	}while(esp8266_send_command("ATE0\r\n", 200) != ESP8266_OK && count++ < 4);

	set_standard_mode();

    // wait for esp8266 to connect..
	// Test if connected to AP (6 times with 1s delay, for startup)
	count = 0;
    do{
		HAL_Delay(1000);
    }while( esp8266_is_connected() == false && count++ < 6);

}
//________UART module Initialized__________//

void esp8266_update()
{
	uint8_t c;
	//wait 2 seconds
	HAL_Delay(2000);

	while(HAL_UART_Receive(&huart1, &c, 1, 10 ) == HAL_OK);// first read old messages..

	if(esp8266_send_command("AT+CIUPDATE\r\n", 120000) != ESP8266_OK ) // wait 2 minutes max for firmware download and flashing
		return;
	// Update success wait for ESP8266 reboot (we don't monitor ESP8266_WIFI_DISCONNECT).
	if( wait_response(15000) != ESP8266_READY)
		return;
	 wait_response(7000); // wait for reconnect to WiFi

	 read_esp8266_at_version(); // read (hopefully) new AT version

	 esp8266_init(); // redo init
}

uint64_t esp8266_send_command(char *command, uint32_t timeout){
    esp8266_print(command);
    return wait_response(timeout);
}

void set_standard_mode(void){
    // connect to accesspoint mode
	esp8266_send_command("AT+CWMODE=1\r\n", 200);

	// Single connection
	esp8266_send_command("AT+CIPMUX=0\r\n", 200);

	// Transparent transmission mode (without +IPD,xx:)
	esp8266_send_command("AT+CIPMODE=1\r\n", 200);
}

/**
 * Check if the module is started
 *
 * This sends the `AT` command to the ESP and waits until it gets a response.
 *
 * @return true if the module is started, false if something went wrong
 */
bool esp8266_is_started(void) {
	return (esp8266_send_command("AT\r\n", 200) == ESP8266_OK);
}

/**
 * Restart or Restore the module
 *
 * This sends the `AT+RST` or `AT+RESTORE` command to the ESP and waits until there is a
 * response.
 *
 * @return true if the module restarted / reseted properly
 */
bool esp8266_reset(bool factory_reset) {
    if(factory_reset)
    	esp8266_send_command("AT+RESTORE\r\n", 200);
	else
		esp8266_send_command("AT+RST\r\n", 200);

    wait_response(5000); // == ESP8266_READY
    esp8266_send_command("ATE0\r\n", 200);
	set_standard_mode();
	return true;
}


bool esp8266_wifi_list(MENU_ENTRY **dst, int *num_menu_entries){
	int count = 0;
	bool is_entry_row;
	uint8_t pos = 0, c;

	esp8266_print("AT+CWLAP\r\n");

	if(HAL_UART_Receive(&huart1, &c, 1, 15000 ) == HAL_OK){
    	do{
            if(count == 0){ // first char defines if its an entry row with SSID or Header Row
            	is_entry_row = (c == '+' ) ? 1 : 0;
            	if(is_entry_row){
                    (*dst)->type = Input_Field;
                    (*dst)->filesize = 0U;
                    memset((*dst)->entryname, 30 , 32);
                    (*dst)->entryname[32] = '\0';
                    pos = 0;
            	}
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

    	return true;
	}
	return false;
}


bool esp8266_wifi_connect(char *ssid, char *password ){
	http_request_header[0] = 0;
    strcat(http_request_header, "AT+CWJAP=\"");
    strcat(http_request_header, ssid);
    strcat(http_request_header, "\",\"");
    strcat(http_request_header, password);
    strcat(http_request_header, "\"\r\n");

	if(esp8266_send_command(http_request_header, 15000) == ESP8266_OK){
    	return true;
	}
	return false;
}

bool esp8266_wps_connect(){
	if(esp8266_send_command("AT+WPS=1\r\n", 1000) == ESP8266_OK){
		if(wait_response(130000) == ESP8266_WPS_SUCCESS){
			return true;
 		}
	}
	return false;
}

bool esp8266_is_connected(void){
	uint8_t count = 0;
	unsigned char c;
   	esp8266_print("AT+CWJAP?\r\n");
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
void esp8266_print(char *ptr) {
	 HAL_UART_Transmit(&huart1, (uint8_t *)ptr, (uint16_t)strlen((char *)ptr), HAL_UART_TIMEOUT_SEND);
}


/*
 *
 * ESP8266 AT WiFi Manager Portal
 *
 */

void esp8266_AT_WiFiManager(){
	esp8266_send_command("AT+CIPCLOSE\r\n", 5000);	        // close all connections.
	esp8266_send_command("AT+CWMODE=3\r\n", 5000);	        // enable AccessPoint + Station mode.
    esp8266_send_command("AT+CWSAP=\"PlusCart(+)\",\"\",1,0\r\n", 5000);	// set SSID.
    esp8266_send_command("AT+CIPMODE=0\r\n", 5000);	        // not transparent transmission
    esp8266_send_command("AT+CIPMUX=1\r\n", 5000);	        // enable multiple connections
    esp8266_send_command("AT+CIPSERVERMAXCONN=1\r\n", 5000);// set max connections
    esp8266_send_command("AT+CIPSERVER=1,80\r\n", 5000);	// start server at port 80:
    esp8266_send_command("AT+CIPSTO=30\r\n",5000);          // Server timeout=30 seconds
    handle_http_requests();
	esp8266_send_command("AT+CIPSERVER=0\r\n", 200);        // disable server
	esp8266_send_command("AT+CIPMUX=0\r\n", 200);           // Single connection
	esp8266_send_command("AT+CWMODE=1\r\n", 5000);	        // disable AccessPoint mode.
	esp8266_reset(false);
	HAL_Delay(4000);
}

void handle_http_requests(){
    unsigned char c;
    const char request_start[] = "+IPD,";
    uint8_t state = 0;
    uint32_t timeout, reqLinBuffIndex = 0;

    while( state < 7 ){
    	timeout = 5000;
		while( HAL_UART_Receive(&huart1, &c, 1, timeout ) == HAL_OK  ){
			timeout = 50;
			if(state == 5){
				if(c != '\r'){
					buffer[reqLinBuffIndex++] = c;
				}else{
					buffer[reqLinBuffIndex] = '\0';
					reqLinBuffIndex = 0;
					esp8266_skip_http_response_header();
					state = process_http_headline();
				}
			}else if(c == request_start[state]){
				state++;
			}else{
				state = 0;
			}
		}
    }
}

uint8_t process_http_headline(){
    char linkId = (char)buffer[0];
    uint8_t status = 0, response_page = http_page_not_found;

    if(strlen((char *)buffer) > 17){ //smallest valid http header = "0,xx:GET / HTTP/x.x"
        if(strstr((char *)buffer, GET_ROOT) || strstr((char *)buffer, GET_INDEX_HTML) ){
        	response_page = http_page_start;
        }else if(strstr((char *)buffer, GET_FAVICON_ICO) ){
        	response_page = http_favicon_ico;
        }else if(strstr((char *)buffer, " " GET_EXIT) ){
        	response_page = http_page_exit;
            status = 7;
        }else if(strstr((char *)buffer, " "GET_SAVE"?") ){

            url_param p_array[3] = {{"s="},{"p="}};
            get_http_request_url_param_values( p_array, 2);

        	response_page = http_page_save;
        	esp8266_wifi_connect(p_array[0].value, p_array[1].value);

        }else if(strstr((char *)buffer, " "GET_NO_SCAN) ){
        	response_page = http_page_wifi_no_scan;
        }else if(strstr((char *)buffer, " "GET_INFO) ){
        	response_page = http_page_info;
           	generate_html_wifi_info();
        }else if(strstr((char *)buffer, " "GET_WIFI) ){
        	response_page = http_page_wifi;
        	generate_html_wifi_list();
        }else if(strstr((char *)buffer, " "GET_PLUS_CONNECT) ){
        	response_page = http_page_plus_connect;
        }else if(strstr((char *)buffer, " "GET_SAVE_CONNECT) ){
            char cur_path[128] = URLENCODE_MENU_TEXT_SETUP "/" URLENCODE_MENU_TEXT_PLUS_CONNECT "/";
            uint8_t c;
            url_param p_array[3] = {{"s="}};
            char send_link_id = (char)(linkId + 1);

            if(send_link_id > '3')
            	send_link_id = '0';

            get_http_request_url_param_values( p_array, 1);

        	strncat(cur_path, p_array[0].value, (127 - sizeof(URLENCODE_MENU_TEXT_SETUP "/" URLENCODE_MENU_TEXT_PLUS_CONNECT "/") ) );
        	strcat(cur_path, "/Enter");

			esp8266_PlusStore_API_prepare_request_header(cur_path, false );
			connect_tcp_link(send_link_id);
			init_send_tcp_link(send_link_id, (uint16_t)strlen(http_request_header));
			esp8266_print(http_request_header);
        	esp8266_skip_http_response_header();
        	while(HAL_UART_Receive(&huart1, &c, 1, 100 ) == HAL_OK){}
        	if(c == '0'){
        		response_page = http_page_plus_failed;
        	}else if(c == '1'){
        		response_page = http_page_plus_created;
        	}else{
        		response_page = http_page_plus_connected;
        	}
			close_tcp_link(send_link_id);
       }
    }

    if(response_page == http_favicon_ico ){
    	send_requested_page_to_client(linkId, favicon_ico, sizeof(favicon_ico), true);
    }else if(response_page == http_page_not_found){
    	send_requested_page_to_client(linkId, not_found_text, sizeof(not_found_text)-1, true);
    }else{
    	send_requested_page_to_client(linkId, http_header_html, sizeof(http_header_html) - 1, false);
       	send_requested_page_to_client(linkId, html_head, sizeof(html_head) - 1, false);
       	if(response_page == http_page_wifi || response_page == http_page_info){
           	send_requested_page_to_client(linkId, (char *)buffer, strlen((char *)buffer), false);
       	}
       	if(response_page == http_page_wifi  || response_page == http_page_wifi_no_scan){
           	send_requested_page_to_client(linkId, html_form, sizeof(html_form) - 1, false);
       	}

       	if(response_page == http_page_save ){
          	send_requested_page_to_client(linkId, html_saved, sizeof(html_saved) - 1, false);
       	}else if(response_page == http_page_exit ){
           	send_requested_page_to_client(linkId, html_exit, sizeof(html_exit) - 1, false);
       	}else if(response_page == http_page_start ){
           	send_requested_page_to_client(linkId, html_portal_options, sizeof(html_portal_options) - 1, false);
           	if(esp8266_is_connected()){
               	send_requested_page_to_client(linkId, html_plus_connect, sizeof(html_plus_connect) - 1, false);
           	}
       	}else if(response_page == http_page_plus_connect ){
           	send_requested_page_to_client(linkId, html_connect_form, sizeof(html_connect_form) - 1, false);
       	}else if(response_page == http_page_plus_failed ){
           	send_requested_page_to_client(linkId, html_plus_failed, sizeof(html_plus_failed) - 1, false);
       	}else if(response_page == http_page_plus_created ){
           	send_requested_page_to_client(linkId, html_plus_created, sizeof(html_plus_created) - 1, false);
       	}else if(response_page == http_page_plus_connected ){
           	send_requested_page_to_client(linkId, html_plus_connected, sizeof(html_plus_connected) - 1, false);
       	}

       	if(response_page != http_page_start && response_page != http_page_exit){
           	send_requested_page_to_client(linkId, html_back, sizeof(html_back) - 1, false);
       	}
       	send_requested_page_to_client(linkId, html_end, sizeof(html_end) - 1, true);
    }
    return status;
}

void send_requested_page_to_client(char id, const char* page, unsigned int len, bool close_connection)
{
	uint16_t len_of_package_to_TX;
    unsigned int page_to_send_address = 0;

    while(len > 0)
    {
        if(len > 2048){
            len -= 2048;
            len_of_package_to_TX = 2048;
        }
        else{
            len_of_package_to_TX = (uint16_t) len;
            len = 0;
        }

        init_send_tcp_link(id, len_of_package_to_TX);

       	HAL_UART_Transmit(&huart1, (uint8_t *)&page[page_to_send_address], len_of_package_to_TX, 500);
        if(wait_response(15000) != ESP8266_SEND_OK)  // link broken, don't send more data to this link.
            break;
        page_to_send_address += len_of_package_to_TX;
    }

    if(close_connection){
    	close_tcp_link(id);
    }
}

void get_http_request_url_param_values(url_param * param_array , int len){
    char *t;

    for (int i=0; i<len; i++){
        if( (param_array[i].value = strstr((char *)buffer, param_array[i].param)) ){
            param_array[i].value += 2;
        }
    }

    for (int i=0; i<len; i++){
        if(param_array[i].value){
        	while( (t = strstr(param_array[i].value, "&")) )
        		t[0] = '\0';
        	while( (t = strstr(param_array[i].value, " ")) )
            	t[0] = '\0';
        	uri_decode(param_array[i].value);
        }
    }
}

int ishex(char x){
	return (x >= '0' && x <= '9') || (x >= 'a' && x <= 'f') || (x >= 'A' && x <= 'F');
}

void uri_decode( char *s ){
	int len = (int) strlen(s);
	int c;
	int s_counter = 0, d_counter = 0;

	for (; s_counter < len; s_counter++) {
		c = s[s_counter];
		if (c == '+'){
            c = ' ';
		}else if (c == '%' && ( !ishex(s[++s_counter]) || !ishex(s[++s_counter]) || !sscanf(&s[s_counter - 1], "%2x", &c))){
			return;
		}
		s[d_counter++] = (char) c;
	}
	s[d_counter] = '\0';
}

void generate_html_wifi_list(void){
	int count = 0, quality = 0;
	uint8_t row_state, c;
	uint16_t pos = 0;
	char network_type[2];
	buffer[0] = '\0';

	esp8266_print("AT+CWLAP\r\n");

	if(HAL_UART_Receive(&huart1, &c, 1, 15000 ) == HAL_OK){
    	do{
            if(count == 0 && row_state < 100){ // first char defines if its an entry row with SSID or Header Row
            	if(c == '\r')
            		row_state = 100;
            	row_state = (c == '+' ) ? 1 : 0;
            	if(row_state == 1){
                	strcat((char *)buffer, "<div><a href=\"#p\" onclick=\"c(this)\">");
                	pos = (uint16_t)strlen((char *)buffer);
                	quality = 0;
            	}
            }else if( row_state > 0 ){
            	if( row_state == 1 && count == 8 ){                       // WiFi encryption method
            		network_type[0] = (c > '0')?'l':' ';
            		network_type[1] = '\0';
            		row_state++;
            	}else if( row_state == 2  && count > 10){                 // WiFiSSID Name
            		if (c == '"'){
            			buffer[pos] = '\0';
            			strcat((char *)buffer, "</a>&nbsp;<span class=\"q ");
            			strcat((char *)buffer, network_type);
            			strcat((char *)buffer, "\">");
            			row_state++;
            			count = 50;
            		}else{
            			buffer[pos++] = c;
            		}
            	}else if( row_state == 3 && count > 52){                  // Wifi Quality %
            		if(c == ','){
            			if (quality <= -100) {
            			    quality = 0;
            			} else if (quality >= -50) {
            			    quality = 100;
            			} else {
            			    quality = 2 * (quality + 100);
            			}
            			itoa(quality, (char *)&buffer[strlen((char *)buffer)], 10);
            			strcat((char *)buffer, "%</span></div>");
            			row_state++;
            		}else{
                		quality = (quality * 10) - (c - '0');
            		}
            	}
            }
            if (c == '\n'){
                count = 0;
            }else{
                count++;
            }
    	}while(HAL_UART_Receive(&huart1, &c, 1, 150 ) == HAL_OK);
	}
}

void generate_html_wifi_info(void){
	int count = 0, quality = 0;
	uint8_t row_state, c;
	uint16_t pos = 5;
	buffer[0] = '\0';

	strcat((char *)buffer, "<div>");

	esp8266_print("AT+CWJAP?\r\n");

	if(HAL_UART_Receive(&huart1, &c, 1, 15000 ) == HAL_OK){
    	do{
            if(count == 0 ){ // first char defines if its an entry row with SSID or Header Row
            	row_state = (c == '+' ) ? 1 : 0;
            	if(row_state == 0){
            		strcat((char *)buffer, "Not Connected</div>");
            	}
            }else if( row_state > 0  && row_state < 3){
            	if( row_state == 1  && count > 7){                       // WiFiSSID Name
            		if (c == '"'){
            			buffer[pos] = '\0';
            			strcat((char *)buffer, "&nbsp;<span class=\"q\">");
            			count = 50;
            			row_state++;
            		}else{
            			buffer[pos++] = c;
            		}
            	}else if( row_state == 2 && count > 74){                  // Wifi Quality %
            		if(c == '\r'){
            			if (quality <= -100) {
            			    quality = 0;
            			} else if (quality >= -50) {
            			    quality = 100;
            			} else {
            			    quality = 2 * (quality + 100);
            			}
            			itoa(quality, (char *)&buffer[strlen((char *)buffer)], 10);
            			strcat((char *)buffer, "%</span></div>");
            			row_state++;
            		}else{
                		quality = (quality * 10) - (c - '0');
            		}
            	}
            }
            count++;
    	}while(HAL_UART_Receive(&huart1, &c, 1, 150 ) == HAL_OK);
	}
}

void connect_tcp_link(char link_id ){;
	sprintf(tmp_uart_buffer, API_ATCMD_1a, link_id);
	esp8266_send_command(tmp_uart_buffer, PLUSSTORE_CONNECT_TIMEOUT);
}

bool init_send_tcp_link(char link_id, uint16_t bytes_to_send){
	sprintf(tmp_uart_buffer, "AT+CIPSEND=%c,%d\r\n", link_id, bytes_to_send);
    if(esp8266_send_command(tmp_uart_buffer, 2000) == ESP8266_OK){
    	wait_response(200); // "> "
    	return true;
    }
    return false;
}

void close_tcp_link(char link_id){
	sprintf(tmp_uart_buffer, "AT+CIPCLOSE=%c\r\n", link_id);
	esp8266_send_command(tmp_uart_buffer, 5000);
}

/**
 * Wait until we received the ESP is done and sends its response.
 *
 * This is a function for internal use only.
 *
 * @param timeout uint16_t timeout for HAL_UART_Receive.
 *
 * @return a constant from esp8266.h describing the status response.
 */

uint64_t wait_response(uint32_t timeout) {
    uint8_t counter = 0;
    uint64_t hash = ESP8266_NO_RESPONSE;
    unsigned char c;

    while(HAL_UART_Receive(&huart1, &c, 1, timeout ) == HAL_OK){
//    	do{
			if(c == '\n'){
				if(counter < 30){ // wps success,connecting ap ...== 29 !
					switch (hash){
						case (uint64_t)ESP8266_OK:
						case (uint64_t)ESP8266_CONNECT:
						case (uint64_t)ESP8266_READY:
						case (uint64_t)ESP8266_ERROR:
						case (uint64_t)ESP8266_FAIL:
						case (uint64_t)ESP8266_ALREADY_CONNECTED:
						case (uint64_t)ESP8266_WPS_SUCCESS:
						case (uint64_t)ESP8266_SEND_OK:
						case (uint64_t)ESP8266_CLOSED:
						case (uint64_t)ESP8266_READY_TO_WRITE_TCP:
	//					case (uint64_t)ESP8266_WIFI_DISCONNECT:
	//					case (uint64_t)ESP8266_WIFI_CONNECTED:
	//					case (uint64_t)ESP8266_WIFI_GOT_IP:
	//					case (uint64_t)ESP8266_BUSY_SENDING:
	//					case (uint64_t)ESP8266_BUSY_PROCESSING:
							return hash;
						default:
							break;
					}
				}
				counter = 0;
				hash = ESP8266_NO_RESPONSE;
			}else if( counter < 30 && c != '\r'){
				counter++;
				hash = ((hash << 5) + hash) + c;
				if(hash == ESP8266_READY_TO_WRITE_TCP)
					break;
			}
//    	}while(HAL_UART_Receive(&huart1, &c, 1, 50 ) == HAL_OK);

	}
	return hash;
}

void read_esp8266_at_version(){
    esp8266_print("AT+GMR\r\n");
    unsigned char c;
    int stage = 0, i = 0;

    while(HAL_UART_Receive(&huart1, &c, 1, 200 ) == HAL_OK){
		if( i==14 || (stage == 0 && c == ':') || (stage == 1 && c == '(')){
			stage++;
		}else if(stage == 1){ // && i < SIZEOF esp8266_at_version
			esp8266_at_version[i++] = c;
		}else if (stage == 2){
			break;
		}
    }
    esp8266_at_version[i] = '\0';
    wait_response(200); // read rest of message
}
