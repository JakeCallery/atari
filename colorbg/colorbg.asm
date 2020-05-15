    processor 6502
    
    include "macro.h"
    include "vcs.h"
    
    seg code
    org $F000       ; defines the origin of the ROM at $F000

START:
    CLEAN_START     ; Macro to safely clear the memory

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Set background luminosity color to yellow
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    lda #$1E        ; Load color into Reg A ($1E is NTSC yellow)
    sta COLUBK      ; store A to Background Color Address $09

    jmp START       ; Repeat from START

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Fill ROM size to exactly 4KB
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    org $FFFC       ; Defines origin to $FFFC
    .word START     ; Reset vector at $FFFC (where program starts)
    .word START     ; Interrupt vector at $FFFE (unused for VCS)