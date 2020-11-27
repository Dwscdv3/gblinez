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



SECTION "UnitTest", ROM0

; [in] \1 = dividend
; [in] \2 = divisor
; [in] \3 = expected quotient
; [in] \4 = expected remainder
UnitTest_Divide: MACRO
    ld b, \1
    ld c, \2
    call Divide
    cp \4
    call nz, Exception
    ld a, b
    cp \3
    call nz, Exception
ENDM

UnitTest_AddScore: MACRO
.UnitTest_AddScore_\1_\2
    write \1 % 100000 / 10000, scoreDigits + 4
    write \1 % 10000 / 1000, scoreDigits + 3
    write \1 % 1000 / 100, scoreDigits + 2
    write \1 % 100 / 10, scoreDigits + 1
    write \1 % 10 / 1, scoreDigits + 0
    write \1 % 100, scoreLow
    ld b, \2
    call AddScore
    ld hl, scoreDigits + 4
    ld a, (\1 + \2) % 100000 / 10000
    cp [hl]
    call nz, Exception
    ld hl, scoreDigits + 3
    ld a, (\1 + \2) % 10000 / 1000
    cp [hl]
    call nz, Exception
    ld hl, scoreDigits + 2
    ld a, (\1 + \2) % 1000 / 100
    cp [hl]
    call nz, Exception
    ld hl, scoreDigits + 1
    ld a, (\1 + \2) % 100 / 10
    cp [hl]
    call nz, Exception
    ld hl, scoreDigits + 0
    ld a, (\1 + \2) % 10 / 1
    cp [hl]
    call nz, Exception
    ld hl, scoreLow
    ld a, (\1 + \2) % 100
    cp [hl]
    call nz, Exception
ENDM

UnitTest:
    UnitTest_Divide 0, 0, 0, 0
    UnitTest_Divide 1, 0, 1, 0
    UnitTest_Divide 128, 1, 128, 0
    UnitTest_Divide 127, 2, 63, 1
    UnitTest_Divide 20, 3, 6, 2
    UnitTest_Divide 255, 85, 3, 0
    UnitTest_Divide 254, 255, 0, 254
    UnitTest_Divide 0, 6, 0, 0
    UnitTest_Divide 255, 84, 3, 3
    UnitTest_AddScore 12138, 10
    UnitTest_AddScore 12138, 108
    UnitTest_AddScore 12138, 156
    
    ; Random uniform test
;     ld a, 17
;     ldh [rand_seed], a
;     ld c, 254
;     xor a
;     ld h, HIGH(_RAM)
;     ld l, a
;     ld d, c
; .random_init_loop
;     ld [hl+], a
;     dec d
;     jr nz, .random_init_loop
    
;     REPT 16
;         ld b, 255
; .random_loop\@
;         push bc
;         call Random
;         pop bc
;         ld h, HIGH(_RAM)
;         ld l, a
;         inc [hl]
;         dec b
;         jr nz, .random_loop\@
;     ENDR
    
    ret
