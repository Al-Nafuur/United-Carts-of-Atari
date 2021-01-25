#ifndef CARTRIDGE_DETECTION_H
#define CARTRIDGE_DETECTION_H



int isProbablyPLS(unsigned int, unsigned char *);

int isPotentialF8(unsigned int, unsigned char *);

/* The following detection routines are modified from the Atari 2600 Emulator Stella
  (https://github.com/stella-emu) */
int isProbablySC(unsigned int, unsigned char *);
int isProbablyUA(unsigned int, unsigned char *);
int isProbablyFE(unsigned int, unsigned char *);
int isProbably3F(unsigned int, unsigned char *);
int isProbably3E(unsigned int, unsigned char *);
int isProbably3EPlus(unsigned int, unsigned char *);
int isProbablyE0(unsigned int, unsigned char *);
int isProbably0840(unsigned int, unsigned char *);
int isProbablyCV(unsigned int, unsigned char *);
int isProbablyEF(unsigned int, unsigned char *);
int isProbablyE7(unsigned int, unsigned char *);
int isProbablyBF(unsigned char *);
int isProbablyBFSC(unsigned char *);
int isProbablyDF(unsigned char *);
int isProbablyDFSC(unsigned char *);
int isProbablyDPCplus(unsigned int, unsigned char *);
int isProbablySB(unsigned int, unsigned char *);

#endif // CARTRIDGE_DETECTION_H
