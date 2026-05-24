#!/bin/bash

nasm -f elf -o linear_regression.o linear_regression.asm
ld -m elf_i386 -o ./linear_regression linear_regression.o
./linear_regression 