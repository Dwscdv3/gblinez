INCLUDE "lib/hardware.inc"
INCLUDE "rand.asm"



SECTION "DwLib80_Input", ROM0

Input:
.getDPadState
    ld c, LOW(rP1)
    ld a, P1F_GET_DPAD
    ldh [c], a
    REPT 6
        ldh a, [c]
    ENDR
    cpl
    and %00001111
    swap a
    ld b, a             ; b = ▼▲◀▶????
.getButtonState
    ld a, P1F_GET_BTN
    ldh [c], a
    REPT 6
        ldh a, [c]
    ENDR
    cpl
    and %00001111
    or b
    ld b, a             ; b = ▼▲◀▶RLBA
.releaseDevice          ; seems unnecessary?
    ld a, P1F_GET_DPAD | P1F_GET_BTN
    ld [c], a
.storeJoypadState
    ldh a, [JoypadState]
    cpl
    and b
    ldh [PressedKeys], a
    ld a, b
    ldh [JoypadState], a
    ret

Exception:
    ld b, b
    ret



SECTION "DwLib80_Input_Variables", HRAM

JoypadState:    db
PressedKeys:    db
