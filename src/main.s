INCLUDE "hardware.inc"

;; --------------------------------------------------------------------
;; main
;; --------------------------------------------------------------------

SECTION "main", ROM0
EXPORT main
main:
	call	init_lcd
.loop
	jr	.loop

;; --------------------------------------------------------------------
;; bzero 
;; --------------------------------------------------------------------

bzero:
	xor	a, a
.loop
	ld	[hl+], a
	dec	c
	jr	nz, .loop
	ret

;; --------------------------------------------------------------------
;; wait_vblank 
;; --------------------------------------------------------------------

waitvblank:
.loop
	ld	a, [rLY]
	cp	$90
	jr	c, .loop
	ret

;; --------------------------------------------------------------------
;; init_lcd
;; --------------------------------------------------------------------

init_lcd:
	call	waitvblank

	;; Disable the LCD
	xor	a, a
	ld	[rLCDC], a

	;; Set the palette
	ld	a, %11100100
	ld	[rBGP], a

	;; Reset scroll registers
	xor	a, a
	ld	[rSCY], a
	ld	[rSCX], a

	;; Turn off sound
	ld	[rNR52], a

	;; Set all background sprites to sprite $20
	ld	a, $20
	ld	d, $4
	ld	e, $0
	ld	hl, $9800
.screenloop
	ld	[hl+], a
	dec	e
	jr	nz, .screenloop
	dec	d
	jr	nz, .screenloop

	;; Set sprite $20 to all black.
	;; This will black out the entire screen.
	ld	d, 16
	ld	a, $00
	ld	hl, $9200
.blackloop
	ld	[hl+], a
	dec	d
	jr	nz, .blackloop

	;; Turn screen on, display background
	ld	a, %10000001
	ld	[rLCDC], a
	ret

