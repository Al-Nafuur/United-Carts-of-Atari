all: plus.bin


plus.bin: *.asm Makefile FORCE
	osascript -e 'quit app "Stella"'
	../dasm/bin/dasm FontTestbed.asm -f3 -ofont.bin
	cp ./font.bin ~/NextCloud/My\ ROMs
	open -a /Applications/Stella.app ./font.bin
	

FORCE:
