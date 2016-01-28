@echo off
ca65 dabg.s -o dabg.o -l dabg.lst
ld65 -C nrom256.x dabg.o -o dabg.nes
pause