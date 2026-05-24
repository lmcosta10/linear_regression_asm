Linear regression fitting in x86 assembly, using least squares, in x86 nasm.

# Model

The model is a Simple Linear Regression:

$ \hat{Y} = b_1 X $

# Building and Running (Linux)

You can just run `./run.sh` (after making it executable with `chmod +x ./run.sh`) or follow the steps below.

## Building

Make sure to have nasm installed.

```
nasm -f elf -o linear_regression.o linear_regression.asm
ld -m elf_i386 -o ./linear_regression linear_regression.o
```

## Running

```
./linear_regression 
```