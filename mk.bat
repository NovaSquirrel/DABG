@echo off
ca65 dabg.s -o dabg.o -l
ld65 -C nrom256.x dabg.o -o dabg.nes
pause