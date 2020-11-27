SECTION "Abstractions", ROM0

; From least significant to most significant, one call per digit
; \1 = X coordinate
; \2 = Y coordinate
; \3 = tile index offset
; 10 cycles
_CopyAddressDEToScreen: MACRO
    ld hl, _SCRN0 + SCRN_VX_B * \2 + \1 ; 3
    ld a, [de]                          ; 2
    add \3                              ; 2
    inc e                               ; 1
    ld [hl], a                          ; 2
ENDM

; 8 cycles waste if not halt
HaltIfVRAMInaccessible: MACRO
    ldh a, [rSTAT]      ; 3
    and STATF_BUSY      ; 2
    jr z, .noHalt\@     ; 3|2
    halt
.noHalt\@
ENDM

; \1 = base sprite address (high byte is not used)
; \2 = total sprites
; \3 = delta X per frame
; \4 = delta Y per frame
; \5 = total frames
StartAnimation: MACRO
    ld hl, \1
    ld b, \2
    ld d, \3
    ld e, \4
    ld c, \5
    call SimpleLinearAnimation
ENDM

; [out] a = Random(7) + 1
GetRandomVariant: MACRO
    ld c, 7
    call Random_Safe
    inc a
ENDM

; [in] a = tile index
; [out] a = tile address
TileIndexToAddress: MACRO
    rlca
    rlca
ENDM

; [in] a = tile address
; [a] a = tile index
TileAddressToIndex: MACRO
    rrca
    rrca
ENDM

; [in] \1 = index (0, 1, 2)
UpdateUpcomingStoneSprite: MACRO
    ld l, SPRITE_NEXT\1
    ld de, upcomingStones + \1
    ld a, [de]
    TileIndexToAddress
    call SetSprite_8x16x2
    ld b, 9
    ld c, \1
    call SetSpritePos_8x16x2
ENDM

SelectCursor: MACRO
    ldh a, [cursor]
    ldh [selected], a
    call UpdateSelectionPos
ENDM

; \1 = delta X
; \2 = delta Y
; \3 = X warp bound, -1 for undefined
; \4 = Y warp bound, -1 for undefined
_CursorMoveHandler: MACRO
    GetCursorXY
    IF \3 >= 0
        cp \3
        jr nz, .noWarp\@
    ELSE
        ld a, c
        cp \4
        jr nz, .noWarp\@
    ENDC
.warp\@
    StartAnimation                      \
        SPRITE_CURSOR, 2,               \
        ANIM_CURSOR_SPEED * (-\1) * 8,  \
        ANIM_CURSOR_SPEED * (-\2) * 8,  \
        16 / ANIM_CURSOR_SPEED
    IF \3 >= 0
        ld b, (-\1) * 8
    ELSE
        ld b, (-\2) * 8 * BOARD_HEIGHT
    ENDC
    call .moveCursor
    ret
.noWarp\@
    StartAnimation                      \
        SPRITE_CURSOR, 2,               \
        ANIM_CURSOR_SPEED * \1,         \
        ANIM_CURSOR_SPEED * \2,         \
        16 / ANIM_CURSOR_SPEED
    IF \3 >= 0
        ld b, \1
    ELSE
        ld b, \2 * BOARD_HEIGHT
    ENDC
    call .moveCursor
    ret
ENDM

; [out] b = X
; [out] c = Y
; 16 ~ 64 cycles
GetCursorXY: MACRO
    ldh a, [cursor]             ; 3
    Coord1DTo2D a, BOARD_WIDTH  ; 13 ~ 61
ENDM

; [out] a
; 8 cycles
GetCursorStoneVariant: MACRO
    ldh a, [cursor]     ; 2 3
    ld h, HIGH(board)   ; 2 2
    ld l, a             ; 1 1
    ld a, [hl]          ; 1 2
ENDM

_InputHandler_Button: MACRO
    ldh a, [PressedKeys]
    bit \1, a
    call nz, \2
ENDM

_InputHandler_DPad: MACRO
    push bc
    ldh a, [c]
    bit \1, a
    call nz, \2
    pop bc
ENDM

; [in] \1 = delta X
; [in] \2 = delta Y
_MoveAnimation: MACRO
    StartAnimation                  \
        SPRITE_MOVE, 2,             \
        \1 * ANIM_MOVEMENT_SPEED,   \
        \2 * ANIM_MOVEMENT_SPEED,   \
        16 / ANIM_MOVEMENT_SPEED
ENDM

; [in] \1 = identifier (top, right, ...)
; [in] \2 = delta X (-1, 0, 1)
; [in] \3 = delta Y (-1, 0, 1)
; [in] \4 = address change
_MoveAnimation_Direction: MACRO
.dir_\1
    push hl
    _MoveAnimation \2, \3
    pop hl
    ld a, l
    add \4
    ld l, a
    jr .anim_loop
ENDM

_PlaceUpcomingStone: MACRO
    call GetRandomEmptyCell
    write l, r1
    Coord1DTo2D a, BOARD_WIDTH
    ld a, b
    sub 9   ; Not BOARD_WIDTH because upcomings are always at right edge
    ld d, a
    ld a, c
    sub \1
    ld e, a
    StartAnimation SPRITE_NEXT\1, 2, d, e, 16
    REPT ANIM_PLACE_STONE_DELAY
        halt
    ENDR
    ld a, [OAMBuffer + SPRITE_NEXT\1 + 2]
    TileAddressToIndex
    ld b, a
    read l, r1
    call PlaceStone
    call CheckForMatch
    ld l, SPRITE_NEXT\1
    call HideSprite_8x16x2
    ldh a, [remainingSpace]
    or a
    jp z, GameOver
ENDM

; [in] de = coordinate
; [corrupt] a
; 25 cycles
_AddDestroyCandidates: MACRO
    push hl                         ; 4
    ld h, HIGH(destroyCandidates)   ; 2
    ldh a, [destroyCandidatesCount] ; 3
    ld l, a                         ; 1
    inc a                           ; 1
    ldh [destroyCandidatesCount], a ; 3
    Coord2DTo1D_9 d, e              ; 6
    ld [hl], a                      ; 2
    pop hl                          ; 3
ENDM

; [corrupt] a
; 7 cycles
_CancelDestroyCandidates: MACRO
    ldh a, [destroyCandidatesCount]
    sub b
    ldh [destroyCandidatesCount], a
ENDM

; [corrupt] a, l
; 10 cycles
_CompareToTarget: MACRO
    Coord2DTo1D_9 d, e  ; 6
    ld l, a             ; 1
    ld a, [hl]          ; 2
    cp c                ; 1
ENDM

; [in] \1 = register to be decreased
; [in] \2 = upper bound (exclusive)
; [out] \1 += 1
; [out] a = 0
; return if overflowed
_IncreaseWithBoundCheck: MACRO
    inc \1
    ld a, \1
    cp \2
    ld a, 0     ; here we must use `LD` because it doesn't change flags
    ret nc
ENDM

; [in] \1 = register to be decreased
; [out] \1 -= 1
; [out] a = 0
; return if overflowed
_DecreaseWithBoundCheck: MACRO
    ld a, \1
    sub 1
    ld \1, a
    ld a, 0     ; here we must use `LD` because it doesn't change flags
    ret c
ENDM

_CheckDirectionPair: MACRO
    ld a, HIGH(\1)
    ld b, LOW(\1)
    ld hl, \2
    call CheckDirectionPair
ENDM
