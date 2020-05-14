        processor 6502

        seg code
        org $F000       ; defines the code origin at $F000

Start:
        sei             ; disable the interrupts
        cld             ; disable the BCD decimal math mode
        ldx #$FF        ; loads the X register with #$FF
        txs             ; transfer x reg to stack pointer register (S)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Clear the Zero Page region ($00 to $FF)
; Meaning the entire TIA register space and also RAM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        lda #0          ; A = 0
        ldx #$FF        ; X = #$FF


; Starts at high end of memory and works back to 0, storing zeros in each location
ClearMemLoop:           
        sta $0,X        ; Store 0 (from reg a) at address $0 + X (Starts at $FF and works back)
        dex             ; x--
        bne ClearMemLoop; loop until X==0 (z-flag set to 1, when reg x gets to 0)
        sta $0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Fill ROM size to exactly 4KB last 4 bytes is the address
; of where the atari reads from after a reset 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
        org $FFFC       ; Force pointer to $FFFC to write the pointer address (4 bytes)
                        ; Mem addresses are 16 bits, or 2 words
                        
        .word Start     ; reset vector at $FFFC (where program starts)
        .word Start     ; interrupt vector at $FFFE (unused in VCS, but needed to fill 4K)
