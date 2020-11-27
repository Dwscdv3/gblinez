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



IF !DEF(src_rand)
src_rand = 1



SECTION "DwLib80_Random_Data", ROM0, ALIGN[8]

RandomTable:
db 157,  20,  90, 166,  10, 158, 132, 211,  35,   4, 224, 167, 176,  88, 143,  96
db 177,  34, 174,   6, 205,  62, 200,  39, 155,   1, 251,  21, 169,  15, 170, 124
db 234, 201,  53,  44, 138, 153, 185, 214, 133, 139, 252, 100, 195, 243, 140,  80
db 221,   3, 145, 227,  87, 194, 228,  98, 119, 181, 173,  37,  41, 126,  93, 236
db  57, 215, 136, 247,  94, 192, 202,  27, 114,   8, 254, 172, 125, 144, 168, 242
db  50,  47,  68, 137, 106,  63, 180,  77, 134,  74,  52,  30, 238, 212,  49, 109
db  67,  13, 246,  36,  55, 163, 237, 182,  42,  28,  24, 146, 115, 220, 249, 164
db 107,  92, 160,  83, 127, 101,  97, 175, 248, 206, 149, 128,  17,  81, 226,   0
db 135, 179, 116,  16, 148,  56,  69, 141,   5, 207, 104, 230, 203,  85,  32, 129
db  54,  26, 239,  38,  43,  61, 150,  89,  75,  64,  12, 216,  45, 154, 111, 122
db 223,  76, 229, 217, 105,   2,  60, 196,   7,  59, 151,  91, 113, 204, 108, 178
db 190,  22, 110, 189, 131, 253, 162, 112, 209,  86,  82, 210, 156, 241,  48, 219
db 161, 191, 142,  65,  14,  73,  40, 199,  23,  46, 187, 102,  25, 103, 225,  95
db  19,  66,  58, 147, 188,   9, 244, 165, 255,  33, 232, 184, 117,  99, 121,  31
db 159,  11, 198, 233, 235, 218,  79, 118, 240, 222,  72,  18,  51, 183, 171,  71
db 130, 250, 208, 193, 197,  29,  84, 152, 123, 245, 186,  78, 120, 213,  70, 231

RandomBiasCheckTable:
db 255, 255, 255, 254, 255, 254, 251, 251, 255, 251, 249, 252, 251, 246, 251, 254
db 255, 254, 251, 246, 239, 251, 241, 252, 239, 249, 233, 242, 251, 231, 239, 247
db 255, 230, 237, 244, 251, 221, 227, 233, 239, 245, 251, 214, 219, 224, 229, 234
db 239, 244, 249, 254, 207, 211, 215, 219, 223, 227, 231, 235, 239, 243, 247, 251
db 255, 194, 197, 200, 203, 206, 209, 212, 215, 218, 221, 224, 227, 230, 233, 236
db 239, 242, 245, 248, 251, 254, 171, 173, 175, 177, 179, 181, 183, 185, 187, 189
db 191, 193, 195, 197, 199, 201, 203, 205, 207, 209, 211, 213, 215, 217, 219, 221
db 223, 225, 227, 229, 231, 233, 235, 237, 239, 241, 243, 245, 247, 249, 251, 253
db 255, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142
db 143, 144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158
db 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174
db 175, 176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190
db 191, 192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206
db 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222
db 223, 224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238
db 239, 240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254



SECTION "DwLib80_Random", ROM0

; [corrupt] a
; 7 cycles
SeedRandom: MACRO
    ldh a, [rDIV]
    ; Map even numbers to odd numbers for best RNG quality
    set 0, a
    ldh [rand_seed], a
ENDM

; [out] a = random number between [0 ~ 256)
; [corrupt] h, l
; 20 cycles
Random8:
    ldh a, [rand_cursor]    ; 3
    ld l, a                 ; 1
    ldh a, [rand_seed]      ; 3
    add l                   ; 1
    ldh [rand_cursor], a    ; 3
    ld l, a                 ; 1
    ld h, HIGH(RandomTable) ; 2
    ld a, [hl]              ; 2
    ret                     ; 4
    
; [in] c = upper bound (exclusive), cannot be 0
; [out] a = random number between [0 ~ c)
; [corrupt] b, c, d, e, h, l
; ~170 cycles (worst case)
Random:
    call Random8                        ; 6 +20
    ld h, HIGH(RandomBiasCheckTable)    ; 2
    ld l, c                             ; 1
    cp [hl]                             ; 2
    jr c, .mod                          ; 3|2
    jr z, .mod                          ;   3|2
    jr Random                           ;     2
.mod
    ld b, a                             ; 1
    call Divide                         ; 6 +35~142
    ret                                 ; 4
    
; Random with register preservation
; [in] c = upper bound (exclusive), cannot be 0
; [out] a = random number between [0 ~ c)
; ~170 + 34 cycles (worst case)
Random_Safe:
    push bc
    push de
    push hl
    call Random
    pop hl
    pop de
    pop bc
    ret


SECTION "DwLib80_Random_Variables", HRAM

rand_cursor:    db
rand_seed:      db



ENDC
