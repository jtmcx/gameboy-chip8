TARG     = chip8.gb
RGBASM   = rgbasm
RGBLINK  = rgblink
RGBFIX   = rgbfix
INCFILES = inc/hardware.inc
OFILES   = src/main.o src/boot.o

$(TARG) : $(OFILES)
	$(RGBLINK) -o $@ $(OFILES)
	$(RGBFIX) -v $@

$(OFILES) : $(INCFILES)

.s.o:
	$(RGBASM) -o $@ -i inc/ $<

run: $(TARG)
	rlwrap sameboy $(TARG)

clean:
	rm -f $(TARG) $(OFILES)

.SUFFIXES:
.SUFFIXES: .s .inc .o
