SECTION "SystemVariables", HRAM

VBlankFlag:     db
FrameCount:     db



SECTION "Variables", HRAM

VBlankHandlerEnabled:   db

; For fast computation of lower 2 decimals
scoreLow:               db

; Little-endian
scoreDigits:            ds SCORE_DIGIT_COUNT

cursor:                 db

; $FF = deselect,
; $51 ~ $FE = undefined behavior
selected:               db

remainingSpace:         db

destroyCandidatesCount: db



SECTION "Stack", WRAM0[STACK_BASE - STACK_SIZE + 1]

Stack:          ds STACK_SIZE



SECTION "Gameboard", WRAM0, ALIGN[8]

board:              ds 81
upcomingStones:     ds 3



IF DEF(EASTER_EGG)

SECTION "EasterEggState", WRAM0, ALIGN[8]

; bit 0 = variant 1
; bit 1 = variant 2
; ...
; When stones are destroyed, set the corresponding bit.
easterEgg_codebook: ds 7

ENDC



SECTION "PathFindingBuffer", WRAM0, ALIGN[8]

visited:        ds 81



SECTION "DestroyCandidatesBuffer", WRAM0, ALIGN[8]

destroyCandidates:  ds 8 * 4 + 1
