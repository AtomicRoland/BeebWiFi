#!/bin/bash

beebasm -i BeebWifi.asm -v >> beebwifi-output.lst

cp bbcwifi.rom ~/Downloads/BeebWifi.bin

echo Creating production files
ver=`grep ".romversion" BeebWifi.asm | cut -d'"' -f 2`
crc=`../crc/crc16 bbcwifi.rom`

echo VER=$ver > beebwifi-version.txt
echo CRC=$crc >> beebwifi-version.txt
cp bbcwifi.rom beebwifi-latest.bin


