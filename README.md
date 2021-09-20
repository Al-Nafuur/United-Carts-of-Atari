# Atari 2600 PlusCart


## Description
the Atari 2600 PlusCart ist based on Robin Edwards Unocart-2600 (https://github.com/robinhedwards/UnoCart-2600) and the extensions of Christian Speckner's (DirtyHairy) fork (https://github.com/DirtyHairy/UnoCart-2600). The PlusCart has no SD-Card, but an ESP8266 to connect to a local WiFi Network and the Internet.
The PlusCart downloads the ROM-files from an Server in the Internet called the "PlusStore". The way this is done is similar to the way the Unocart-2600 loads ROMs from the FAT filesystem on the SD-card, while the VCS is performing a waitroutine in his RAM.

## PlusROM
Additionally the PlusCart has one more interesting feature. It offers **internet access** to the ROM Developers, these functions are called "[PlusROM](http://pluscart.firmaplus.de/pico/?PlusROM)". Examples for PlusROMs can be found in the [PlusROM-Hacks Repository](https://github.com/Al-Nafuur/PlusROM-Hacks) on Github.

## [Documentation](http://pluscart.firmaplus.de/pico/)
More information and documentation can be found at the [PlusCart website](http://pluscart.firmaplus.de/pico/)


Copyright:

(c) Firmaplus(+) Ltd.

Dipl.Ing.(FH) Wolfgang Stubig
