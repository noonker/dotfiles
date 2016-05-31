#!/bin/bash
E=329.63
Gs=415.30
Fs=369.99
B=246.94
for X in $E $Gs $Fs $B $E $Fs $Gs $E $Gs $E $Fs $B $B $Fs $Gs $E
do
speaker-test -c1 -f$X -t sine -l1 -b5 > /dev/null
done
