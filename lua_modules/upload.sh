#!/bin/bash

(($#))||set wipe bmp180 am2321 i2d pms3003 hub \
            keys wifi_init rgbLED app init
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
  wifi_init|pms3003|rgbLED) #|hueLED)
    luatool.py -p $PORT -cf $opt.lua;;
  keys|keys.*|my_conf|my_conf.*)
    luatool.py -p $PORT -cf my_conf.lua -t keys.lua;;
  app|app.*|AQmon|AQmon.*)
    luatool.py -p $PORT -rf ${opt%.*}.lua -t app.lua;;
  hub|hub.*|*_hub|*_hub.*)
    luatool.py -p $PORT -rf ${opt%.*}.lua -t sensors.lua;;
  init|init.lua)
    luatool.py -p $PORT -rf ${opt%.*}.lua;;
  *_v*.lua)  # alternative versions
    luatool.py -p $PORT -df $opt -t ${opt/_v*/.lua};;
  *_test.lua)# test scripts
    luatool.py -p $PORT -df $opt -t test.lua;;
  *.lua)     # other scipts
    luatool.py -p $PORT -f $opt;;
  esac && shift
  trap - SIGHUP SIGINT SIGTERM
done
