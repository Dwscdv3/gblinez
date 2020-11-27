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



IF !DEF(src_memory)
src_memory = 1



SECTION "DwLib80_Memory", ROM0

read: MACRO
    ld a, [\2]
    ld \1, a
ENDM

write: MACRO
    ld a, \1
    ld [\2], a
ENDM

readh: MACRO
    ldh a, [\2]
    ld \1, a
ENDM

writeh: MACRO
    ld a, \1
    ldh [\2], a
ENDM

; [in] a = value to set
; [in] bc = length
; [in] hl = destination address
; [corrupt] b, c, h, l
memset:
    inc c
    inc b
    jr .start
.loop:
    ld [hl+], a
.start:
    dec c
    jr nz, .loop
    dec b
    jr nz, .loop
    ret

; [in] bc = length
; [in] de = destination address
; [in] hl = source address
; [corrupt] a, b = 0, c = 0, d, e, h, l
memcpy:
    inc c
    inc b
    jr .start
.loop:
    ld a, [hl+]
    ld [de], a
    inc de
.start:
    dec c
    jr nz, .loop
    dec b
    jr nz, .loop
    ret

; [in] c = length
; [in] hl = base address
; [corrupt] a, b, c, d, e, h, l
; 15 + c * 17 cycles
reverse:
    ld d, h     ; 1
    ld e, l     ; 1
    ld b, 0     ; 2
    add hl, bc  ; 2
    dec hl      ; 2
    srl c       ; 2
    inc c       ; 1
.loop
    dec c       ; 1
    ret z       ; 5|2
    ld b, [hl]  ;   2
    ld a, [de]  ;   2
    ld [hl-], a ;   2
    ld a, b     ;   1
    ld [de], a  ;   2
    inc de      ;   2
    jr .loop    ;   3

ENDC
