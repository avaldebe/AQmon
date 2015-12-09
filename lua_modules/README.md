# lua_modules
Lua modules for [AQmon][] project.<br/>

[AQmon]:      https://github.com/avaldebe/AQmon
[thingspeak]: https://thingspeak.com
[luatool.py]: https://github.com/4refr0nt/luatool

### Project specific modules
- `AQmon.lua`: Read sensors and publish to [thingspeak][].
- `keys.lua`: Contains the known APs SSID/PASS pairs,
              [thingspeak][] keys and pin assignment (LED,SDA/SCL,&c).

### Sensor modules
- `bmp180.lua`: BMP085 / BMP180 sensors.
- `am2321.lua`: AM2320 / AM2321 sensors.
- `bme280.lua`: BME280 sensor, can replace BMPxxx and AM232x sensors.
- `pms3003.lua`: PMS3003 sensor.
- `sensor_hub.lua`: Read all sensors above.

### I-Net modules
- `wifi_connect.lua`: Connect to a known AP, as defined in keys.lua.
- `sendData.lua`: Publish data to [thingspeak][] or other API, as defined in keys.lua

### General purpose modules
- `init.lua`: Exit infinite reboot caused by a PANIC error.
              Calls `require('app')` after 2 seconds from boot.
              Before that, the call can be aborted by pressing KEY_FLASH,
              which drives pin3 (gpio0) low.
- `rgbLED.lua`: Returns a status function for a RGB LED.
- `hueLED.lua`: Returns a function that control a RGB LED with Hue,
                at full Saturation and Brightness (HSV).
- `i2c-autoscan.lua`: scan gpio pins and address and report devices found.

#### Upload from command line with [luatool.py][]

```sh
# find the port
PORT=`ls /dev/ttyUSB? /dev/rfcomm? 2>/dev/null`
# remove all *.lua and *.lc files and restart
luatool.py -p $PORT -w -r
# upload, compile and restart
luatool.py -p $PORT -rc -f bme280.lua
luatool.py -p $PORT -rc -f bmp180.lua
luatool.py -p $PORT -rc -f am2321.lua
luatool.py -p $PORT -rc -f pms3003.lua
luatool.py -p $PORT -rc -f keys.lua
luatool.py -p $PORT -rc -f wifi_connect.lua
luatool.py -p $PORT -rc -f sendData.lua
luatool.py -p $PORT -rc -f rgbLED.lua
# upload, rename, compile and restart
luatool.py -p $PORT -rc -f sensor_hub.lua -t sensors.lua
luatool.py -p $PORT -rc -f AQmon.lua      -t app.lua
# upload and restart
luatool.py -p $PORT -r -f init.lua
```

### Ussage examples
Information for each sensor module can be found at [SENSORS.md][]

[SENSORS.md]: ./SENSORS.md

#### Sensor Hub
```lua
-- module setup and read: no PMS3003
sda,scl,pinSET=3,4,nil -- GPIO0,GPIO2
require('sensors').init(sda,scl,pinSET)
sensors.verbose=true -- verbose mode
sensors.read()

-- module setup and read: all sensors
sda,scl,pinSET=5,6,7
require('sensors').init(sda,scl,pinSET)
sensors.read(function()
  print(sensors.format({heap=node.heap(),time=tmr.time()},
    'sensors:{time}[s],{t}[C],{h}[%],{p}[hPa],{pm01},{pm25},{pm10}[ug/m3],{heap}[b]'))
end)

-- release memory
sensors,package.loaded.sensors = nil,nil
```

### References
After many round of write/rewrite code it becomes hard to keep track of
sources for code and ideas. Please let me know, if I have missed you.

My biggest thanks to the following authors:

- [bigdanz][]: `init.lua` is based on ideas form his article abut [interrupting][] `init.lua`.
- @javieryanez: I used his nodemcu modules for the [BMP180 and DTH22][] sensors before I wrote my own module.
  My `bmp180.lua` module is based on his.
- @saper-2: I used his nodemcu modules for the [AM2321][] sensor before I wrote my own module.
  My `am2321.lua` module is based on his.
- [captain-slow][]: His short article on [posting to thingspeak][] helped me to get my data out.
- @geekscape: his [skeleton][]/`setup.lua` is almost esactly the same as my first version of `wifi.init`.
  From him I took the idea of using a generic module name (`appliation.lua`) for the appliation specific code.
- @hwiguna: his [esp8266 videos][] are an inspiration go out and play (or code).
- For my `bme280.lua` module I took bit and pieces from many sources:
  - [bme280.lua][] by @wogum
  - [BME280_driver][] by @BoschSensortec
  - [bme280.py][] by @kbrownlees
  - [Adafruit_BME280.py][] by @adafruit
  - [SparkFunBME280.cpp][] by @sparkfun

[bigdanz]:      https://bigdanzblog.wordpress.com
[interrupting]: https://bigdanzblog.wordpress.com/2015/04/24/esp8266-nodemcu-interrupting-init-lua-during-boot
[BMP180 and DTH22]: https://github.com/javieryanez/nodemcu-modules
[skeleton]:        https://github.com/geekscape/nodemcu_esp8266/tree/master/skeleton
[esp8266 videos]:  https://www.youtube.com/user/hwiguna
[captain-slow]:    http://captain-slow.dk
[posting to thingspeak]: http://captain-slow.dk/2015/04/16/posting-to-thingspeak-with-esp8266-and-nodemcu
[AM2321]:         https://github.com/saper-2/esp8266-am2321-remote-sensor
[bme280.lua]:     https://github.com/wogum/esp12
[BME280_driver]:  https://github.com/BoschSensortec/BME280_driver
[bme280.py]:      https://github.com/kbrownlees/bme280
[Adafruit_BME280.py]: https://github.com/adafruit/Adafruit_Python_BME280
[SparkFunBME280.cpp]: https://github.com/sparkfun/SparkFun_BME280_Arduino_Library
