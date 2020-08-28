#ifndef CARTRIDGE_EMULATION_DPCP_H
#define CARTRIDGE_EMULATION_DPCP_H

#include <stdint.h>
#define CCM_RAM ((uint8_t*)0x10000000)

/* DPC+ Bankswitching */
void emulate_DPCplus_cartridge(uint32_t);

#endif // CARTRIDGE_EMULATION_DPCP_H
