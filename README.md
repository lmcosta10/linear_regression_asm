Linear regression fitting in x86 assembly, using nasm.

<h1> Building </h1>

1) nasm -f elf -o linear_regression.o linear_regression.s

2) ld -m elf_i386 -o linear_regression linear_regression.o