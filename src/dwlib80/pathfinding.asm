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



INCLUDE "tmp.asm"
INCLUDE "memory.asm"
INCLUDE "math.asm"
INCLUDE "convert.asm"



SECTION "DwLib80_Pathfinding_Buffer", WRAM0, ALIGN[8]

BACKTRACE_FROM_BOTTOM   EQU $F1
BACKTRACE_FROM_LEFT     EQU $F2
BACKTRACE_FROM_TOP      EQU $F3
BACKTRACE_FROM_RIGHT    EQU $F4
BACKTRACE_ORIGIN        EQU $F5

; This is a hybrid buffer for both board clone and backtrace info.
; For board, 0 is treated as passable, otherwise obstacle.
; For backtrace:
; 0 = not visited yet
; 1 = from bottom
; 2 = from left
; 3 = from top
; 4 = from right
; 5 = origin
Pathfinding_backtrace:  ds 256
_Pathfinding_frontier:  ds 256



SECTION "DwLib80_Pathfinding_Variables", HRAM

; board should be aligned to $XX00 and less than 256 bytes
Pathfinding_BoardAddressHigh:   db
Pathfinding_BoardWidth:         db
Pathfinding_BoardHeight:        db
Pathfinding_BoardSize:          db



SECTION "DwLib80_Pathfinding", ROM0

; [in] \1 = data to be enqueued
; 18 cycles
_Pathfinding_frontier_enqueue: MACRO
    push hl
    readh l, r0
    ld [hl], \1
    inc l
    writeh l, r0
    pop hl
ENDM

; [out] \1 = register to receive data
; 3 cycles
_Pathfinding_frontier_dequeue: MACRO
    ld \1, [hl]
    inc l
ENDM

; [in] \1 = backtrace info
_Pathfinding_addToFrontier: MACRO
    _Pathfinding_frontier_enqueue e
    ld a, \1
    ld [de], a
ENDM

; [in] b = X
; [in] c = Y
; [in] d = HIGH(Pathfinding_backtrace)
; [in] e = 1D index
; [out] a = boolean
; [corrupt] r2
; 0 is treated as empty, otherwise obstacle
; Valid when:  in bound  &&  empty  &&  not visited before
; invalid any cells after target
; 37 cycles (worst case)
_Pathfinding_IsValidCell:
.checkX                 ; 8|7
    ldh a, [Pathfinding_BoardWidth]
    dec a
    cp b
    jr c, .false
.checkY                 ; 8|7
    ldh a, [Pathfinding_BoardHeight]
    dec a
    cp c
    jr c, .false
.checkIsTarget          ; 13|12
    ldh a, [r2]
    or a
    jr nz, .false
    ldh a, [r1]
    cp e
    jr z, .target
.checkEmptyAndVisited   ; 6|5
    ld a, [de]
    or a
    jr nz, .false
.true                   ; 6
    ld a, 1
    ret
.false                  ; 5
    xor a
    ret
.target                 ; 8
    writeh 1, r2
    ret

; [in] e = origin index
; [in] r1 = target
; [out] a = found (boolean)
; [out] Pathfinding_backtrace
; [corrupt] b, c, d, e, h, l, r0
Pathfinding_BFS:
    ; Copy board to backtrace buffer to save 2 registers from tracing board address.
    push bc
    push de
    xor a
    ld b, a
    ld e, a
    ld l, a
    ldh a, [Pathfinding_BoardSize]
    ld c, a
    ld d, HIGH(Pathfinding_backtrace)
    ldh a, [Pathfinding_BoardAddressHigh]
    ld h, a
    call memcpy
    pop de
    pop bc
    ld d, HIGH(Pathfinding_backtrace)
    ld hl, _Pathfinding_frontier
    write 0, r0
    write 0, r2

    _Pathfinding_frontier_enqueue e
    ld a, BACKTRACE_ORIGIN
    ld [de], a  ; backtrace[origin] = ORIGIN

    ; de = backtrace buffer
    ; hl = frontier buffer
    ; r0 = frontier queue tail (entrance)
    ; r2 = target accessed indicator
.loop_condition ; while (l != r0)
    ldh a, [r0]
    cp l
    jp z, .notFound
.loop_body
    _Pathfinding_frontier_dequeue e

    ldh a, [r1]
    cp e
    jr z, .found

    ldh a, [Pathfinding_BoardWidth]
    ld b, a
    Coord1DTo2D e, b

.up
    dec c
    ldh a, [Pathfinding_BoardWidth]
    sub e
    neg
    ld e, a
    call _Pathfinding_IsValidCell
    or a
    jr z, .up_skip
    _Pathfinding_addToFrontier BACKTRACE_FROM_BOTTOM
.up_skip    ; revert position change here
    ldh a, [Pathfinding_BoardWidth]
    add e
    ld e, a
    inc c
.right
    inc b
    inc e
    call _Pathfinding_IsValidCell
    or a
    jr z, .right_skip
    _Pathfinding_addToFrontier BACKTRACE_FROM_LEFT
.right_skip
    dec e
    dec b
.down
    inc c
    ldh a, [Pathfinding_BoardWidth]
    add e
    ld e, a
    call _Pathfinding_IsValidCell
    or a
    jr z, .down_skip
    _Pathfinding_addToFrontier BACKTRACE_FROM_TOP
.down_skip
    ldh a, [Pathfinding_BoardWidth]
    sub e
    neg
    ld e, a
    dec c
.left
    dec b
    dec e
    call _Pathfinding_IsValidCell
    or a
    jr z, .left_skip
    _Pathfinding_addToFrontier BACKTRACE_FROM_RIGHT
.left_skip
    inc e
    inc b

    jp .loop_condition

.notFound
    xor a
    ret
.found
    ld a, 1
    ret

