#!/usr/bin/env bash
set -euo pipefail

for reg in 0x40 0x41 0x42 0x43; do
    v=$(i2cget -y 1 0x50 "$reg")
    printf '%b' "\\x${v#0x}"
done
