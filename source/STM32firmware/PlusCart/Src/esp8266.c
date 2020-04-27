/**
 * File:    esp8266.c
 * Author:  Wolfgang Stubig <w.stubig@firmaplus.de>
 * Version: v0.0.3
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

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "stm32_udid.h"
#include "esp8266_AT_WifiManager.h"
#include "esp8266.h"

/* private functions */
void get_boundary_http_header(char *) __attribute__((section(".flash01")));
uint64_t wait_response(uint32_t) __attribute__((section(".flash01")));
void set_standard_mode(void) __attribute__((section(".flash01")));
uint64_t esp8266_send_command(char *command, uint32_t timeout) __attribute__((section(".flash01")));

/* AT WiFi Manager */
void handle_http_requests() __attribute__((section(".flash01")));
uint8_t process_http_headline() __attribute__((section(".flash01")));
void send_requested_page_to_client(char id, const char* page, unsigned int len, _Bool close_connection) __attribute__((section(".flash01")));
void get_http_request_url_param_values(url_param * param_array , int len) __attribute__((section(".flash01")));
void generate_html_wifi_list(void) __attribute__((section(".flash01")));
void generate_html_wifi_info(void) __attribute__((section(".flash01")));
inline int ishex(char x) __attribute__((section(".flash01")));
void uri_decode( char *s ) __attribute__((section(".flash01")));
void connect_tcp_link(char link_id ) __attribute__((section(".flash01")));
_Bool init_send_tcp_link(char link_id, uint16_t bytes_to_send) __attribute__((section(".flash01")));
void close_tcp_link(char link_id) __attribute__((section(".flash01")));

char stm32_udid[25];
char tmp_uart_buffer[50];

_Bool esp8266_PlusStore_API_connect(){
	uint64_t resp = esp8266_send_command(API_ATCMD_1, 200);
	if( resp == ESP8266_CONNECT || resp == ESP8266_ALREADY_CONNECTED){
		esp8266_send_command(API_ATCMD_2, 200);
	    return TRUE;
	}
    return FALSE;
}

void esp8266_PlusStore_API_prepare_request_header(char *path, _Bool prepare_range_request, _Bool basic_uri_encode){

	if(basic_uri_encode){
		for (char* p = path; (p = strchr(p, ' ')); ++p) {
			*p = '+';
		}
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

void esp8266_PlusStore_API_end_transmission(){
	HAL_Delay(50);
	esp8266_send_command("+++", 1000);
}

uint32_t esp8266_PlusStore_API_range_request(char *path, uint32_t range_count, http_range *range, uint8_t *ext_buffer){
	uint32_t response_size = 0;
	uint16_t expected_size = 0;
	uint8_t c;
	char boundary[] = {'\r','\n','-','-', RANGE_BOUNDARY_TEMPLATE , '\r','\n'};

	esp8266_PlusStore_API_prepare_request_header(path, TRUE, FALSE );

	for (uint32_t i = 0; i < range_count; i++) {
 	    if (i > 0)
            strcat(http_request_header, ",");
        sprintf(http_request_header, "%s%lu-%lu" ,http_request_header, range[i].start, range[i].stop  );
        expected_size += ( range[i].stop + 1 - range[i].start );
 	}
    strcat(http_request_header, (char *)"\r\n\r\n");

	esp8266_print(http_request_header);
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
	uint32_t bytes_read = 0, chunk_read = 0;
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
		chunk_read = esp8266_PlusStore_API_range_request(path, 1, range, &ext_buffer[(range[0].start - start_pos)]);
		bytes_read += chunk_read;
		if(chunk_read != ( range[0].stop + 1 - range[0].start ))
			break;
	}
	esp8266_PlusStore_API_end_transmission();
	return bytes_read;
}

int esp8266_PlusROM_API_connect(unsigned int size){
	uint16_t * nmi_p = (uint16_t * )&buffer[size - 6];
	int i = nmi_p[0] - 0x1000;

	int offset = strlen((char *)&buffer[i]) + 1 + i;

	http_request_header[0] = '\0';
	strcat(http_request_header, (char *)"AT+CIPSTART=\"TCP\",\"");
    strcat(http_request_header, (char *)&buffer[offset]);
    strcat(http_request_header, (char *)"\",80\r\n");

    esp8266_send_command(http_request_header, 5000);

	http_request_header[0] = '\0';
	strcat(http_request_header, (char *)"POST /");
    strcat(http_request_header, (char *)&buffer[i]);
    strcat(http_request_header, (char *)" HTTP/1.0\r\nHost: ");
    strcat(http_request_header, (char *)&buffer[offset]);
    strcat(http_request_header, (char *)"\r\nConnection: keep-alive\r\nContent-Type: application/octet-stream\r\nPlusStore-ID: v" VERSION " ");
    strcat(http_request_header, (char *)stm32_udid);
    strcat(http_request_header, (char *)"\r\nContent-Length:    \r\n\r\n");
    offset = strlen(http_request_header);

    esp8266_send_command(API_ATCMD_2, 5000);
    return offset;
}

uint16_t esp8266_skip_http_response_header(){
	int count = 0;
	uint16_t content_length = 0;
	uint8_t c;
	while(HAL_UART_Receive(&huart1, &c, 1, 15000 ) == HAL_OK){
       	if( c == '\n' ){
       		if (count == 1){
       			break;
       		}else if(count > 16 && strncasecmp("content-length: ", tmp_uart_buffer, 16) == 0){
   		        content_length = (uint16_t) atoi(&tmp_uart_buffer[16]);
       		}
       		count = 0;
       	}else{
       		if(count < 20){
       			tmp_uart_buffer[count] = c;
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
    }while( esp8266_is_connected() == FALSE && count++ < 6);

}
//________UART module Initialized__________//

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
_Bool esp8266_is_started(void) {
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
_Bool esp8266_reset(_Bool factory_reset) {
    if(factory_reset)
    	esp8266_send_command("AT+RESTORE\r\n", 200);
	else
		esp8266_send_command("AT+RST\r\n", 200);

    wait_response(5000); // == ESP8266_READY
    esp8266_send_command("ATE0\r\n", 200);
	set_standard_mode();
	return TRUE;
}


_Bool esp8266_wifi_list(MENU_ENTRY **dst, int *num_menu_entries){
	int count = 0;
	_Bool is_entry_row;
	uint8_t pos = 0, c;

	esp8266_print("AT+CWLAP\r\n");

	if(HAL_UART_Receive(&huart1, &c, 1, 15000 ) == HAL_OK){
    	do{
            if(count == 0){ // first char defines if its an entry row with SSID or Header Row
            	is_entry_row = (c == '+' ) ? 1 : 0;
            	if(is_entry_row){
                    (*dst)->type = Setup_Menu;
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

	if(esp8266_send_command(http_request_header , 15000) == ESP8266_OK){
    	return TRUE;
	}
	return FALSE;
}

_Bool esp8266_wps_connect(){
	if(esp8266_send_command("AT+WPS=1\r\n", 1000) == ESP8266_OK){
		if(wait_response(130000) == ESP8266_WPS_SUCCESS){
			return TRUE;
 		}
	}
	return FALSE;
}

_Bool esp8266_is_connected(void){
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
	 HAL_UART_Transmit(&huart1, (uint8_t *)ptr, strlen((char *)ptr), HAL_UART_TIMEOUT_SEND);
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
	esp8266_reset(FALSE);
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
            char send_link_id = linkId + 1;

            if(send_link_id > '3')
            	send_link_id = '0';

            get_http_request_url_param_values( p_array, 1);

        	strncat(cur_path, p_array[0].value, (127 - sizeof(URLENCODE_MENU_TEXT_SETUP "/" URLENCODE_MENU_TEXT_PLUS_CONNECT "/") ) );
        	strcat(cur_path, "/Enter");

			esp8266_PlusStore_API_prepare_request_header(cur_path, FALSE, FALSE );
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
    	send_requested_page_to_client(linkId, favicon_ico, sizeof(favicon_ico), TRUE);
    }else if(response_page == http_page_not_found){
    	send_requested_page_to_client(linkId, not_found_text, sizeof(not_found_text)-1, TRUE);
    }else{
    	send_requested_page_to_client(linkId, http_header_html, sizeof(http_header_html) - 1, FALSE);
       	send_requested_page_to_client(linkId, html_head, sizeof(html_head) - 1, FALSE);
       	if(response_page == http_page_wifi || response_page == http_page_info){
           	send_requested_page_to_client(linkId, (char *)buffer, strlen((char *)buffer), FALSE);
       	}
       	if(response_page == http_page_wifi  || response_page == http_page_wifi_no_scan){
           	send_requested_page_to_client(linkId, html_form, sizeof(html_form) - 1, FALSE);
       	}

       	if(response_page == http_page_save ){
          	send_requested_page_to_client(linkId, html_saved, sizeof(html_saved) - 1, FALSE);
       	}else if(response_page == http_page_exit ){
           	send_requested_page_to_client(linkId, html_exit, sizeof(html_exit) - 1, FALSE);
       	}else if(response_page == http_page_start ){
           	send_requested_page_to_client(linkId, html_portal_options, sizeof(html_portal_options) - 1, FALSE);
           	if(esp8266_is_connected()){
               	send_requested_page_to_client(linkId, html_plus_connect, sizeof(html_plus_connect) - 1, FALSE);
           	}
       	}else if(response_page == http_page_plus_connect ){
           	send_requested_page_to_client(linkId, html_connect_form, sizeof(html_connect_form) - 1, FALSE);
       	}else if(response_page == http_page_plus_failed ){
           	send_requested_page_to_client(linkId, html_plus_failed, sizeof(html_plus_failed) - 1, FALSE);
       	}else if(response_page == http_page_plus_created ){
           	send_requested_page_to_client(linkId, html_plus_created, sizeof(html_plus_created) - 1, FALSE);
       	}else if(response_page == http_page_plus_connected ){
           	send_requested_page_to_client(linkId, html_plus_connected, sizeof(html_plus_connected) - 1, FALSE);
       	}

       	if(response_page != http_page_start && response_page != http_page_exit){
           	send_requested_page_to_client(linkId, html_back, sizeof(html_back) - 1, FALSE);
       	}
       	send_requested_page_to_client(linkId, html_end, sizeof(html_end) - 1, TRUE);
    }
    return status;
}

void send_requested_page_to_client(char id, const char* page, unsigned int len, _Bool close_connection)
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
            len_of_package_to_TX = len;
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

inline int ishex(char x){
	return (x >= '0' && x <= '9') || (x >= 'a' && x <= 'f') || (x >= 'A' && x <= 'F');
}

void uri_decode( char *s ){
	int len = strlen(s);
	int c;
	int s_counter = 0, d_counter = 0;

	for (; s_counter < len; s_counter++) {
		c = s[s_counter];
		if (c == '+'){
            c = ' ';
		}else if (c == '%' && ( !ishex(s[++s_counter]) || !ishex(s[++s_counter]) || !sscanf(&s[s_counter - 1], "%2x", &c))){
			return;
		}
		s[d_counter++] = c;
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
	esp8266_send_command(tmp_uart_buffer , 200);
}

_Bool init_send_tcp_link(char link_id, uint16_t bytes_to_send){
	sprintf(tmp_uart_buffer, "AT+CIPSEND=%c,%d\r\n", link_id, bytes_to_send);
    if(esp8266_send_command(tmp_uart_buffer, 2000) == ESP8266_OK){
    	wait_response(200); // "> "
    	return TRUE;
    }
    return FALSE;
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

void generate_udid_string(){
	int i;
	uint8_t c;
	memset(stm32_udid, '0', 24);
	stm32_udid[24] = '\0';
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
