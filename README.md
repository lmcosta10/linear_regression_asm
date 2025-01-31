Linear regression fitting in x86 assembly, using least squares, in x86 nasm.

<h1> Model </h1>

The model is a Simple Linear Regression:

$ \^{Y} = b_0 + b_1 X $

<h1> Building </h1>

1) nasm -f elf -o linear_regression.o linear_regression.s

2) ld -m elf_i386 -o linear_regression linear_regression.o