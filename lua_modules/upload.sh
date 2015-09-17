#!/bin/bash

(($#))||set wipe bmp180 i2d am2321 met keys wifi_init rgbLED metspeak init
while (($#)); do
  PORT=`ls /dev/ttyUSB? /dev/rfcomm? 2>/dev/null`
  opt=$1
  trap "exit" SIGHUP SIGINT SIGTERM
  case $opt in
#  list)
#   luatool.py -p $PORT -l;;
  wipe)
    luatool.py -p $PORT -rw;;
  bmp180|dht22|am2321)
    luatool.py -p $PORT -rcf $opt.lua;;
  keys|keys.*|my_conf|my_conf.*)
    luatool.py -p $PORT -cf my_conf.lua -t keys.lua;;
  metspeak|metspeak.*|test.lua)
    luatool.py -p $PORT -rf ${opt%.*}.lua -t app.lua;;
  wifi_init|met|rgbLED|pms3003)
    luatool.py -p $PORT -cf $opt.lua;;
  init|init.lua)
    luatool.py -p $PORT -rf ${opt%.*}.lua;;
  *_v*.lua)
    luatool.py -p $PORT -df $opt -t test.lua;;
  *)
    luatool.py -p $PORT -f ${opt%.*}.lua;;
  esac && shift
  trap - SIGHUP SIGINT SIGTERM
done

