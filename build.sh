#!/bin/bash

pushd src
nasm kernel.asm -o ../bin/out.bin
popd

dd conv=notrunc  if=./bin/out.bin of=c.img

echo "Finished building"
