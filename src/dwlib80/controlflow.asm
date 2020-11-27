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



IF !DEF(src_control_flow)
src_control_flow = 1



SECTION "DwLib80_ControlFlow", ROM0

; [in] \1 = identifier
; [in] \2 = counter register
BeginLoop: MACRO
    inc \2
    jr .loop_\1_step
.loop_\1_body
ENDM

; [in] \1 = identifier
; [in] \2 = counter register
EndLoop: MACRO
.loop_\1_step
    dec \2
    jr nz, .loop_\1_body
ENDM



ENDC
