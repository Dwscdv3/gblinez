SECTION "RST00", ROM0[$00]
    ret

SECTION "RST08", ROM0[$08]

SECTION "RST10", ROM0[$10]

SECTION "RST18", ROM0[$18]

SECTION "RST20", ROM0[$20]

SECTION "RST28", ROM0[$28]

SECTION "RST30", ROM0[$30]

SECTION "RST38", ROM0[$38]



SECTION "Interrupt_VBlank", ROM0[$40]
    jp VBlankInterrupt

SECTION "Interrupt_LCDStat", ROM0[$48]
    reti

SECTION "Interrupt_Timer", ROM0[$50]
    reti

SECTION "Interrupt_Serial", ROM0[$58]
    reti

SECTION "Interrupt_Joypad", ROM0[$60]
    jp JoypadInterrupt



SECTION "Entry", ROM0[$100]
    jp Entry



SECTION "Header", ROM0[$104]
    ds $4C
