#!/bin/sh
# Waybar custom module: aggregate physical-disk I/O rate.
#
# /proc/diskstats field 6 = sectors read, field 10 = sectors written; a
# sector is 512 B. Match whole disks only (nvme0n1, sda, vda, mmcblk0)
# so partitions and dm-* don't double-count the same I/O.

INTERVAL=2

snapshot() {
    awk '$3 ~ /^(nvme[0-9]+n[0-9]+|sd[a-z]|vd[a-z]|mmcblk[0-9]+)$/ \
         {r+=$6; w+=$10} END {print r+0, w+0}' /proc/diskstats
}

set -- $(snapshot); r1=$1; w1=$2
sleep "$INTERVAL"
set -- $(snapshot); r2=$1; w2=$2

r=$(( (r2 - r1) * 512 / 1024 / INTERVAL ))
w=$(( (w2 - w1) * 512 / 1024 / INTERVAL ))

fmt() {
    if [ "$1" -ge 1024 ]; then
        printf '%d.%d M' $(( $1 / 1024 )) $(( ($1 % 1024) * 10 / 1024 ))
    else
        printf '%d K' "$1"
    fi
}

printf '↓ %s  ↑ %s\n' "$(fmt "$r")" "$(fmt "$w")"
