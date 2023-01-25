rom_elf: rom_elf.c
	arm-none-eabi-gcc -r -mlong-calls -fno-exceptions -march=armv7-m *.c -orom_elf.o -O2 -Wall
#	arm-none-eabi-gcc -r -I"/mnt/d/ST/STM32CubeIDE_1.11.0/STM32CubeIDE/plugins/com.st.stm32cube.ide.mcu.externaltools.gnu-tools-for-stm32.10.3-2021.10.win32_1.0.100.202210260954/tools/bin" -I"/mnt/d/ST/STM32CubeIDE_1.11.0/STM32CubeIDE/plugins/com.st.stm32cube.ide.mcu.externaltools.make.win32_2.0.100.202202231230/tools/bin" -I"/mnt/d/ST/STM32CubeIDE_1.11.0/STM32CubeIDE//plugins/com.st.stm32cube.ide.jre.win64_2.3.0.202207290817/jre/bin/server" -I"/mnt/d/ST/STM32CubeIDE_1.11.0/STM32CubeIDE//plugins/com.st.stm32cube.ide.jre.win64_2.3.0.202207290817/jre/bin" -I"/mnt/c/Program Files (x86)/Common Files/Oracle/Java/javapath" -I"/mnt/c/ProgramData/Oracle/Java/javapath" -I"/mnt/c/Program Files (x86)/Intel/iCLS Client/" -I"/mnt/c/Program Files/Intel/iCLS Client/" -I"/mnt/c/WINDOWS/system32" -I"/mnt/c/WINDOWS" -I"/mnt/c/WINDOWS/System32/Wbem" -I"/mnt/c/WINDOWS/System32/WindowsPowerShell/v1.0/" -I"/mnt/c/Program Files (x86)/PuTTY/" -I"/mnt/d/Programme/IsoBuster" -I"/mnt/c/Program Files (x86)/Intel/Intel(R) Management Engine Components/DAL" -I"/mnt/c/Program Files/Intel/Intel(R) Management Engine Components/DAL" -I"/mnt/c/Program Files (x86)/Intel/Intel(R) Management Engine Components/IPT" -I"/mnt/c/Program Files/Intel/Intel(R) Management Engine Components/IPT" -I"/mnt/c/WINDOWS/System32/OpenSSH/" -I"/mnt/c/Program Files/Git/cmd" -I"/mnt/c/Program Files (x86)/Windows Live/Shared" -I"/mnt/d/Programme/KretSim" -I"/mnt/c/Program Files/CMake/bin" -I"/mnt/d/Programme/Arm GNU Toolchain arm-none-eabi/12.2 rel1/bin" -I"/mnt/c/Users/stubig/AppData/Local/Programs/Python/Python39/Scripts/" -I"/mnt/c/Users/stubig/AppData/Local/Programs/Python/Python39/" -I"/mnt/d/Programme/bB" -I"/mnt/d/Download/bB" -I"/mnt/d/Atari/bB.1.1d.reveng41" -I"/mnt/c/Users/stubig/AppData/Local/Microsoft/WindowsApps" -I"/mnt/c/Users/stubig/AppData/Local/particledev/bin" -I"/mnt/c/Users/stubig/AppData/Local/Programs/Microsoft VS Code/bin" -I"/mnt/c/Users/stubig/AppData/Local/Microsoft/WindowsApps" -I"/mnt/c/Program Files/Git/usr/bin" -I"/mnt/d/ST/STM32CubeIDE_1.11.0/STM32CubeIDE" -mlong-calls -fno-exceptions -march=armv7-m *.c -orom_elf.o -O2 -Wall
#	arm-none-eabi-gcc -r -I/mnt/d/Firmaplus/Firmaplus_intern/Atari/PlusCart/GIT/atari-2600-pluscart/source/STM32firmware/PlusCart/Drivers/CMSIS/Device/ST/STM32F4xx/Include -I/mnt/d/Firmaplus/Firmaplus_intern/Atari/PlusCart/GIT/atari-2600-pluscart/source/STM32firmware/PlusCart/Drivers/CMSIS/Include -I/mnt/d/Firmaplus/Firmaplus_intern/Atari/PlusCart/GIT/atari-2600-pluscart/source/STM32firmware/PlusCart/Drivers/STM32F4xx_HAL_Driver/Inc -I/mnt/d/Firmaplus/Firmaplus_intern/Atari/PlusCart/GIT/atari-2600-pluscart/source/STM32firmware/PlusCart/Inc -mlong-calls -fno-exceptions -march=armv7-m *.c -orom_elf.o -O2 -Wall
	arm-none-eabi-ld -r rom_elf.o -b binary 4k_rom.bin -orom_elf.bin
	arm-none-eabi-strip rom_elf.bin -d -R.comment -R.ARM.attributes
	arm-none-eabi-gcc rom_elf.bin vcsMock.a cartridge_io_mock.a -orom_elf-linked.elf -Tstm32f4_flash.ld -nostartfiles


define BOGUS

https://stackoverflow.com/questions/48148077/arm-eabi-none-undefined-reference-to-memset-error-for-lpc2148

https://visualgdb.com/tutorials/arm/stm32/dma/
http://www.lucadavidian.com/2017/11/17/stm32f4-using-the-dma-controller-with-adc/
https://embedds.com/using-direct-memory-access-dma-in-stm23-projects/
https://stm32f4-discovery.net/2017/07/stm32-tutorial-efficiently-receive-uart-data-using-dma/
https://deepbluembedded.com/stm32-dma-tutorial-using-direct-memory-access-dma-in-stm32/
https://mcturra2000.wordpress.com/2021/07/12/simple-memory-to-memory-stm32f4-dma-example-using-libopencm3/
https://microtechnics.ru/en/stm32cube-spi-and-dma-example/

https://www.reddit.com/r/stm32/comments/d8zt8a/delaytimer_code_without_hal/
https://www.digikey.de/en/maker/projects/getting-started-with-stm32-timers-and-timer-interrupts/d08e6493cefa486fb1e79c43c0b08cc6



/mnt/d/Firmaplus/Firmaplus_intern/Atari/PlusCart/GIT/atari-2600-pluscart/source/STM32firmware/PlusCart/Drivers/CMSIS/Device/ST/STM32F4xx/Include 
/mnt/d/Firmaplus/Firmaplus_intern/Atari/PlusCart/GIT/atari-2600-pluscart/source/STM32firmware/PlusCart/Drivers/CMSIS/Include 
/mnt/d/Firmaplus/Firmaplus_intern/Atari/PlusCart/GIT/atari-2600-pluscart/source/STM32firmware/PlusCart/Drivers/STM32F4xx_HAL_Driver/Inc 
/mnt/d/Firmaplus/Firmaplus_intern/Atari/PlusCart/GIT/atari-2600-pluscart/source/STM32firmware/PlusCart/Inc

D:\ST\STM32CubeIDE_1.11.0\STM32CubeIDE\plugins\com.st.stm32cube.ide.mcu.externaltools.gnu-tools-for-stm32.10.3-2021.10.win32_1.0.100.202210260954\tools\bin
D:\ST\STM32CubeIDE_1.11.0\STM32CubeIDE\plugins\com.st.stm32cube.ide.mcu.externaltools.make.win32_2.0.100.202202231230\tools\bin
D:/ST/STM32CubeIDE_1.11.0/STM32CubeIDE//plugins/com.st.stm32cube.ide.jre.win64_2.3.0.202207290817/jre/bin/server
D:/ST/STM32CubeIDE_1.11.0/STM32CubeIDE//plugins/com.st.stm32cube.ide.jre.win64_2.3.0.202207290817/jre/bin
D:\Programme\Arm GNU Toolchain arm-none-eabi\12.2 rel1\bin
D:\ST\STM32CubeIDE_1.11.0\STM32CubeIDE



/usr/local/sbin
/usr/local/bin
/usr/sbin
/usr/bin
/sbin
/bin
/usr/games
/usr/local/games
/mnt/c/Program Files (x86)/Common Files/Oracle/Java/javapath
/mnt/c/ProgramData/Oracle/Java/javapath
/mnt/c/Program Files (x86)/Intel/iCLS Client/
/mnt/c/Program Files/Intel/iCLS Client/
/mnt/c/WINDOWS/system32
/mnt/c/WINDOWS
/mnt/c/WINDOWS/System32/Wbem
/mnt/c/WINDOWS/System32/WindowsPowerShell/v1.0/
/mnt/c/Program Files (x86)/PuTTY/
/mnt/d/Programme/IsoBuster
/mnt/c/Program Files (x86)/Intel/Intel(R) Management Engine Components/DAL
/mnt/c/Program Files/Intel/Intel(R) Management Engine Components/DAL
/mnt/c/Program Files (x86)/Intel/Intel(R) Management Engine Components/IPT
/mnt/c/Program Files/Intel/Intel(R) Management Engine Components/IPT
/mnt/c/WINDOWS/System32/OpenSSH/
/mnt/c/Program Files/Git/cmd
/mnt/c/Program Files (x86)/Windows Live/Shared
/mnt/d/Programme/KretSim
/mnt/c/Program Files/CMake/bin
/mnt/d/Programme/Arm GNU Toolchain arm-none-eabi/12.2 rel1/bin
/mnt/c/Users/stubig/AppData/Local/Programs/Python/Python39/Scripts/
/mnt/c/Users/stubig/AppData/Local/Programs/Python/Python39/
/mnt/d/Programme/bB
/mnt/d/Download/bB
/mnt/d/Atari/bB.1.1d.reveng41
/mnt/c/Users/stubig/AppData/Local/Microsoft/WindowsApps
/mnt/c/Users/stubig/AppData/Local/particledev/bin
/mnt/c/Users/stubig/AppData/Local/Programs/Microsoft VS Code/bin
/mnt/c/Users/stubig/AppData/Local/Microsoft/WindowsApps
/mnt/c/Program Files/Git/usr/bin
/snap/bin


D:\ST\STM32CubeIDE_1.11.0\STM32CubeIDE\plugins\com.st.stm32cube.ide.mcu.externaltools.gnu-tools-for-stm32.10.3-2021.10.win32_1.0.100.202210260954\tools\bin
D:\ST\STM32CubeIDE_1.11.0\STM32CubeIDE\plugins\com.st.stm32cube.ide.mcu.externaltools.make.win32_2.0.100.202202231230\tools\bin
D:/ST/STM32CubeIDE_1.11.0/STM32CubeIDE//plugins/com.st.stm32cube.ide.jre.win64_2.3.0.202207290817/jre/bin/server
D:/ST/STM32CubeIDE_1.11.0/STM32CubeIDE//plugins/com.st.stm32cube.ide.jre.win64_2.3.0.202207290817/jre/bin
D:\Programme\Arm GNU Toolchain arm-none-eabi\12.2 rel1\bin
D:\ST\STM32CubeIDE_1.11.0\STM32CubeIDE

C:\Program Files (x86)\Common Files\Oracle\Java\javapath
C:\ProgramData\Oracle\Java\javapath
C:\Program Files (x86)\Intel\iCLS Client\
C:\Program Files\Intel\iCLS Client\
C:\WINDOWS\system32
C:\WINDOWS
C:\WINDOWS\System32\Wbem
C:\WINDOWS\System32\WindowsPowerShell\v1.0\
C:\Program Files (x86)\PuTTY\
D:\Programme\IsoBuster
C:\Program Files (x86)\Intel\Intel(R) Management Engine Components\DAL
C:\Program Files\Intel\Intel(R) Management Engine Components\DAL
C:\Program Files (x86)\Intel\Intel(R) Management Engine Components\IPT
C:\Program Files\Intel\Intel(R) Management Engine Components\IPT
C:\WINDOWS\System32\OpenSSH\
C:\Program Files\Git\cmd
C:\Program Files (x86)\Windows Live\Shared
D:\Programme\KretSim
C:\Program Files\CMake\bin
C:\Users\stubig\AppData\Local\Programs\Python\Python39\Scripts\
C:\Users\stubig\AppData\Local\Programs\Python\Python39\
D:\Programme\bB
D:\Download\bB
D:\Atari\bB.1.1d.reveng41
C:\Users\stubig\AppData\Local\Microsoft\WindowsApps
C:\Users\stubig\AppData\Local\particledev\bin
C:\Users\stubig\AppData\Local\Programs\Microsoft VS Code\bin
C:\Users\stubig\AppData\Local\Microsoft\WindowsApps
C:\Program Files\Git\usr\bin
endef