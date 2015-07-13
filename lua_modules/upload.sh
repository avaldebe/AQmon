#!/bin/bash

(($#))||set wipe bmp180 i2d am2321 met keys wifi_init application init
while (($#)); do
  PORT=`ls /dev/ttyUSB? /dev/rfcomm? 2>/dev/null`
  opt=$1
  case $opt in
  wipe)
    luatool.py -p $PORT    -r  --$opt --list;;
  bmp180|dht22|am2321)
    luatool.py -p $PORT -c -r -f $opt.lua;;
  keys|my_conf)
    luatool.py -p $PORT -c    -f my_conf.lua -t keys.lua;;
  wifi_init|met|application)
    luatool.py -p $PORT -c    -f $opt.lua;;
  init)
    luatool.py -p $PORT    -r -f $opt.lua;;
  *.lua)
    luatool.py -p $PORT -c    -f $opt;;
  *)
    luatool.py -p $PORT -c    -f $opt.lua;;
  esac && shift
done

