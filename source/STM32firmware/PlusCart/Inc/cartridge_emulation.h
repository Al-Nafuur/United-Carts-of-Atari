#ifndef CARTRIDGE_EMULATION_H
#define CARTRIDGE_EMULATION_H

#include <stdint.h>
#include <stdbool.h>
#include "global.h"

#define RESET_ADDR addr = addr_prev = 0xffff;
#define CCM_RAM ((uint8_t*)0x10000000)

#define SWCHA          0x280

enum Transmission_State{
	No_Transmission,
	Send_Start,
	Send_Prepare_Header,
	Send_Header,
	Send_Content,
	Send_Finished,
	Receive_Header,
	Receive_Length,
	Receive_Content,
	Receive_Finished
};

#if USE_WIFI
#define setup_plus_rom_functions() \
		uint8_t receive_buffer_write_pointer = 0, receive_buffer_read_pointer = 0, content_counter = 0; \
		uint8_t out_buffer_write_pointer = 0, out_buffer_send_pointer = 0; \
		uint8_t receive_buffer[256], out_buffer[256]; \
		uint8_t prev_c = 0, prev_prev_c = 0, i, c; \
		uint16_t content_len; \
		int content_length_pos = header_length - 5; \
		enum Transmission_State huart_state = No_Transmission; \

#else //Todo make setup_plus_rom_functions empty if no WiFi
#define setup_plus_rom_functions() \
		uint8_t receive_buffer_write_pointer = 0, receive_buffer_read_pointer = 0, content_counter = 0; \
		uint8_t out_buffer_write_pointer = 0, out_buffer_send_pointer = 0; \
		uint8_t receive_buffer[256], out_buffer[256]; \
		uint8_t prev_c = 0, prev_prev_c = 0, i, c; \
		uint16_t content_len; \
		int content_length_pos = header_length - 5; \
		enum Transmission_State huart_state = No_Transmission; \

#endif

#if USE_WIFI
#define process_transmission() \
        switch(huart_state){ \
          case Send_Start: { \
        	content_len = out_buffer_write_pointer; \
        	content_len++; \
            i = (uint8_t) content_length_pos; \
            huart_state++; \
            break; \
          } \
          case Send_Prepare_Header: { \
            if (content_len != 0) { \
              c = (uint8_t) (content_len % 10); \
              http_request_header[i--] =  (char) (c + '0'); \
              content_len = content_len/10; \
            }else{ \
              i = 0; \
              huart_state++; \
            } \
            break; \
          } \
          case Send_Header: { \
            if(( huart1.Instance->SR & UART_FLAG_TXE) == UART_FLAG_TXE){ \
              huart1.Instance->DR = http_request_header[i]; \
              if( ++i == header_length ){ \
                huart_state++; \
              } \
            } \
            break; \
          } \
          case Send_Content: { \
            if(( huart1.Instance->SR & UART_FLAG_TXE) == UART_FLAG_TXE){ \
              huart1.Instance->DR = out_buffer[out_buffer_send_pointer]; \
              if( out_buffer_send_pointer == out_buffer_write_pointer ){ \
                huart_state++; \
              }else{ \
                out_buffer_send_pointer++; \
              } \
            } \
            break; \
          } \
          case Send_Finished: { \
            if(( huart1.Instance->SR & UART_FLAG_TC) == UART_FLAG_TC){ \
              out_buffer_write_pointer = 0; \
              out_buffer_send_pointer = 0; \
              huart_state++; \
            } \
            break; \
          } \
          case Receive_Header: { \
            if(( huart1.Instance->SR & UART_FLAG_RXNE) == UART_FLAG_RXNE){ \
              c = (uint8_t)huart1.Instance->DR; \
              if(c == '\n' && c == prev_prev_c){ \
                huart_state++; \
              }else{ \
                prev_prev_c = prev_c; \
                prev_c = c; \
              } \
            } \
            break; \
          } \
          case Receive_Length: { \
            if(( huart1.Instance->SR & UART_FLAG_RXNE) == UART_FLAG_RXNE){ \
              c = (uint8_t)huart1.Instance->DR; \
              huart_state++; \
              if(c == 0) \
                huart_state++; \
            } \
            break; \
          } \
          case Receive_Content: { \
            if(( huart1.Instance->SR & UART_FLAG_RXNE) == UART_FLAG_RXNE){ \
              receive_buffer[receive_buffer_write_pointer++] = (uint8_t)huart1.Instance->DR; \
              if(++content_counter == c ){ \
                huart_state++; \
              } \
            } \
            break; \
          } \
          case Receive_Finished:{ \
            http_request_header[content_length_pos - 1] = ' '; \
            http_request_header[content_length_pos - 2] = ' '; \
            content_counter = 0; \
            huart_state = No_Transmission; \
            break; \
          } \
          case No_Transmission: \
          default: \
            break; \
        }
#else
#define process_transmission()
#endif

void exit_cartridge(uint16_t , uint16_t );

/* 'Standard' Bankswitching */
void emulate_standard_cartridge(int, bool, uint16_t, uint16_t, int);

/* UA Bankswitching */
void emulate_UA_cartridge();

/* FA (CBS RAM plus) Bankswitching */
void emulate_FA_cartridge(int, bool);

/* FE Bankswitching */
void emulate_FE_cartridge();

/* 3F (Tigervision) Bankswitching */
void emulate_3F_cartridge();

/* 3E (3F + RAM) Bankswitching */
void emulate_3E_cartridge(int, bool);

/* 3E+ Bankswitching by Thomas Jentzsch */
void emulate_3EPlus_cartridge(int, bool);

/* E0 Bankswitching */
void emulate_E0_cartridge();

void emulate_0840_cartridge();

/* CommaVid Cartridge*/
void emulate_CV_cartridge();

/* F0 Bankswitching */
void emulate_F0_cartridge();

/* E7 Bankswitching */
void emulate_E7_cartridge(int, bool);


/* DPC (Pitfall II) Bankswitching */
void emulate_DPC_cartridge(uint32_t);

/* Pink Panther */
void emulate_pp_cartridge(uint8_t* ram);

#endif // CARTRIDGE_EMULATION_H
