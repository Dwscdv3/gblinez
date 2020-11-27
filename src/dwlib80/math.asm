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



IF !DEF(src_math)
src_math = 1



SECTION "DwLib80_Math", ROM0

neg: MACRO
    cpl
    inc a
ENDM

; [in] \1 = R16 (high)
; [in] \2 = R16 (low)
; [in] \3 = D8
; [corrupt] a
; 7 bytes, 7 cycles
AddR16D8: MACRO
    ld a, \2            ; 1 1
    add \3              ; 2 2
    ld \2, a            ; 1 1
    jr nc, .noCarry\@   ; 2 3|2
    inc \1              ; 1   1
.noCarry\@
ENDM

; [in] \1 = R16 (high)
; [in] \2 = R16 (low)
; [in] \3 = D8
; 7 cycles
SubR16D8: MACRO
    ld a, \2            ; 1
    sub \3              ; 2
    ld \2, a            ; 1
    jr nc, .noCarry\@   ; 3|2
    dec \1              ;   1
.noCarry\@
ENDM

; [in] a = binary integer
; [out] a = 10^0 place
; [out] b = 10^1 place
; [out] c = 10^2 place
; 94 cycles (worst case: 190 ~ 199)
ToDecimal8:
    ld b, 0         ; 2
    ld c, 0         ; 2
.hundreds
    cp 100          ; 1
    jr c, .tens     ; 3|2
    sub 100         ;   1
    inc c           ;   1
    jr .hundreds    ;   3
.tens
    cp 10           ; 1
    ret c           ; 5|2
    sub 10          ;   1
    inc b           ;   1
    jr .tens        ;   3
    
_DivideBit: MACRO
.bit\1
    sub c               ; 1
    jr c, .bit\1_is0    ; 3|2
.bit\1_is1
    set \1, b           ;   2
    jr .bit\1_step      ;   2
.bit\1_is0
    add c               ; 1
.bit\1_step
    srl c               ; 2
ENDM

; [in] b = dividend
; [in] c = divisor
; [out] a = remainder
; [out] b = quotient
; [corrupt] c, d, e, h, l
; 144 cycles (worst case: quotient = 1), 37 cycles (best case: quotient >= 128)
Divide:
    ld a, c             ; 1
    or a                ; 1
    ret z               ; 5|2
    
    ld de, 0            ; 3
    
    jr .checkDivisorLessThan128 ; 2
.shlDivisor
    rlca                ; 1
    inc e               ; 1
.checkDivisorLessThan128
    cp $80              ; 1
    jr c, .shlDivisor   ; 3|2
    ld c, a             ; 1
    
    ld a, b             ; 1
    ld b, 0             ; 2
    ld hl, .jumpTable   ; 3
    sla e               ; 2
    add hl, de          ; 2
    jp hl               ; 1
.jumpTable              ; 2
    jr .bit0
    jr .bit1
    jr .bit2
    jr .bit3
    jr .bit4
    jr .bit5
    jr .bit6
    jr .bit7
    
    _DivideBit 7
    _DivideBit 6
    _DivideBit 5
    _DivideBit 4
    _DivideBit 3
    _DivideBit 2
    _DivideBit 1
    _DivideBit 0
    
.end
    ret                 ; 4



ENDC
