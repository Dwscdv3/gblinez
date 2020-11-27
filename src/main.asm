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



INCLUDE "includes.inc"



SECTION "Game", ROM0

Entry:
    ld sp, STACK_BASE
    call InitDMA
.initSystemVariables
    xor a
    ldh [FrameCount], a
    ldh [JoypadState], a
    ldh [PressedKeys], a
    ldh [VBlankHandlerEnabled], a
    ldh a, [rand_seed]  ; rand_seed * 2 + 1, ensure it's an odd number
    sla a
    inc a
    ldh [rand_seed], a
.configureInterrupts
    ld a, P1F_GET_DPAD
    ldh [rP1], a
    ld a, IEF_VBLANK | IEF_HILO
    ldh [rIE], a
    ei
.waitForVBlank
    halt
.screenOff
    ld a, LCDCF_OFF
    ld [rLCDC], a
.initOAM
    call ClearOAMBuffer
    ld l, SPRITE_CURSOR
    ld a, TILE_CURSOR
    call SetSprite_8x16x2
    ld l, SPRITE_SELECTION
    ld a, TILE_SELECTION
    call SetSprite_8x16x2
.loadTileset
    ld de, _VRAM
    ld hl, Tileset
    ld bc, Tileset.end - Tileset
    call memcpy
.initBGMap
    ld hl, _SCRN0 + SCRN_VX_B * 0 + 19
    ld c, SCRN_Y_B
    BeginLoop clearBGMap, c
        ld a, TILE_EMPTY
        ld [hl], a
        AddR16D8 h, l, SCRN_VX_B
    EndLoop clearBGMap, c
    ld hl, _SCRN0 + SCRN_VX_B * 0 + 18
    ld c, SCRN_Y_B
    BeginLoop loadBorder, c
        ld a, TILE_BORDER
        ld [hl], a
        AddR16D8 h, l, SCRN_VX_B
    EndLoop loadBorder, c
.initDisplay
    ld a, LCDCF_ON | LCDCF_BGON | LCDCF_BG8000 | LCDCF_OBJON | LCDCF_OBJ16
    ld [rLCDC], a
.initPalette
    ld a, %11100100
    ld [rBGP], a
    ld [rOBP0], a
    ld [rOBP1], a
.enableVBlankHandler
    write 1, VBlankHandlerEnabled
.soundOff
    ld a, AUDENA_OFF
    ld [rAUDENA], a
.initPathfinding
    write BOARD_WIDTH, Pathfinding_BoardWidth
    write BOARD_HEIGHT, Pathfinding_BoardHeight
    write BOARD_WIDTH * BOARD_HEIGHT, Pathfinding_BoardSize
    write HIGH(board), Pathfinding_BoardAddressHigh
.unitTest
    IF DEF(UnitTest)
        call UnitTest
    ENDC

InitGame:
.resetStack
    ld sp, STACK_BASE
.initVariables
    write 0, FrameCount
    write 0, scoreLow
    ld a, 0
    ld bc, SCORE_DIGIT_COUNT
    ld hl, scoreDigits
    call memset
    ld a, 0
    ld bc, 7
    ld hl, easterEgg_codebook
    call memset
    write 40, cursor
    call UpdateCursorPos
    write -1, selected
    call UpdateSelectionPos
    write BOARD_SIZE, remainingSpace
.initBoard
    ld a, 0
    ld bc, BOARD_SIZE
    ld hl, board
    call memset
.initStones
    REPT 5
        GetRandomVariant
        ld b, a
        call GetRandomEmptyCell
        call PlaceStone
    ENDR
    call GenerateUpcomingStones

Main:
.waitForVBlank
    halt
.checkIsVBlankInterrupt
    ldh a, [VBlankFlag]
    or a
    jr z, Main
    xor a
    ldh [VBlankFlag], a

    call Input
    call Game

    jr Main

Draw:
    ; Switch to H-Blank interrupt
    ld a, IEF_LCDC
    ldh [rIE], a
    ld a, STATF_MODE00
    ldh [rSTAT], a
IF !DEF(EASTER_EGG) || EASTER_EGG == 0
.score
    ld de, scoreDigits
    _CopyAddressDEToScreen 19, 17, TILE_DIGIT_0
    _CopyAddressDEToScreen 19, 16, TILE_DIGIT_0
    _CopyAddressDEToScreen 19, 15, TILE_DIGIT_0
    _CopyAddressDEToScreen 19, 14, TILE_DIGIT_0
    _CopyAddressDEToScreen 19, 13, TILE_DIGIT_0
ENDC
IF EASTER_EGG > 0
.easterEgg
EASTER_EGG_SYMBOL = 0
    REPT 7
        ld a, [easterEgg_codebook + EASTER_EGG_SYMBOL]
        or a
        ld a, TILE_BORDER
        ld b, TILE_EMPTY
        jr z, .easterEgg_\@_skip
        ld a, TILE_SYMBOL_0 + EASTER_EGG_SYMBOL
        ld b, TILE_DIGIT_0 + 1 + EASTER_EGG_SYMBOL
.easterEgg_\@_skip
        ld [_SCRN0 + 18 + (SCRN_Y_B - 1 - EASTER_EGG_SYMBOL) * SCRN_VX_B], a
        ld a, b
        ld [_SCRN0 + 19 + (SCRN_Y_B - 1 - EASTER_EGG_SYMBOL) * SCRN_VX_B], a
EASTER_EGG_SYMBOL = EASTER_EGG_SYMBOL + 1
    ENDR
ENDC
.board
    ld de, board
    ld hl, _SCRN0       ; (0, 0) of the game area
    ld c, BOARD_HEIGHT  ; Y counter
    BeginLoop y, c
        ld b, BOARD_WIDTH   ; X counter
        BeginLoop x, b
            HaltIfVRAMInaccessible      ; 8
            ld a, [de]                  ; 2
            TileIndexToAddress          ; 2
            ld [hl+], a                 ; 2
            add 2                       ; 2
            ld [hl-], a                 ; 2
            AddR16D8 h, l, SCRN_VX_B    ; 7
            HaltIfVRAMInaccessible      ; 8
            ld a, [de]                  ; 2
            TileIndexToAddress          ; 2
            inc a                       ; 1
            ld [hl+], a                 ; 2
            add 2                       ; 2
            ld [hl+], a                 ; 2
            SubR16D8 h, l, SCRN_VX_B    ; 7
            inc e                       ; 1
        EndLoop x, b
        AddR16D8 h, l, SCRN_VX_B * 2 - BOARD_WIDTH * 2
        ld l, a
    EndLoop y, c

    ; Restore normal interrupt
    ld a, IEF_VBLANK | IEF_HILO
    ldh [rIE], a
    ret

Game:
    call InputHandler
    ret

InputHandler:
    _InputHandler_Button PADB_A, .btnA
    _InputHandler_Button PADB_SELECT, .btnSelect
    _InputHandler_Button PADB_START, .btnStart
    ld c, LOW(JoypadState)
    ldh a, [c]
    bit PADB_B, a
    jr nz, .rapidMode
    ld c, LOW(PressedKeys)
.rapidMode
    _InputHandler_DPad PADB_RIGHT, .right
    _InputHandler_DPad PADB_LEFT, .left
    _InputHandler_DPad PADB_UP, .up
    _InputHandler_DPad PADB_DOWN, .down
    ret
.btnA
    GetCursorStoneVariant
    cp 0
    jr z, .emptyGrid
    SelectCursor
    ret
.emptyGrid
    call TryMove
    ret
.btnB
    ret
.btnSelect
    ret
.btnStart
    jp InitGame
.right
    _CursorMoveHandler 1, 0, 8, -1
.left
    _CursorMoveHandler -1, 0, 0, -1
.up
    _CursorMoveHandler 0, -1, -1, 0
.down
    _CursorMoveHandler 0, 1, -1, 8
.moveCursor
    ldh a, [cursor]
    add b
    ldh [cursor], a
    call UpdateCursorPos
    ret

TryMove:
    ldh a, [selected]
    cp 255
    ret z
    ldh [r1], a
    read e, cursor
    call Pathfinding_BFS
    or a
    call nz, Move
    ret

Move:
    ld h, HIGH(board)
    read l, selected
    write $FF, selected
    call UpdateSelectionPos
    ld a, [hl]
    TileIndexToAddress
    write a, r0     ; r0 = stone sprite address
    ld [hl], 0      ; remove stone from old place
    ld e, l
    ld l, SPRITE_MOVE
    call SetSprite_8x16x2
    Coord1DTo2D e, BOARD_WIDTH
    ld l, SPRITE_MOVE
    call SetSpritePos_8x16x2
    ld h, HIGH(Pathfinding_backtrace)
    ld l, e
.anim_loop
    ld a, BACKTRACE_FROM_BOTTOM
    cp [hl]
    jr z, .dir_down
    ld a, BACKTRACE_FROM_LEFT
    cp [hl]
    jr z, .dir_left
    ld a, BACKTRACE_FROM_TOP
    cp [hl]
    jr z, .dir_up
    ld a, BACKTRACE_FROM_RIGHT
    cp [hl]
    jr z, .dir_right
    ld a, BACKTRACE_ORIGIN
    cp [hl]
    jr z, .anim_loop_end
    call Exception
    _MoveAnimation_Direction down, 0, 1, BOARD_WIDTH
    _MoveAnimation_Direction left, -1, 0, -1
    _MoveAnimation_Direction up, 0, -1, -BOARD_WIDTH
    _MoveAnimation_Direction right, 1, 0, 1
.anim_loop_end
    ld h, HIGH(board)   ; l = cursor
    ldh a, [r0]
    srl a
    srl a
    ld [hl], a
    ld l, SPRITE_MOVE
    call HideSprite_8x16x2
    read l, cursor
    call CheckForMatch
    cp 5
    jr nc, .matched
    call PlaceUpcomingStones
    call GenerateUpcomingStones
    jr .end
.matched
IF EASTER_EGG > 0
    ld hl, easterEgg_codebook
    read a, r0
    dec a
    add l
    ld l, a
    ld [hl], 1
ENDC
.end
    ret

PlaceUpcomingStones:
    _PlaceUpcomingStone 0
    _PlaceUpcomingStone 1
    _PlaceUpcomingStone 2
    ret

GenerateUpcomingStones:
    push bc
    push de
    push hl
    ld hl, upcomingStones
    REPT 3
        GetRandomVariant
        ld [hl+], a
    ENDR
    ld de, upcomingStones
    UpdateUpcomingStoneSprite 0
    UpdateUpcomingStoneSprite 1
    UpdateUpcomingStoneSprite 2
    pop hl
    pop de
    pop bc
    ret

UpdateSelectionPos:
    push bc
    push hl
    ldh a, [selected]
    Coord1DTo2D a, BOARD_WIDTH
    ld hl, SPRITE_SELECTION
    call SetSpritePos_8x16x2
    pop hl
    pop bc
    ret

UpdateCursorPos:
    push bc
    push hl
    GetCursorXY
    ld l, SPRITE_CURSOR
    call SetSpritePos_8x16x2
    pop hl
    pop bc
    ret

; [out] a, l = an empty position
; [corrupt] h
GetRandomEmptyCell:
    push bc
    ldh a, [remainingSpace]
    ld c, a
    call Random_Safe
    ; Find nth empty cell
    ld c, a
    ld hl, board - 1
    inc c
    xor a
.loop
    inc hl
    cp [hl]
    jr nz, .loop    ; jump if cell is occupied
    dec c
    jr nz, .loop    ; jump if counter > 0
    pop bc
    ret

RecountRemainingSpace:
    xor a
    ld b, a
    ld hl, board
    ld c, BOARD_SIZE
    BeginLoop count, c
        cp [hl]
        jr nz, .notEmpty
        inc b
.notEmpty
        inc l
    EndLoop count, c
    write b, remainingSpace
    ret

; [in] l = search origin
; [out] a = destroyCandidatesCount
; [out] r0 = target variant checked
; [out] destroyCandidates
; [corrupt] b, c, d, e, h, l
CheckForMatch:
    Coord1DTo2D l, BOARD_WIDTH
    ld d, b
    ld e, c
    write 0, destroyCandidatesCount
    ld h, HIGH(board)
    ld c, [hl]          ; c = target stone variant
    _CheckDirectionPair .toTopLeft, .toBottomRight
    _CheckDirectionPair .toTop, .toBottom
    _CheckDirectionPair .toTopRight, .toBottomLeft
    _CheckDirectionPair .toLeft, .toRight
.destroy
    write c, r0
    read c, destroyCandidatesCount
    ld h, HIGH(ScoreTable)
    ld l, c
    ld b, [hl]
    call AddScore
    read c, destroyCandidatesCount
    ld hl, destroyCandidates
    ld d, HIGH(board)
    xor a
    BeginLoop destroy, c
        ld e, [hl]
        ld [de], a
        inc l
    EndLoop destroy, c
    call RecountRemainingSpace
    ldh a, [destroyCandidatesCount]
    ret

.toTopLeft
    _DecreaseWithBoundCheck, d
    _DecreaseWithBoundCheck, e
    inc a
    ret

.toBottomRight
    _IncreaseWithBoundCheck d, BOARD_WIDTH
    _IncreaseWithBoundCheck e, BOARD_HEIGHT
    inc a
    ret

.toTop
    _DecreaseWithBoundCheck e
    inc a
    ret

.toBottom
    _IncreaseWithBoundCheck e, BOARD_HEIGHT
    inc a
    ret

.toTopRight
    _IncreaseWithBoundCheck d, BOARD_WIDTH
    _DecreaseWithBoundCheck e
    inc a
    ret

.toBottomLeft
    _DecreaseWithBoundCheck d
    _IncreaseWithBoundCheck e, BOARD_HEIGHT
    inc a
    ret

.toLeft
    _DecreaseWithBoundCheck d
    inc a
    ret

.toRight
    _IncreaseWithBoundCheck d, BOARD_WIDTH
    inc a
    ret

; [in] b = consecutive stones in a row
; [in] c = target stone variant
; [in] de = coordinate of the origin
; [in] hl = address of the traverse handler (return 0 = outside bound, 1 = inside bound)
; [out] b += stones of the same variant found along the way
; [out] destroyCandidatesCount += b, if b >= 5
; [out] destroyCandidates
; [corrupt] a
; 12 cycles + 75 cycles per iteration
CheckSingleDirection:
    push de                 ; 4
.loop
    ; bound check
    push bc                 ; 4
    ld bc, .returningPoint  ; 3
    push bc                 ; 4     no need to pop
    push hl                 ; 4     no need to pop
    ret                     ; 4 +?  call [hl]
.returningPoint
    pop bc                  ; 3
    cp 0                    ; 1
    jr z, .cleanUp          ; 3|2
    ; variant check
    push hl                 ;   4
    ld h, HIGH(board)       ;   2
    _CompareToTarget        ;   10
    pop hl                  ;   3
    jr nz, .cleanUp         ;   3|2
    inc b                   ;     1
    _AddDestroyCandidates   ;     25
    jr .loop                ;     3
.cleanUp
    pop de                  ; 3
    ret                     ; 4

; [in] a, b = address of the traverse handler 1
; [in] c = target stone variant
; [in] de = coordinate of the origin
; [in] hl = address of the traverse handler 2
CheckDirectionPair:
    push hl
    ld h, a
    ld l, b
    ld b, 1             ; b = consecutive stones in a row
    _AddDestroyCandidates
    call CheckSingleDirection
    pop hl
    call CheckSingleDirection
    ld a, b
    cp 5
    jr nc, .confirmCandidates
    _CancelDestroyCandidates
.confirmCandidates
    ret

; [in] b = stone variant
; [in] l = position to be placed
; [corrupt] a, h
PlaceStone:
    ld h, HIGH(board)
    xor a
    cp [hl]
    call nz, Exception
    ld [hl], b      ; place stone
    ldh a, [remainingSpace]
    dec a
    ldh [remainingSpace], a
    ret

; [in] b = score to add
; [corrupt] a, b, c, h, l
AddScore:
    ldh a, [scoreLow]
    add b
    ldh [scoreLow], a
    call ToDecimal8
    ld hl, scoreDigits
    ld [hl+], a
    ld [hl], b
.hasDecimalCarry
    ldh a, [scoreLow]
    cp 100
    jr c, .noRipple
    sub 100
    ldh [scoreLow], a
    ld hl, scoreDigits + 2
.ripple
    REPT SCORE_DIGIT_COUNT - 2
        inc [hl]
        ld a, [hl]
        cp 10
        jr c, .hasDecimalCarry
        sub 10
        ld [hl], a
        inc hl
    ENDR
    jr .hasDecimalCarry
.noRipple
    ret

GameOver:
    ; TODO
    jp InitGame

VBlankInterrupt:
    ei
    push af
    push bc
    push de
    push hl
    ldh a, [VBlankHandlerEnabled]
    or a
    jr z, .skip
    ldh a, [rLY]
    cp SCRN_Y
    jr nz, .skip
    call StartDMA
    call Draw
.skip
    ld a, 1
    ldh [VBlankFlag], a
    ldh a, [FrameCount]
    inc a
    ldh [FrameCount], a
    pop hl
    pop de
    pop bc
    pop af
    reti

JoypadInterrupt:
    push af
    SeedRandom
    pop af
    reti
