#!/bin/bash

bs_array=(32 64 128)

for bs in ${bs_array[@]}
do
  make -B BS=$bs
done

## Realizar copia de último tipo de dato compilado
cp Makefile last_makefile
cp include/defs.h last_defs.h