#!/bin/bash

: ${PORT:=`ls /dev/ttyUSB? /dev/rfcomm? 2>/dev/null`}
: ${VERSION:=0.9.6-dev_20150704}
: ${CHANNEL:=37527}

(($#))||set wipe bmp180 am2321 bme280 pms3003 sensor_hub \
            keys_v$CHANNEL wifi_connect rgbLED sendData AQmon init

while (($#)); do
  opt=$1
  trap "exit" SIGHUP SIGINT SIGTERM
  case $opt in
  nodemcu_float|nodemcu_integer)
    esptool.py --port $PORT --baud 115200 write_flash 0x00000 \
      ../nodemcu-firmware/bin/$opt\_$VERSION.bin ;;
# list) luatool.py -p $PORT -l;;
  wipe)
    luatool.py -p $PORT -rw;;
  bmp180|am2321|bme280|pms3003)        # sensor modules
    luatool.py -p $PORT -cf $opt.lua;;
  hub|hub.*|*_hub|*_hub.*)      # sensor hub module
    luatool.py -p $PORT -rcf ${opt%.*}.lua -t sensors.lua;;
  keys|wifi_connect|sendData|rgbLED|hueLED)
    luatool.py -p $PORT -cf $opt.lua;;
  app|app.*|AQmon|AQmon.*)
    luatool.py -p $PORT -rcf ${opt%.*}.lua -t app.lua;;
  init|init.lua)
    luatool.py -p $PORT -rf ${opt%.*}.lua;;
  *_v*|*_v*.lua)  # alternative versions, eg keys_v37527
    luatool.py -p $PORT -cf ${opt%.*}.lua -t ${opt/_v*/.lua};;
  *_test.lua)# test scripts
    luatool.py -p $PORT -df $opt -t test.lua;;
  *.lua)     # other scipts
    luatool.py -p $PORT -f $opt;;
  esac && shift
  trap - SIGHUP SIGINT SIGTERM
done
