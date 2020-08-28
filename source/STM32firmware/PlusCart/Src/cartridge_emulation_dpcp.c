/*
 * cartridge_emulation_dpcp.c
 *
 *  Created on: 07.07.2020
 *      Author: stubig
 */
#include <string.h> // for new DCP emulation
#include <ctype.h>
#include <stdlib.h>
#include "cartridge_emulation.h"
#include "cartridge_firmware.h"
#include "global.h"

#include "cartridge_emulation_dpcp.h"

/*
#define updateMusicModeDataFetchers() { \
	uint32_t systick = SysTick->VAL; \
	if (systick > systick_lastval){ \
       for(int x = 0; x <= 2; ++x) \
    	    myMusicCounters[x] += myMusicFrequencies[x]; / * (systick - systick_lastval); /  \
	} \
	systick_lastval = systick; \
}
*/
#define updateMusicModeDataFetchers() { \
	uint32_t systick = SysTick->VAL; \
	if (systick > systick_lastval){ \
		myMusicCounters[0] += myMusicFrequencies[0]; \
		myMusicCounters[1] += myMusicFrequencies[1]; \
		myMusicCounters[2] += myMusicFrequencies[2]; \
	} \
	systick_lastval = systick; \
}

void emulate_DPCplus_cartridge( uint32_t image_size)
{
	SysTick_Config(SystemCoreClock / 21000 );// 21000?? 800 ==  ??	SystemCoreClock / 20000 // 20KHz

	uint32_t systick_lastval = 0;

	uint8_t prev_rom = 0;

	uint16_t addr, addr_prev = 0, tmp_addr=0, data = 0, data_prev = 0;

    uint8_t* ccm = CCM_RAM;
	memcpy(ccm, buffer, 0xc00); // DPC+ ARM Driver code (not really needed)
	memcpy(ccm + 0xc00, buffer + 0x6c00, 0x1400); // Display and Frequency Data 5k

	uint8_t *myProgramImage = buffer + 3*1024, *bankPtr = buffer + 23*1024;
	uint8_t *myDisplayImage = ccm + 0xc00, *myFrequencyImage = ccm + 0x1c00;
	uint32_t myFractionalCounters[8] = {0,0,0,0,0,0,0,0};
	uint32_t myMusicCounters[3] = {0,0,0}, myMusicFrequencies[3] = {0,0,0};
	uint8_t  myTops[8] = {0,0,0,0,0,0,0,0}, myBottoms[8] = {0,0,0,0,0,0,0,0};
	uint8_t  myFractionalIncrements[8] = {0,0,0,0,0,0,0,0}, myParameter[8] = {0,0,0,0,0,0,0,0};
	uint16_t myMusicWaveforms[3] = {0,0,0}, myCounters[8] = {0,0,0,0,0,0,0,0};
    _Bool myFastFetch = FALSE;
    uint8_t myParameterPointer = 0;
    unsigned char index, function;


    // Datafetcher copy stuff for CALLFUNCTION PARAMETER
    uint8_t *source, *destination;
    uint8_t myDataFetcherCopyPointer = 0, myDataFetcherCopyType = 0, myDataFetcherCopyValue = 0;


    uint32_t thumb_code_entry_point = (*(volatile uint32_t*)(&buffer[0xc4c]));//(uint32_t)0x20004d85; //buffer + 0x3bf4 + 1; //0x0c00;
//    uint32_t thumb_code_entry_point = (uint32_t) (buffer + 0x0c0b);

    // Older DPC+ driver code had different behaviour wrt the mask used
    // to retrieve 'DFxFRACLOW' (fractional data pointer low byte)
    // ROMs built with an old DPC+ driver and using the newer mask can
    // result in 'jittering' in the playfield display
    // For current versions, this is 0x0F00FF; older versions need 0x0F0000
//	uint32_t myFractionalLowMask = 0x0F00FF;
	uint32_t myFractionalLowMask = 0x0F0000;

	// Initialise the DPC's random number generator register
	uint32_t myRandomNumber = 0x2B435044; // "DPC+";


    if (!reboot_into_cartridge()) {
        return ;
    }

    __disable_irq();	// Disable interrupts

	while (1)
	{
		while ((addr = ADDR_IN) != addr_prev) addr_prev = addr;

		// got a stable address
		if (addr & 0x1000)
		{ // A12 high

			tmp_addr = addr; // save addr, because of possible fast fetch

			if(myFastFetch && prev_rom == 0xA9 && addr > 0x107f){
				data = (uint16_t) bankPtr[addr&0xFFF];
			    if(data < 0x28)
			    	addr = data; // dont't need to add 0x1000, because: if addr < 0x28 it is also < 0x1028 :-)
			}
			prev_rom = 0;

			if ( addr < 0x1028)
			{	// DPC read
				data  = 0;
				index = addr & 0x07;
				function = (addr >> 3) & 0x07;

				switch (function)
				{
					case 0x00:
					{
						switch(index)
						{
							case 0x00:
							{	// RANDOM0NEXT - advance and return byte 0 of random
								myRandomNumber = (((myRandomNumber & (1<<10)) ? 0x10adab1e : 0x00)
											     ^ ((myRandomNumber >> 11) | (myRandomNumber << 21)));
								data = (uint8_t)myRandomNumber;
								break;
							}
							case 0x01:
							{	  // RANDOM0PRIOR - return to prior and return byte 0 of random
								myRandomNumber = ((myRandomNumber & (1U<<31)) ?
											((0x10adab1e^myRandomNumber) << 11) | ((0x10adab1e^myRandomNumber) >> 21) :
											(myRandomNumber << 11) | (myRandomNumber >> 21));
								data = (uint8_t)myRandomNumber;
								break;
							}
							case 0x02:
							{	// RANDOM1
								data = (uint8_t)((myRandomNumber>>8) & 0xFF);
								break;
							}
							case 0x03:
							{	// RANDOM2
								data = (uint8_t)((myRandomNumber>>16) & 0xFF);
								break;
							}
							case 0x04:
							{	// RANDOM3
								data = (uint8_t)((myRandomNumber>>24) & 0xFF);
								break;
							}

							case 0x05:
							{	// AMPLITUDE
								// Update the music data fetchers (counter & flag)
//								updateMusicModeDataFetchers();

								// using myDisplayImage[] instead of myProgramImage[] because waveforms
								// can be modified during runtime.
								data = (uint8_t)
										( (uint32_t)myDisplayImage[(uint32_t)myMusicWaveforms[0] + (myMusicCounters[0] >> 27)] +
										  (uint32_t)myDisplayImage[(uint32_t)myMusicWaveforms[1] + (myMusicCounters[1] >> 27)] +
										  (uint32_t)myDisplayImage[(uint32_t)myMusicWaveforms[2] + (myMusicCounters[2] >> 27)] );
								break;
							}
						}
						break;
					}
					// DFxDATA - display data read
					case 0x01:
					{
						data = myDisplayImage[myCounters[index]];
						myCounters[index] = (myCounters[index] + 0x1) & 0x0fff;
						break;
					}

					// DFxDATAW - display data read AND'd w/flag ("windowed")
					case 0x02:
					{
						//  flag = (myCounters[index] & 0xFF) < myBottoms[index] ? 0xFF : 0;
						//  flag = (((myTops[index]-(myCounters[index] & 0x00ff)) & 0xFF) > ((myTops[index]-myBottoms[index]) & 0xFF)) ? 0xFF : 0;
						data = myDisplayImage[myCounters[index]] & ( (((myTops[index]-(myCounters[index] & 0x00ff)) & 0xFF) > ((myTops[index]-myBottoms[index]) & 0xFF)) ? 0xFF : 0);
						myCounters[index] = (myCounters[index] + 0x1) & 0x0fff;
						break;
					}

					// DFxFRACDATA - display data read w/fractional increment
					case 0x03:
					{
						data = myDisplayImage[ myFractionalCounters[index] >> 8];
						myFractionalCounters[index] = (myFractionalCounters[index] + myFractionalIncrements[index]) & 0x0fffff;
						break;
					}

					case 0x04:
					{
						if(index < 4)
							data = (((myTops[index]-(myCounters[index] & 0x00ff)) & 0xFF) > ((myTops[index]-myBottoms[index]) & 0xFF)) ? 0xFF : 0;
						break;
					}
					default:
                    {
						break;
                    }
			    }


				DATA_OUT = data;
				SET_DATA_MODE_OUT
				addr = tmp_addr; // restore addr, because of possible fast fetch

				// wait for address bus to change
				while (ADDR_IN == addr) ;
				SET_DATA_MODE_IN;
			}
			else if ( addr < 0x1080)
			{	// DPC write

				index = addr & 0x07;
				function = ((addr - 0x1028) >> 3) & 0x0f;

				while (ADDR_IN == addr) { data_prev = data & 0xff; data = DATA_IN; }

				switch (function)
				{
			      // DFxFRACLOW - fractional data pointer low byte
			      case 0x00:
			        myFractionalCounters[index] = (myFractionalCounters[index] & myFractionalLowMask) | (data_prev << 8);
			        break;

			      // DFxFRACHI - fractional data pointer high byte
			      case 0x01:
			        myFractionalCounters[index] = (((uint32_t)(data_prev & 0x0F)) << 16) | (myFractionalCounters[index] & 0x00ffff);
			        break;

			      //DFxFRACINC - Fractional Increment amount
			      case 0x02:
			        myFractionalIncrements[index] = (uint8_t) data_prev;
			        myFractionalCounters[index] = myFractionalCounters[index] & 0x0FFF00;
			        break;

			      // DFxTOP - set top of window (for reads of DFxDATAW)
			      case 0x03:
			        myTops[index] = (uint8_t)data_prev;
			        break;

			      // DFxBOT - set bottom of window (for reads of DFxDATAW)
			      case 0x04:
			        myBottoms[index] = (uint8_t)data_prev;
			        break;

			      // DFxLOW - data pointer low byte (trap $1057   )
			      case 0x05:
			        myCounters[index] = (myCounters[index] & 0x0F00) | data_prev ;
			        break;

			      // Control registers
			      case 0x06:
			        switch (index)
			        {
			          case 0x00:  // FASTFETCH - turns on LDA #<DFxDATA mode if value is 0
			            myFastFetch = ( data_prev == 0);
			            break;

			          case 0x01:  // PARAMETER - set parameter used by CALLFUNCTION (not all functions use the parameter)
			            if(myParameterPointer < 8)
			              myParameter[myParameterPointer++] = (uint8_t)data_prev;
			            break;

			          case 0x02:  // CALLFUNCTION
			        	// callFunction(value);
			        	  switch (data_prev)
			        	  {
			        	    case 0: // Parameter Pointer reset
			        	      myParameterPointer = 0;
			        	      break;
			        	    case 1: // Copy ROM to fetcher
			        	    	myDataFetcherCopyPointer = myParameter[3];
			        	    	myDataFetcherCopyType = data_prev;

//			        	    	source = &myProgramImage[ (*((uint16_t*)&myParameter[0])) ];
			        	    	source = &myProgramImage[ ((myParameter[1] << 8) | myParameter[0]) ];

			        	    	destination = &myDisplayImage[myCounters[myParameter[2] & 0x7]];
//			        	    	for(int i = 0; i < myParameter[3]; ++i)
//			        	    		destination[i] = source[i];
/*
				        	  	mROMdata = ((uint16_t)myParameter[1] << 8) + myParameter[0];
				        		tmp_addr = myCounters[myParameter[2] & 0x7];
			        	    	for(int i = 0; i < myParameter[3]; ++i)
			        	      		myDisplayImage[tmp_addr+i] = myProgramImage[mROMdata+i];
*/
							  myParameterPointer = 0;
			        	      break;
			        	    case 2: // Copy value to fetcher
			        	    	myDataFetcherCopyPointer = myParameter[3];
			        	    	myDataFetcherCopyType = data_prev;
			        	    	destination = &myDisplayImage[myCounters[myParameter[2]]];
			        	    	myDataFetcherCopyValue =  myParameter[0];
//			        	    	for(int i = 0; i < myParameter[3]; ++i)
//			        	    		destination[i] = myParameter[0];
			        	    	myParameterPointer = 0;
			        	    	break;
			        	      // Call user written ARM code (most likely be C compiled for ARM)
			        	    case 254: // call with IRQ driven audio, special handling needed at this
			        	              // __enable_irq();
			        	    		  // set_irq_timer(every scanline  70x 6507 CPU cycles);
			        	    		  //
			        	    case 255: // call without IRQ driven audio
			        	    	// wait for the next address (which is the address we send PC back later)
			        	    	while ((addr = ADDR_IN) != addr_prev) addr_prev = addr;
				        	    DATA_OUT = 0xEA;				// (NOP)
				        	    SET_DATA_MODE_OUT;
				        	    // check Parameter flag and copy and reset myParameterPointer and Flag.
				        	    // but maybe multiple copie tasks have to be done..
/*				        	    while(myCopyRequestCounter > 0){
 	 	 	 	 	 	 	 	 	 if(myCopyRequestType[myCopyRequestCounter] == 1){
							  	  	  	  source = &myProgramImage[myCopyRequestParameter_01[myCopyRequestCounter] ];
							  	  	  	  destination = &myDisplayImage[myCounters[myParameter[2] & 0x7]];
			        	      	  	  	  for(int i = 0; i < myCopyRequestParameter_3[myCopyRequestCounter]; ++i)
			        	    	  	  	  	  destination[i] = source[i];
 	 	 	 	 	 	 	 	 	 }else{
 	 	 	 	 	 	 	 	 	   	  destination = &myDisplayImage[myCounters[myParameter[2]]];
			        	      	  	  	  for(int i = 0; i < myCopyRequestParameter_3[myCopyRequestCounter]; ++i)
			        	      	  	  	  	  destination[i] = (uint8_t)myCopyRequestParameter_01[myCopyRequestCounter] & 0xff;
 	 	 	 	 	 	 	 	 	 }
									myCopyRequestCounter--;
				        	    }
*/
			        	    	((int (*)())thumb_code_entry_point)();
			        	    	// disable_irq_timer();
			        	    	// __disable_irq();
			    				// now send the VCS Program Counter to last address
			        	    	addr = ADDR_IN;
				        	    while (ADDR_IN == addr);

			        	    	addr = ADDR_IN;
				        	    DATA_OUT = 0x4C;				// (JMP)
				        	    while (ADDR_IN == addr);

			        	    	addr = ADDR_IN;
				        	    DATA_OUT = (addr_prev & 0xff);	// (Low Byte of new addr)
				        	    while (ADDR_IN == addr);

			        	    	addr = ADDR_IN;
				        	    DATA_OUT = (addr_prev >> 8);	// (High Byte of new addr)
			        	    	addr_prev = addr;				// set addr_prev for next loop
				        	    while (ADDR_IN == addr);
				        	    SET_DATA_MODE_IN;

				        	  break;
			        	    default:  // reserved
			        	      break;
			        	  }
			            // END OF CALLFUNCTION
			            break;

			          case 0x03:  // reserved
			          case 0x04:  // reserved
			            break;

			          case 0x05:  // WAVEFORM0
				        myMusicWaveforms[0] = (data_prev & 0x007f) << 5;
				        break;
			          case 0x06:  // WAVEFORM1
				        myMusicWaveforms[1] = (data_prev & 0x007f) << 5;
				        break;
			          case 0x07:  // WAVEFORM2
				        myMusicWaveforms[2] = (data_prev & 0x007f) << 5;
				        break;
			          default:
			            break;
			        }
			        break;

			      // DFxPUSH - Push value into data bank
			      case 0x07:
			        myCounters[index] = (myCounters[index] - 0x1) & 0x0fff;
			        myDisplayImage[myCounters[index]] = (uint8_t)data_prev;
			        break;

			      // DFxHI - data pointer high byte
			      case 0x08:
			        myCounters[index] = ((data_prev & 0x0F) << 8) | (myCounters[index] & 0x00ff);
			        break;

			      case 0x09:
			      {
			        switch (index)
			        {
			          case 0x00:  // RRESET - Random Number Generator Reset
			            myRandomNumber = 0x2B435044; // "DPC+"
			            break;
			          case 0x01:  // RWRITE0 - update byte 0 of random number
			            myRandomNumber = (myRandomNumber & 0xFFFFFF00) | data_prev;
			            break;
			          case 0x02:  // RWRITE1 - update byte 1 of random number
			            myRandomNumber = (myRandomNumber & 0xFFFF00FF) | (data_prev<<8);
			            break;
			          case 0x03:  // RWRITE2 - update byte 2 of random number
			            myRandomNumber = (myRandomNumber & 0xFF00FFFF) | (((uint32_t)data_prev)<<16);
			            break;
			          case 0x04:  // RWRITE3 - update byte 3 of random number
			            myRandomNumber = (myRandomNumber & 0x00FFFFFF) | (((uint32_t)data_prev)<<24);
			            break;
			          case 0x05:  // NOTE0
				        myMusicFrequencies[0] = (*((uint32_t*)&myFrequencyImage[data_prev<<2]));
				        break;
			          case 0x06:  // NOTE1
				        myMusicFrequencies[1] = (*((uint32_t*)&myFrequencyImage[data_prev<<2]));
				        break;
			          case 0x07:  // NOTE2
				        myMusicFrequencies[2] = (*((uint32_t*)&myFrequencyImage[data_prev<<2]));
				        break;
			          default:
			            break;
			        }
			        break;
			      }

			      // DFxWRITE - write into data bank
			      case 0x0a:
			      {
			        myDisplayImage[myCounters[index]] = (uint8_t)data_prev;
			        myCounters[index] = (myCounters[index] + 0x1) & 0x0fff;
			        break;
			      }

			      default:
			        break;

				}
			}
			else
			{	// check bank-switch
				if (addr >= 0x1FF6 && addr <= 0x1FFB)	// bank-switch
					bankPtr = &myProgramImage[(addr - 0x1FF6 ) * 4*1024 ];

				// normal rom access
				prev_rom = bankPtr[addr&0xFFF];
				DATA_OUT = ((uint16_t) prev_rom);
				SET_DATA_MODE_OUT;

				if(myDataFetcherCopyType == 0)
					updateMusicModeDataFetchers();

				while (ADDR_IN == addr){
					// move copy routine for data fetchers here (non blocking !)
					if(myDataFetcherCopyType == 1){
						destination[--myDataFetcherCopyPointer] = source[myDataFetcherCopyPointer];
						if(myDataFetcherCopyPointer == 0)
							myDataFetcherCopyType = 0;
					}else if(myDataFetcherCopyType == 2){
	        	    	destination[--myDataFetcherCopyPointer] = myDataFetcherCopyValue;
						if(myDataFetcherCopyPointer == 0)
							myDataFetcherCopyType = 0;
					}
				}
				SET_DATA_MODE_IN;
			}
		}
	}

	__enable_irq();
}

