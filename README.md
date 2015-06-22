# AQmon
DIY Air Quality Monitor

###  Controler
- ESP8266: [nodemcu-devkit][] with [nodemcu-firmware][] (custom built).
- Send met data to [thingspeak][].

[nodemcu-devkit]:   https://github.com/nodemcu/nodemcu-devkit
[nodemcu-firmware]: https://github.com/nodemcu/nodemcu-firmware
[thingspeak]:       https://thingspeak.com/channels/37527

### Sensors
- BMP085: pressure and temperature
- DHT22: relative humidity and temperature
- [AM2321][]: relative humidity and temperature
- [PMS3003][]: PM1, PM2.5 and PM10

[AM2321]:  http://www.aliexpress.com/snapshot/6399232524.html?orderId=65033515010843
[PMS3003]: http://www.aliexpress.com/snapshot/6624872562.html?orderId=66919764160843

### ToDo
- hardware
  - remove DHT22
  - finish shield
  - add [PMS3003][] sensor to shield
- lua_modules
  - sleep between measurements
  - extend `wifi_init.lua` to `wifi.SOFTAP` and `wifi.STATIONAP`
  - browser side makrdown with [strapdown.js][]
  - index.md: index page
    - Meteogram using [highcharts][]
    - [yr.no][] and [aqicn.org][] widgets
  - config.md: config page
    - save params to `keys.lua`
    - wifi.SOFTAP only
  - replace `upkeep.lua` (compile) ny [luatool.py][] (upload & compile):
    - modify `luatool.py` to handle multy line comments
    - upload (& compile) modules with `make module.lc`.
  - new modules
    - [AM2321][]  (i2c)
    - [PMS3003][] (uart)
- nodemcu-firmware
  - i2c.bmpXXX module for BMP085/BMP180 sensors
  - i2c.am2321 module for [AM2321][] sensor
  - pms3003    module for [PMS3003][] sensor

[strapdown.js]: http://strapdownjs.com
[luatool.py]: https://github.com/4refr0nt/luatool
[highcharts]: http://www.highcharts.com
[yr.no]:      http://www.yr.no/place/Norway/Oslo/Oslo/Marienlyst_skole/
[aqicn.org]:  http://aqicn.org/city/norway/norway/oslo/kirkeveien/
