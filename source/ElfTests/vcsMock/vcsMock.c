#include <stdint.h>

void elf_main(uint32_t args);

__attribute__((section(".vcsMock.const")))
const uint8_t ReverseByte[256] = { 0 };

__attribute__((section(".vcsMock")))
void vcsWrite3(uint8_t ZP, uint8_t data)
{
	elf_main(0);
}

__attribute__((section(".vcsMock"))) 
void vcsJmp3()
{
}

__attribute__((section(".vcsMock"))) 
void vcsLda2(uint8_t data)
{
}

__attribute__((section(".vcsMock")))
void vcsSta3(uint8_t ZP)
{
}

__attribute__((section(".vcsMock")))
uint8_t vcsRead6(uint16_t address)
{
	return 0;
}

__attribute__((section(".vcsMock")))
void vcsStartOverblank()
{
}

__attribute__((section(".vcsMock")))
void vcsEndOverblank()
{
}

__attribute__((section(".vcsMock")))
void vcsLdaForBusStuff2()
{
}

__attribute__((section(".vcsMock")))
void vcsLdxForBusStuff2()
{
}

__attribute__((section(".vcsMock")))
void vcsLdyForBusStuff2()
{
}

__attribute__((section(".vcsMock")))
void vcsWrite5(uint8_t ZP, uint8_t data)
{
}

__attribute__((section(".vcsMock"))) 
void vcsLdx2(uint8_t data)
{
}

__attribute__((section(".vcsMock")))
void vcsLdy2(uint8_t data)
{
}

__attribute__((section(".vcsMock")))
void vcsSta4(uint8_t ZP)
{
}

__attribute__((section(".vcsMock"))) 
void vcsStx3(uint8_t ZP)
{
}

__attribute__((section(".vcsMock")))
void vcsStx4(uint8_t ZP)
{
}

__attribute__((section(".vcsMock"))) 
void vcsSty3(uint8_t ZP)
{
}

__attribute__((section(".vcsMock")))
void vcsSty4(uint8_t ZP)
{
}

__attribute__((section(".vcsMock")))
void vcsTxs2()
{
}

__attribute__((section(".vcsMock")))
void vcsJsr6(uint16_t target)
{
}

__attribute__((section(".vcsMock"))) 
void vcsNop2()
{
}

__attribute__((section(".vcsMock")))
void vcsNop2n(uint16_t n)
{
}


__attribute__((section(".vcsMock")))
void vcsCopyOverblankToRiotRam()
{
}