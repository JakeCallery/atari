    PROCESSOR 6502

    include "./vcs.h"
    include "./macro.h"

    seg code
    org $F000

Reset: 
    CLEAN_START     ; reset memory and TIA to zero

    ldx #$80        ; load value for blue background into dx
    stx COLUBK      ; set background color

    lda #$1C        ; load value for yellow playfield into da
    sta COLUPF      ; set playfield color

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Start a new frame by turning on VBLANK and VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   
StartFrame:
    lda #02         ; value to enable VBLANK and VSYNC
    sta VBLANK      ; enable VBLANK
    sta VSYNC       ; enable VSYNC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Generate the three lines of VSYNC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    sta WSYNC   ; Wait for vsync
    sta WSYNC   ; Wait for vsync
    sta WSYNC   ; Wait for vsync

    lda #0      ;
    sta VSYNC   ; store 0 into VSYNC to turn off vsync
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Let the TIA output the recommended 37 scanlines of VBLANK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    REPEAT 37
        sta WSYNC
    REPEND

    lda #0
    sta VBLANK  ; Disable vblank

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set the CTRLPF register to allow playfield reflection
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ldx #%00000001  ; CTLPF register (D0 means reflect the Playfield)
    stx CTRLPF      ; Store the setting

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Draw the 192 visible scanlines (kernel)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ; Skip 7 scanlines with no PF set
    ldx #0
    stx PF0     ; Set left set of playfield columns for this scanline to disable
    stx PF1     ; Set middle set of playfield columns for this scanline to disabled
    stx PF2     ; Set right set of playfile columns for this scanline to disable
    REPEAT 7
        sta WSYNC ;Wait for 7 scanlines
    REPEND

    ; Draw top boarder of playfield
    ; Set PF0 1110 (LSB First) and PF1,PF2 to 1111 1111
    ; This creates a blank space on the left before the border starts
    ; This will then reflect past the mid point as CTRLPF is set to do that
    ldx #%11100000  ;PF0 only uses the most significant 4 bits
    stx PF0
    ldx #%11111111  ;PF1 and PF2 are 8 bits wide each
    stx PF1
    stx PF2
    REPEAT 7
        sta WSYNC
    REPEND

    ; Set the next 164 lines with the left and right border walls
    ldx #%00100000
    stx PF0
    
    ; Disable playfield for area inbetween the border walls
    ldx #0
    stx PF1
    stx PF2
    
    ; Keep settings the same for the next 164 scanlines
    REPEAT 164
        sta WSYNC
    REPEND

    ; Draw the bottom border wall
    ldx #%11100000  ;PF0 only uses the most significant 4 bits
    stx PF0
    ldx #%11111111  ;PF1 and PF2 are 8 bits wide each
    stx PF1
    stx PF2
    REPEAT 7
        sta WSYNC
    REPEND

    ; Skip last 7 scanlines
    ldx #0
    stx PF0     ; Set left set of playfield columns for this scanline to disable
    stx PF1     ; Set middle set of playfield columns for this scanline to disabled
    stx PF2     ; Set right set of playfile columns for this scanline to disable
    REPEAT 7
        sta WSYNC ;Wait for 7 scanlines
    REPEND

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Output 30 more VBLANK lines (overscan) to complete our frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #2 
    sta VBLANK  ; Turn VBLANK back on for overscan
    REPEAT 30
        sta WSYNC
    REPEND
    lda #0
    sta VBLANK  ; Turn VBLANK off again now that overscan is complete

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Loop over to start the next frame
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    jmp StartFrame

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Complete ROM size to 4KB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC
    .word Reset
    .word Reset
