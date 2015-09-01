#!/bin/bash

(($#))||set wipe bmp180 i2d am2321 met keys wifi_init metspeack init
while (($#)); do
  PORT=`ls /dev/ttyUSB? /dev/rfcomm? 2>/dev/null`
  opt=$1
  trap "exit" SIGHUP SIGINT SIGTERM
  case $opt in
  wipe)
    luatool.py -p $PORT -rwl;;
  bmp180|dht22|am2321)
    luatool.py -p $PORT -rcf $opt.lua;;
  keys|keys.*|my_conf|my_conf.*)
    luatool.py -p $PORT -cf my_conf.lua -t keys.lua;;
  metspeack|metspeack.*)
    luatool.py -p $PORT -rcf metspeack.lua -t app.lua;;
  wifi_init|met)
    luatool.py -p $PORT -cf $opt.lua;;
  init|init.lua)
    luatool.py -p $PORT -rf ${opt%.*}.lua;;
  *)
    luatool.py -p $PORT -cf ${opt%.*}.lua;;
  esac && shift
  trap - SIGHUP SIGINT SIGTERM
done

