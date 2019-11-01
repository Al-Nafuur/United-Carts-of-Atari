#ifndef CARTRIDGE_DETECTION_H
#define CARTRIDGE_DETECTION_H



int isProbablyPLS(int, unsigned char *);

int isPotentialF8(int, unsigned char *);

/* The following detection routines are modified from the Atari 2600 Emulator Stella
  (https://github.com/stella-emu) */
int isProbablySC(int, unsigned char *);
int isProbablyFE(int, unsigned char *);
int isProbably3F(int, unsigned char *);
int isProbably3E(int, unsigned char *);
int isProbablyE0(int, unsigned char *);
int isProbably0840(int, unsigned char *);
int isProbablyCV(int, unsigned char *);
int isProbablyEF(int, unsigned char *);
int isProbablyE7(int, unsigned char *);

#endif // CARTRIDGE_DETECTION_H
