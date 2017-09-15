.POSIX:

cantina.bin: cantina.asm
	dasm cantina.asm -I$(DASMINC) -f3 -v4 -ocantina.bin -lcantina.lst -scantina.sym

clean:
	rm *.bin *.lst *.sym

.PHONY: clean
