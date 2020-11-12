all: plus.bin


plus.bin: *.asm Makefile FORCE
	osascript -e 'quit app "Stella"'
	../../../dasm/bin/dasm PlusCart.asm -lPlusCart.lst -f3 -oPlusCart.bin
	cp ./PlusCart.bin ~/NextCloud/My\ ROMs
	open -a /Applications/Stella.app ./PlusCart.bin
	

FORCE:
