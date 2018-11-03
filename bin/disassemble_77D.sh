#!/bin/bash

ROMS="/vagrant/ROMs"
BIN="/vagrant/bin"

echo Disassembling ROM0 in "$ROMS"

cd "$ROMS"

perl "$BIN/disassemblev7.pl" 0xE0000000 ROM0.BIN

echo Done with disassembling
