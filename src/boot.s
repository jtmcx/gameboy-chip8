SECTION "boot", ROM0[$100]
boot:
	di
	jp main 
REPT $150 - $104
	db 0
ENDR

SECTION "chip 8 rom", ROM0[$200]
INCBIN "test/test_rnd.ch8"
