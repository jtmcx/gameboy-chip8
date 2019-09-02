
;; --------------------------------------------------------------------
;; Chip 8 Data 
;; --------------------------------------------------------------------

SECTION "Chip 8 Data", WRAM0
Chip8Regs:	DS	16	; Chip 8 Registers
Chip8PC:	DS	2	; Chip 8 Program Counter (big endian)
Chip8SP:	DS	2	; Chip 8 Stack Pointer (big endian)
Chip8Stack:	DS	64	; Chip 8 Stack area (grows upwards)

;; --------------------------------------------------------------------
;; main
;; --------------------------------------------------------------------

SECTION "main", ROM0
EXPORT main
main:
	call	init
.loop
	call	step
	jr	.loop

;; --------------------------------------------------------------------
;; srla4
;; --------------------------------------------------------------------

srla4:
	srl	a
	srl	a
	srl	a
	srl	a
	ret

;; --------------------------------------------------------------------
;; loadvy
;; --------------------------------------------------------------------

loadvy:
.prologue
	push	de
.start
	ld	a, c
	call	srla4
	ld	d, 0
	ld	e, a
	ld	hl, Chip8Regs
	add	hl, de
	ld	a, [hl]
.epilogue
	pop	de
	ret

;; --------------------------------------------------------------------
;; loadvx
;; --------------------------------------------------------------------

loadvx:
.prologue
	push	de
.start
	ld	a, b
	and	a, $0F
	ld	d, 0
	ld	e, a
	ld	hl, Chip8Regs
	add	hl, de
	ld	a, [hl]
.epilogue
	pop	de
	ret

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
;; init 
;; --------------------------------------------------------------------

init:
	;; Clear all registers
	ld	c, 16
	ld	hl, Chip8Regs
	call	bzero

	;; Clear stack area
	ld	c, 64
	ld	hl, Chip8Stack
	call	bzero

	;; Initialize PC to $0200
	ld	a, $02
	ld	[Chip8PC+0], a
	ld	a, $00
	ld	[Chip8PC+1], a

	;; Initialize SP to Chip8Stack
	ld	de, Chip8Stack
	ld	a, d
	ld	[Chip8SP+0], a
	ld	a, e
	ld	[Chip8SP+1], a
	ret

;; --------------------------------------------------------------------
;; step 
;; --------------------------------------------------------------------

step:
	;; Dereference Chip8PC into HL
	ld	hl, Chip8PC
	ld	a, [hl+]
	ld	l, [hl]
	ld	h, a

	;; Load current Chip 8 instruction into BC
	ld	a, [hl+]
	ld	c, [hl]
	ld	b, a

	ld	a, b
	call	srla4
	ld	d, 0
	ld	e, a
	ld	hl, JumpTabMain
	push	hl
	push	de
	call	trampoline
	add	sp, 4
	ret

;; --------------------------------------------------------------------
;; incpc
;; --------------------------------------------------------------------

incpc:
.prologue
	push	bc
.start
	;; Dereference Chip8PC into BC
	ld	a, [Chip8PC+0]
	ld	b, a
	ld	a, [Chip8PC+1]
	ld	c, a
	
	;; Increment the program counter.
	inc	bc
	inc	bc

	;; Save the new PC.
	ld	a, b
	ld	[Chip8PC+0], a
	ld	a, c
	ld	[Chip8PC+1], a
.epilogue
	pop	bc
	ret
	
;; --------------------------------------------------------------------
;; stackpop
;; --------------------------------------------------------------------

stackpush:
.prologue
	push	bc
	push	hl
.start
	;; Load the first argument (the value to push) into BC
	ld	hl, sp+6
	ld	a, [hl+]
	ld	b, [hl]
	ld	c, a

	;; Dereference stack pointer into HL
	ld	a, [Chip8SP+0]
	ld	h, a
	ld	a, [Chip8SP+1]
	ld	l, a

	;; Place the item on the stack
	ld	[hl], b
	inc	hl
	ld	[hl], c
	inc	hl

	;; Save the new stack pointer
	ld	a, h
	ld	[Chip8SP+0], a
	ld	a, l
	ld	[Chip8SP+1], a
.epilogue
	pop	hl
	pop	bc
	ret

;; --------------------------------------------------------------------
;; stackpop
;; --------------------------------------------------------------------

stackpop:
.prologue
	push	bc
	push	hl
.start
	;; Dereference stack pointer into HL
	ld	a, [Chip8SP+0]
	ld	h, a
	ld	a, [Chip8SP+1]
	ld	l, a

	;; Load the top of the stack into BC.
	;; Move the stack pointer down as well.
	dec	hl
	ld	c, [hl]
	dec	hl
	ld	b, [hl]

	;; Save the new stack pointer
	ld	a, h
	ld	[Chip8SP+0], a
	ld	a, l
	ld	[Chip8SP+1], a

	;; Place the value into the first argument.
	ld	hl, sp+6
	ld	[hl], c
	inc	hl
	ld	[hl], b
.epilogue
	pop	hl
	pop	bc
	ret

;; --------------------------------------------------------------------
;; trampoline 
;; --------------------------------------------------------------------

trampoline:
.start
	;; Load jump table offset from second argument in DE
	ld	hl, sp+2
	ld	e, [hl]
	inc	hl
	ld	d, [hl]

	;; Load jump table base from first argument into HL
	ld	hl, sp+4
	ld	a, [hl+]
	ld	h, [hl]
	ld	l, a

	sla	e
	add	hl, de
	ld	a, [hl+]
	ld	h, [hl]
	ld	l, a
	push	hl
	ret

;; --------------------------------------------------------------------
;; op_jp
;; --------------------------------------------------------------------

op_jp:
	ld	a, b
	and	a, $0F
	ld	[Chip8PC+0], a	
	ld	a, c
	ld	[Chip8PC+1], a
	ret

;; --------------------------------------------------------------------
;; op_call
;; --------------------------------------------------------------------

op_call:
	;; Dereference program counter into DE
	ld	a, [Chip8PC+0]
	ld	d, a
	ld	a, [Chip8PC+1]
	ld	e, a

	;; Push address of following instruction onto the chip 8 stack.
	inc	de
	inc	de
	push	de
	call	stackpush
	add	sp, 2

	;; Jump to the requested address.
	jr	op_jp

;; --------------------------------------------------------------------
;; op_ret
;; --------------------------------------------------------------------

op_ret:
	;; Load return address into DE
	add	sp, -2
	call	stackpop
	pop	de

	;; Set the new program counter
	ld	a, d
	ld	[Chip8PC+0], a
	ld	a, e
	ld	[Chip8PC+1], a

	ret


SECTION "jump tables", ROM0
JumpTabMain:
dw	op_ret	; 0x0___
dw	op_jp	; 0x1___
dw	op_call	; 0x2___
dw	incpc	; 0x3___
dw	incpc	; 0x4___
dw	incpc	; 0x5___
dw	incpc	; 0x6___
dw	incpc	; 0x7___
dw	incpc	; 0x8___
dw	incpc	; 0x9___
dw	incpc	; 0xA___
dw	incpc	; 0xB___
dw	incpc	; 0xC___
dw	incpc	; 0xD___
dw	incpc	; 0xE___
dw	incpc	; 0xF___

JumpTabAlu:
dw	incpc	; 0x8__0
dw	incpc	; 0x8__1
dw	incpc	; 0x8__2
dw	incpc	; 0x8__3
dw	incpc	; 0x8__4
dw	incpc	; 0x8__5
dw	incpc	; 0x8__6
dw	incpc	; 0x8__7
dw	incpc	; 0x8__8
dw	incpc	; 0x8__9
dw	incpc	; 0x8__A
dw	incpc	; 0x8__B
dw	incpc	; 0x8__C
dw	incpc	; 0x8__D
dw	incpc	; 0x8__E
dw	incpc	; 0x8__F
