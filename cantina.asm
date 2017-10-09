    ;; Pazaak for the 2600

    processor 6502
    include "vcs.h"
    include "macro.h"

    ;; Cards are one byte: higher nibble is type, lower is value.
    ;; Type is mapped as follows:
    ;;   0 => +
    ;;   1 => -
    ;;   2 => +/-
    ;;   3 => flip
    ;;   4 => double
    ;;   5 => tiebreaker
    ;;
    ;; Value is a simple number, with the following exceptions,
    ;; according to card type:
    ;;   In the case of +/-, a value of 7 means "1 or 2"
    ;;   In the case of flip, values can only be 2, 3, 4, 6
    ;;   In the case of double or tiebreaker, value is ignored
    ;;
    ;; Note that card types will be progressively implemented.

    ;; Arrow colours are used to reflect joystick input (left/right)
LEFT_ARROW_COLOUR = $80
RIGHT_ARROW_COLOUR = $81
LAST_SWCHA = $82

    ;; Currently selected side-deck card
SIDE_DECK_SELECTED = $83  ; increment on SIDE_DECK (0..3)

    ;; 4-card side deck for the game
SIDE_DECK = $84           ; 4 bytes

SCRATCH = $88
TYPE_SPRITE_OFFSET = $89
VALUE_SPRITE_OFFSET = $8A

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
    sta   NUSIZ0
    ;; ------------------------------------------------

    ;; Pre-loaded side deck, for testing
    ldx   #0
    lda   $00           ; +1
    sta   SIDE_DECK,X
    inx
    lda   $10           ; -1
    sta   SIDE_DECK,X
    inx
    lda   $01           ; +2
    sta   SIDE_DECK,X
    inx
    lda   $11           ; -2
    sta   SIDE_DECK,X

    ;; More test data
    lda   #2            ; third card of side deck
    sta   SIDE_DECK_SELECTED

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

    ;; example: -1 is 00010001
    ;;  need to take card type value, 1 (minus sign), in left nibble
    ;;  multiple by 8 and put in right nibble:
    ;;    00001000
    ;;  after rotating once to right, AND with 11111000 ($f8) to clear
    ;;  rest of right nibble

    ;; load selected side-deck card type/value
    ldx   SIDE_DECK_SELECTED ; 3 (3)
    lda   SIDE_DECK,X        ; 4 (7)
    lsr                      ; 2 (9)
    and   #$f8               ; 2 (11)
    ;; A now contains offset from CardTypes for first line of sprite
    sta   TYPE_SPRITE_OFFSET ; 3 (14)

    ;; Now same with card value.  It is in right nibble, so clear
    ;; left and then multiple by 8.
    lda   SIDE_DECK,X        ; 4 (18)
    and   #$0f               ; 2 (20)
    asl                      ; 2 (22)
    asl                      ; 2 (24)
    asl                      ; 2 (26)
    sta   VALUE_SPRITE_OFFSET; 3 (29)

    ;; Nudge card type over
    lda   #$40
    sta   HMP1
    sta   WSYNC
    sta   WSYNC

    ;; Display side-deck selector: left arrow, current side-deck card
    ;; type, current side-deck card value (if any), right arrow
    ;; (4 "sprites").
    ;; Y contains current line, from 0, used to select line from
    ;; sprites.

    ldy   #0
DisplayArrowLine
    sta   WSYNC              ; 3 (X / 75)
    ;; set colour and pixels for left playfield
    lda   LEFT_ARROW_COLOUR  ; 3 (3)
    sta   COLUPF             ; 3 (6)
    lda   Arrow,Y            ; 4 (10)
    sta   PF0                ; 3 (13)

    tya                      ; 2 (15)
    adc   TYPE_SPRITE_OFFSET ; 3 (18)
    tax                      ; 2 (20)
    lda   CardTypes,X        ; 4 (24) * might be 5 if crossing page
    sta   GRP0               ; 3 (27)

    tya                      ; 2 (29)
    adc   VALUE_SPRITE_OFFSET; 3 (32)
    tax                      ; 2 (34)
    lda   CardValues,X       ; 4 (38)
    sta   GRP1               ; 3 (41)
    sta   RESP0              ; 3 (44)
    sta   RESP1              ; 3 (47)

    ;; maximum allowed time before we have to set the right playfield
    sleep 12                 ; 12 (59)

    ; set colour and pixels for right playfield
    lda   RIGHT_ARROW_COLOUR ; 3 (62)
    sta   COLUPF             ; 3 (65)
    iny                      ; 2 (67)

    ;; card and arrows are 8 lines high
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

;--------------------------------------------------------------------

CardTypes
    ;; Plus
    .byte $00,$00,$10,$10,$7C,$10,$10,$00
    ;; Minus
    .byte $00,$00,$00,$00,$7C,$00,$00,$00
    ;; TODO: +/-, flip, double, tiebreaker

CardValues
    ;; One
    .byte $00,$08,$18,$08,$08,$08,$1C,$00
    ;; Two
    .byte $00,$18,$24,$04,$08,$10,$3C,$00
    ;; TODO: three, four, five, six, seven, eight, nine, ten
    ;; (seven to ten for main deck only)

Arrow
    .byte $00,$00,$80,$C0,$E0,$C0,$80,$00

    ORG   $FFFA

InterruptVectors
    .word Reset           ; NMI
    .word Reset           ; RESET
    .word Reset           ; IRQ

    END
