   processor 6502

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Include required files with register mapping and macros
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    include "vcs.h"
    include "macro.h"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start an uninitialized segment at $80 for var declaration.
;; We have memory from $80 to $FF to work with, minus a few at
;; the end if we use the stack.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg.u Variables
    org $80
P0XPos   byte      ; sprite X coordinate

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start our ROM code segment starting at $F000.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    seg Code
    org $F000

Reset:
    CLEAN_START    ; macro to clean memory and TIA

    ldx #$00       ; black background color
    stx COLUBK

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialize variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #40
    sta P0XPos     ; initialize player X coordinate

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start a new frame by configuring VBLANK and VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
StartFrame:
    lda #2
    sta VBLANK     ; turn VBLANK on
    sta VSYNC      ; turn VSYNC on

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Display 3 vertical lines of VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    REPEAT 3
        sta WSYNC  ; first three VSYNC scanlines
    REPEND
    lda #0
    sta VSYNC      ; turn VSYNC off

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set player horizontal position while in VBLANK
;; 1 CPU clock is 3 TIA color clocks
;; Wait for new scan line, then wait (X + 68)/3 cpu cycles
;; HBLANK (left) is 68 TIA color clocks (pixels)
;; Visible scanline is 160 TIA color clocks (pixels)
;; simple loop is a total of 5 clock cycles (dex(2) and bne(3))
;; Use loop to get to closest 15pixel block (5 cpu clocks * 3 color clocks = 15pixels)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda P0XPos          ; load reg A with current x pos
    and #$7F            ; same as ANS 01111111, forces bit 7 to 0 (sign bit)
    sta WSYNC           ; wait for next scanline
    sta HMCLR           ; clear old horizontal position info

    sec                 ; set carry flag before subtraction

DivideLoop:              ; A contains desired x position / loop costs 15 color clocks
    sbc #15             ; A -= 15
    bcs DivideLoop       ; loop will carry flag is still set
                        ; After the loop A contains the remainder of the division
    eor #7              ; adjust remainder in A between -8 and 7 (exclusive or)
    asl                 ; left shift 4 times, as HMP0 uses only most sig 4 bits
    asl 
    asl 
    asl 
    sta HMP0            ; stick remainder into fine position register (horizontal motion player 0)
    sta RESP0           ; strobe player 0 reset / finalize x position
    sta WSYNC           ; wait for next scanline
    sta HMOVE           ; apply the fine position offset

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Let the TIA output the 37 - 2 (2 used for x position) recommended lines of VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    REPEAT 35           ; not sure if this should be 35 or 37 (used 2 scanlines during x position set)
        sta WSYNC
    REPEND

    lda #0
    sta VBLANK     ; turn VBLANK off

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Draw the 192 visible scanlines
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    REPEAT 60
        sta WSYNC  ; wait for 60 empty scanlines
    REPEND

    ldy 8          ; counter to draw 8 rows of bitmap
DrawBitmap:
    lda P0Bitmap,Y ; load player bitmap slice of data
    sta GRP0       ; set graphics for player 0 slice

    lda P0Color,Y  ; load player color from lookup table
    sta COLUP0     ; set color for player 0 slice

    sta WSYNC      ; wait for next scanline

    dey
    bne DrawBitmap ; repeat next scanline until finished

    lda #0
    sta GRP0       ; disable P0 bitmap graphics

    REPEAT 124
        sta WSYNC  ; wait for remaining 124 empty scanlines
    REPEND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Output 30 more VBLANK overscan lines to complete our frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
Overscan:
    lda #2
    sta VBLANK     ; turn VBLANK on again for overscan
    REPEAT 30
        sta WSYNC
    REPEND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Increment X coordinate before next frame for animation.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    inc P0XPos
    lda P0XPos
    sbc #80
    bne NoResetX
    lda #40
    sta P0XPos
NoResetX:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Loop to next frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    jmp StartFrame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Lookup table for the player graphics bitmap.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
P0Bitmap:
    byte #%00000000
    byte #%00010000
    byte #%00001000
    byte #%00011100
    byte #%00110110
    byte #%00101110
    byte #%00101110
    byte #%00111110
    byte #%00011100

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Lookup table for the player colors.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
P0Color:
    byte #$00
    byte #$02
    byte #$02
    byte #$52
    byte #$52
    byte #$52
    byte #$52
    byte #$52
    byte #$52

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Complete ROM size
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC
    word Reset
    word Reset

