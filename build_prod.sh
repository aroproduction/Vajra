#!/usr/bin/env bash
cd /mnt/d/Works/secret/chess-engine/Vajra2

v -enable-globals -os windows \
  -cc x86_64-w64-mingw32-gcc \
  -cflags "-O3 -march=native -mtune=native -flto -mbmi2 -mpopcnt -mlzcnt -mavx2 -mfma -fomit-frame-pointer -fno-semantic-interposition -funroll-loops" \
  -ldflags "-flto -s" \
  -prod ./src -o ./bin/vajra2_prod_best
