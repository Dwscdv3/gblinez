SECTION "Tileset", ROM0

; 1024 B
Tileset:
INCBIN "res/tileset.bin"
.end



SECTION "ScoreTable", ROM0, ALIGN[8]

; 37 B
ScoreTable:
db 0, 0, 0, 0, 0, 10, 12, 18, 28, 42, 60, 82, 108, 138
ds 23, 156  ; 157 is the maximum safe number
            ; to not overflow the current score implementation
            ; Here uses 156 to avoid an odd number score
.end
