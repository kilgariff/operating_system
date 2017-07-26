#!/bin/bash

nasm -i./src/ ./src/kernel.asm -o ./bin/out.bin && dd conv=notrunc ibs=1k count=5 if=./bin/out.bin of=c.img
echo "Finished building"
