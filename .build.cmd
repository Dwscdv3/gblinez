@echo off
rgbasm --export-all --halt-without-nop --include src --include src/dwlib80 --output obj/main.o src/main.asm
rgblink -d -m bin/gblinez.map -n bin/gblinez.sym -o bin/gblinez.gb obj/main.o
rgbfix -v -p 0 -j -k DW -t gblinez bin/gblinez.gb
