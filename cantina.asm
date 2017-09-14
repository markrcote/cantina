    ;; Pazaak for the 2600

    processor 6502
    include "vcs.h"
    include "macro.h"

LEFT_ARROW_COLOUR = $80
RIGHT_ARROW_COLOUR = $81
LAST_SWCHA = $82
DISPLAYED_SIDE_DECK = $83 ; increment on SIDE_DECK (0..9)
SIDE_DECK = $84   ; 10 bytes

    SEG
    ORG   $F000
Reset
    ;; Clear RAM and all TIA registers
    ldx   #0
    lda   #0
Clear
    sta   0,x
    inx
    bne   Clear

    ;; ------------------------------------------------
    ;; Once-only initialisation...

    lda   #$9A
    sta   COLUBK
    lda   #$32
    sta   COLUPF
    lda   #1
    sta   CTRLPF
    lda   #0
    sta   COLUP0
    sta   SWACNT
    ;; ------------------------------------------------

    ;; Dummy values (FIXME: there should actually be 10)
    ldx   #0
    lda   PlusOne
    sta   SIDE_DECK,X
    inx
    lda   MinusOne
    sta   SIDE_DECK,X
    inx
    lda   PlusTwo
    sta   SIDE_DECK,X
    inx
    lda   MinusTwo
    sta   SIDE_DECK,X
StartOfFrame

    ;; Start of new frame
    ;; Start of vertical blank processing

    lda   #0
    sta   VBLANK

    lda   #2
    sta   VSYNC
    sta   WSYNC
    sta   WSYNC
    sta   WSYNC           ; 3 scanlines of VSYNC signal

    lda   #0
    sta   VSYNC

    ;; ------------------------------------------------
    ;; 37 scanlines of vertical blank...

    ldx   #0
VerticalBlank
    sta   WSYNC
    inx
    cpx   #37
    bne   VerticalBlank

    ;; Blank space at top
    sta   WSYNC
    sta   WSYNC

    lda   #04
    sta   NUSIZ0
    sta   WSYNC

    ldy   #0
DisplayArrowLine
    sta   WSYNC              ; 3 (X / 75)

	; set colour and pixels for left playfield
    lda   LEFT_ARROW_COLOUR  ; 3 (3)
    sta   COLUPF             ; 3 (6)
    lda   Arrow,Y            ; 4 (10)
    sta   PF0                ; 4 (14)

	; maximum allowed time before we have to set the right playfield
    sleep 45                 ; 45 (59)

	; set colour and pixels for right playfield
    lda   RIGHT_ARROW_COLOUR ; 3 (62)
    sta   COLUPF             ; 3 (65)
    iny                      ; 2 (67)

	; card and arrows are 8 lines high
    cpy   #8                 ; 2 (69)
    bne   DisplayArrowLine   ; 3 (72) if true / 2 (71)

    ldy   #198               ; 2 (74)
Ground
    sta   WSYNC              ; 3 (77)
    dey
    bne   Ground

    lda   0
    sta   PF0
    sta   PF1
    sta   PF2

    ;; ------------------------------------------------

    lda   #%01000010
    sta   VBLANK          ; end of screen - enter blanking

    ;; Check inputs

    lda   #$32
    sta   LEFT_ARROW_COLOUR
    sta   RIGHT_ARROW_COLOUR

    ldx   #$F2
    lda   SWCHA

CheckRight
    asl
    bcs   CheckLeft
    stx   RIGHT_ARROW_COLOUR

CheckLeft
    asl
    bcs   Overscan
    stx   LEFT_ARROW_COLOUR

Overscan
    ;; 30 scanlines of overscan...

    ldx   #0
OverscanLine
    sta   WSYNC
    inx
    cpx   #30
    bne   OverscanLine

    jmp   StartOfFrame

;------------------------------------------------------------------------------

Arrow
    .byte $00,$00,$80,$C0,$E0,$C0,$80,$00
PlusOne
    .byte $00,$02,$42,$E2,$42,$02,$02,$00
MinusOne
    .byte $00,$02,$02,$E2,$02,$02,$02,$00
PlusTwo
    .byte $00,$06,$49,$E2,$44,$08,$0F,$00
MinusTwo
    .byte $00,$06,$09,$E2,$04,$08,$0F,$00

    ORG   $FFFA

InterruptVectors
    .word Reset           ; NMI
    .word Reset           ; RESET
    .word Reset           ; IRQ

    END
