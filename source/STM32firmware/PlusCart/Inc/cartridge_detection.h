#ifndef CARTRIDGE_DETECTION_H
#define CARTRIDGE_DETECTION_H



int isProbablyPLS(unsigned int, unsigned char *);

int isPotentialF8(unsigned int, unsigned char *);

/* The following detection routines are modified from the Atari 2600 Emulator Stella
  (https://github.com/stella-emu) */
int isProbablySC(unsigned int, unsigned char *) __attribute__((section(".flash01")));
int isProbablyUA(unsigned int, unsigned char *) __attribute__((section(".flash01")));
int isProbablyFE(unsigned int, unsigned char *) __attribute__((section(".flash01")));
int isProbably3F(unsigned int, unsigned char *) __attribute__((section(".flash01")));
int isProbably3E(unsigned int, unsigned char *) __attribute__((section(".flash01")));
int isProbably3EPlus(unsigned int, unsigned char *) __attribute__((section(".flash01")));
int isProbablyE0(unsigned int, unsigned char *) __attribute__((section(".flash01")));
int isProbably0840(unsigned int, unsigned char *) __attribute__((section(".flash01")));
int isProbablyCV(unsigned int, unsigned char *) __attribute__((section(".flash01")));
int isProbablyEF(unsigned int, unsigned char *) __attribute__((section(".flash01")));
int isProbablyE7(unsigned int, unsigned char *) __attribute__((section(".flash01")));
int isProbablyE78K(unsigned int, unsigned char *) __attribute__((section(".flash01")));
int isProbablyBF(unsigned char *) __attribute__((section(".flash01")));
int isProbablyBFSC(unsigned char *) __attribute__((section(".flash01")));
int isProbablyDF(unsigned char *) __attribute__((section(".flash01")));
int isProbablyDFSC(unsigned char *) __attribute__((section(".flash01")));
int isProbablyDPCplus(unsigned int, unsigned char *) __attribute__((section(".flash01")));
int isProbablySB(unsigned int, unsigned char *) __attribute__((section(".flash01")));

#endif // CARTRIDGE_DETECTION_H
