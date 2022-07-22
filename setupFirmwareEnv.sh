#!/bin/bash

source "${PLAYBOOKS}/scripts/common.env"

# ARCH_SDCARD_BOOT=/dev/sda1
ARCH_SDCARD_ROOT=/dev/sda2

if ARCH_ROOT="$(blkid | grep $ARCH_SDCARD_ROOT | cut -d ' ' -f 8)"; then
    echo "ARCH_ROOT=${ARCH_ROOT}"
else
    abort
fi


latestConf="$(ls -lhtrB ${RPI_CONFS} tail -n 1 | cut -d ' ' -f 9)"

sed -i"_$(date -Ins)~ "s/root=PARTUUID=*/root=PARTUUID=\"${ARCH_ROOT}\"/g "${RTSP_SRC_DIR}/${latestConf}"

sed -i -e "s/BOOT_UART=0/BOOT_UART=1/" bootcode.bin