; Copyright (C) 2020  Dwscdv3 <dwscdv3@hotmail.com>
;
; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
; 
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
; 
; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <https://www.gnu.org/licenses/>.



; Not used the LOAD command due to unknown crashes in the linker.



IF !DEF(src_oam)
src_oam = 1



INCLUDE "../lib/hardware.inc"
INCLUDE "memory.asm"



SECTION "DwLib80_OAM_Buffer", WRAM0, ALIGN[8]

OAMBuffer:      ds $A0



SECTION "DwLib80_OAM", ROM0

ClearOAMBuffer:
    xor a
    ld bc, $A0
    ld hl, OAMBuffer
    call memset
    ret

; [in] a = tile address
; [in] l = sprite address
; [corrupt] a, h, l
; 25 cycles
SetSprite_8x16x2:
    push hl         ; 4
    ld h, HIGH(OAMBuffer) ; 2
    inc l           ; 1
    inc l           ; 1
    ld [hl], a      ; 2
    inc l           ; 1
    inc l           ; 1
    inc l           ; 1
    inc l           ; 1
    add 2           ; 2
    ld [hl], a      ; 2
    pop hl          ; 3
    ret             ; 4

; [in] b = X
; [in] c = Y
; [in] l = sprite address
; [corrupt] a, h, l
; 45 cycles
SetSpritePos_8x16x2:
    push hl         ; 4
    ld h, HIGH(OAMBuffer) ; 2
    ld a, c         ; 1
    REPT 4          ; 4
        rlca
    ENDR
    add 16          ; 2
    ld [hl+], a     ; 2  tile[0].Y
    inc l           ; 1
    inc l           ; 1
    inc l           ; 1
    ld [hl-], a     ; 2  tile[1].Y
    dec l           ; 1
    dec l           ; 1
    ld a, b         ; 1
    REPT 4          ; 4
        rlca
    ENDR
    add 8           ; 2
    ld [hl+], a     ; 2  tile[0].X
    inc l           ; 1
    inc l           ; 1
    inc l           ; 1
    add 8           ; 2
    ld [hl], a      ; 2  tile[1].X
    pop hl          ; 3
    ret             ; 4

; [in] l = sprite address
; 23 cycles
HideSprite_8x16x2:
    push hl         ; 4
    ld h, HIGH(OAMBuffer) ; 2
    ld [hl], 0      ; 3
    REPT 4          ; 4
        inc l
    ENDR
    ld [hl], 0      ; 3
    pop hl          ; 3
    ret             ; 4



SECTION "DwLib80_DMA", ROM0

InitDMA:
    ld bc, DMAProc.end - DMAProc
    ld de, DMAProc_HRAM
    ld hl, DMAProc
    call memcpy
    ret

; [corrupt] a, b, c
StartDMA:
    ld a, HIGH(OAMBuffer)
    ld bc, 41 * $100 + LOW(rDMA)
    jp DMAProc_HRAM

; 5 bytes
DMAProc:
    ldh [c], a
.wait
    dec b           ; 1
    jr nz, .wait    ; 3|2
    ret             ;   4
.end



SECTION "DwLib80_DMA_HRAM", HRAM

DMAProc_HRAM:   ds DMAProc.end - DMAProc



ENDC
