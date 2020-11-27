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



INCLUDE "controlflow.asm"
INCLUDE "oam.asm"



SECTION "DwLib80_BlockingAnimation", ROM0

; [in] b = total sprites
; [in] c = total frames
; [in] d = delta X per frame
; [in] e = delta Y per frame
; [in] hl = base sprite address
; Move a range of sprites linearly.
; Will block execution until animation is completed.
SimpleLinearAnimation:
    ; Switch to V-Blank interrupt
    ldh a, [rIE]
    ld [animation_rIE_backup], a
    ld a, IEF_VBLANK
    ldh [rIE], a
    ei

    ld h, HIGH(OAMBuffer)
    ld a, b
    ld [animation_sprites_backup], a
    BeginLoop frame, c
        ld a, [animation_sprites_backup]
        ld b, a
        push hl
        BeginLoop sprite, b
            ld a, [hl]
            add e
            ld [hl+], a
            ld a, [hl]
            add d
            ld [hl+], a
            inc l
            inc l
        EndLoop sprite, b
        halt
        pop hl
    EndLoop frame, c

    ; Restore interrupt
    ld a, [animation_rIE_backup]
    ldh [rIE], a

    ret


SECTION "DwLib80_BlockingAnimation_Temp", WRAM0

animation_rIE_backup:     db
animation_sprites_backup: db
