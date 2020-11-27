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



IF !DEF(src_convert)
src_convert = 1



SECTION "Convert", ROM0

; [in] \1 = X
; [in] \2 = Y
; [out] a = 1D index
; 6 cycles
Coord2DTo1D_9: MACRO
    ld a, \2
    rlca
    rlca
    rlca
    add \2
    add \1
ENDM

; [in] \1 = 1D index
; [in] \2 = width, bdehl or immediate value
; [out] a, b = X
; [out] c = Y
; 13 bytes
; 6n + 13 cycles, or 5n + 11 cycles
Coord1DTo2D: MACRO
    ld c, 0                         ; 2 2
    ld a, \1                        ; 1 1
    jr .Coord1DTo2D_loop_start\@    ; 2 3
.Coord1DTo2D_loop_body\@
    inc c                           ; 1 1
.Coord1DTo2D_loop_start\@
    sub \2                          ; 2 2
    jr nc, .Coord1DTo2D_loop_body\@ ; 2 3|2
    add \2                          ; 2   2
    ld b, a                         ; 1   1
ENDM



ENDC
