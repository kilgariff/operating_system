#!/bin/bash

nasm -f bin -i./src/ ./src/kernel.asm -o ./bin/out.bin && dd conv=notrunc if=./bin/out.bin of=c.img
echo "Finished building"
