#!/bin/bash

(($#))||set wipe bmp180 keys wifi_init dht22 am2321 met application init
PORT=`ls /dev/ttyUSB? /dev/rfcomm? 2>/dev/null`
while (($#)); do
  opt=$1
  case $opt in
  wipe|list)
    luatool.py -p $PORT --$opt;;
  bmp180|dht22|am2321)
    luatool.py -p $PORT -c -r -f $opt.lua;;
  keys|my_conf)
    luatool.py -p $PORT -c    -f my_conf.lua -t keys.lua;;
  wifi_init|met|application)
    luatool.py -p $PORT -c    -f $opt.lua;;
  init)
    luatool.py -p $PORT    -r -f $opt.lua --list;;
  *.lua)
    luatool.py -p $PORT -c    -f $opt;;
  *)
    luatool.py -p $PORT -c    -f $opt.lua;;
  esac && shift
done

