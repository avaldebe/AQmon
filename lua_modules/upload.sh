#!/bin/bash

: ${PORT:=`ls /dev/ttyUSB? /dev/rfcomm? 2>/dev/null`}
: ${VERSION:=0.9.6-dev_20150704}
: ${CHANNEL:=37527}

(($#))||set wipe bmp180 am2321 bme280 pms3003 sensor_hub \
            keys_v$CHANNEL wifi_connect rgbLED sendData AQmon init

TRANSPORT="-p $PORT"; [[ -n $IP ]] && TRANSPORT="--ip $IP:2323"
while (($#)); do
  opt=$1
  trap "exit" SIGHUP SIGINT SIGTERM
  case $opt in
  AT-095)
    esptool.py --port $PORT --baud 115200 write_flash \
      0x00000 ../nodemcu-firmware/bin/095/AI-v0.9.5.0\ AT\ Firmware.bin ;;
  nodemcu_float|nodemcu_integer)
    esptool.py --port $PORT --baud 115200 write_flash \
      0x00000 ../nodemcu-firmware/bin/096/$opt\_$VERSION.bin ;;
  nodemcu_custom) # 1.4.0
    esptool.py --port $PORT --baud 115200 write_flash \
      0x00000 ../nodemcu-firmware/bin/0x00000.bin \
      0x10000 ../nodemcu-firmware/bin/0x10000.bin ;;
  nodemcu_blank)
    esptool.py --port $PORT --baud 115200 write_flash \
      0x7C000 ../nodemcu-firmware/bin/esp_init_data_default.bin \
      0x7E000 ../nodemcu-firmware/bin/blank.bin ;;
# list) luatool.py -p $PORT -l;;
  wipe)
    luatool.py $TRANSPORT -rw;;
  bmp180|am2321|bme280|pms3003) # sensor modules
    luatool.py $TRANSPORT -cf $opt.lua;;
  hub|hub.*|*_hub|*_hub.*)      # sensor hub module
    luatool.py $TRANSPORT -rcf ${opt%.*}.lua -t sensors.lua;;
  keys|wifi_connect|sendData|rgbLED|hueLED)
    luatool.py $TRANSPORT -cf $opt.lua;;
  AQmon|AQmon.*|*_app|*_app.*)
    luatool.py $TRANSPORT -rcf ${opt%.*}.lua -t app.lua;;
  init|init.lua)
    luatool.py $TRANSPORT -rf ${opt%.*}.lua;;
  *_v*|*_v*.lua)  # alternative versions, eg keys_v37527
    luatool.py $TRANSPORT -cf ${opt%.*}.lua -t ${opt/_v*/.lua};;
  *_test.lua)# test scripts
    luatool.py $TRANSPORT -df $opt -t test.lua;;
  *.lua)     # other scipts
    luatool.py $TRANSPORT -f $opt;;
  esac && shift
  trap - SIGHUP SIGINT SIGTERM
done
