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
  wifi_init|rgbLED|pms3003)
    luatool.py -p $PORT -cf $opt.lua;;
  keys|keys.*|my_conf|my_conf.*)
    luatool.py -p $PORT -cf my_conf.lua -t keys.lua;;
  app|app.*|AQmon|AQmon.*)
    luatool.py -p $PORT -rf ${opt%.*}.lua -t app.lua;;
  hub|hub.*|sensor_hub|sensor_hub.*)
    luatool.py -p $PORT -rf ${opt%.*}.lua -t sensors.lua;;
  init|init.lua)
    luatool.py -p $PORT -rf ${opt%.*}.lua;;
  *_v*.lua)  # alternative versions
    luatool.py -p $PORT -df $opt -t ${opt/_v*/.lua};;
  *)
    luatool.py -p $PORT -f ${opt%.*}.lua;;
  esac && shift
  trap - SIGHUP SIGINT SIGTERM
done
