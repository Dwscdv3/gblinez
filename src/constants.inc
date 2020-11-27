SECTION "Constants", ROM0

; Build settings
EASTER_EGG          EQU 0

; Environment settings
STACK_BASE          EQU $CFFF
STACK_SIZE          EQU $100

; Animation speed
ANIM_CURSOR_SPEED       EQU 3
ANIM_MOVEMENT_SPEED     EQU 4
ANIM_PLACE_STONE_DELAY  EQU 4

; Fixed value, not supposed to change
OAM_STRUCT_SIZE     EQU 4
BOARD_WIDTH         EQU 9
BOARD_HEIGHT        EQU 9
BOARD_SIZE          EQU BOARD_WIDTH * BOARD_HEIGHT
SCORE_DIGIT_COUNT   EQU 5
TILE_CURSOR         EQU 32
TILE_SELECTION      EQU 36
TILE_DIGIT_0        EQU 40
TILE_EMPTY          EQU 50
TILE_BORDER         EQU 51
TILE_SYMBOL_0       EQU 52

; Sprite address definitions
; Double-sized tile (x2)
                    RSRESET
SPRITE_CURSOR       rb 8
SPRITE_SELECTION    rb 8
SPRITE_NEXT0        rb 8
SPRITE_NEXT1        rb 8
SPRITE_NEXT2        rb 8
SPRITE_MOVE         rb 8
