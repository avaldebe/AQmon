# AQmon
DIY Air Quality Monitor

### Controler

- ESP8266: [nodemcu-devkit][] with [nodemcu-firmware][] (custom built).
- Send met data to [ThingSpeak][].

[nodemcu-devkit]:   https://github.com/nodemcu/nodemcu-devkit
[nodemcu-firmware]: https://github.com/nodemcu/nodemcu-firmware
[thingspeak]:       https://thingspeak.com

### Sensors

- BMP085/[BMP180][]: pressure and temperature
- [AM2321][]: relative humidity and temperature
- [PMS3003][]: PM1, PM2.5 and PM10

[BMP180]: http://www.aliexpress.com/snapshot/6747685613.html?orderId=67922658930843
[AM2321]:  http://www.aliexpress.com/snapshot/6399232524.html?orderId=65033515010843
[PMS3003]: http://www.aliexpress.com/snapshot/6624872562.html?orderId=66919764160843

### Plugins

- [Meteogram][]: use [Highcharts][] to display met data from [channel][].

[meteogram]: http://thingspeak.com/plugins/15643
[highcharts]:http://www.highcharts.com
[channel]:   http://thingspeak.com/channels/37527

### ToDo
- hardware
  - prototype shield
  - test with BMP180 and  AM2320 sensors (newer and cheaper).
  - add PMS3003 sensor to shield
- lua_modules
  - read sensor ids and write it as metadata.
  - sleep between measurements
    - note: dsleep is incompatible with user blink of ledD0
  - browser side makrdown with [strapdown.js][]
  - index.md: index page with thingspeak plugins and external widgets
  - config.md: config page
    - save params to `keys.lua`
    - wifi.SOFTAP only(?)
  - decode forecast & obervations from [yr.no][] using [highcharts][] pharser:<br/>
      GET http://www.highcharts.com/samples/data/jsonp.php?url=http://www.yr.no/place/Norway/Oslo/Oslo/Marienlyst_skole/forecast.xml&callback=cjson.decode<br/>
      ... loadstrng(payload)
  - new modules
    - AM2321  (i2c, done)
    - PMS3003 (uart)
- plugins
  - live update for the last hour datapoint
- nodemcu-firmware(?)
  - i2c.bmpXXX module for BMP085/BMP180 sensors
  - i2c.am2321 module for AM2320/AM2321 sensors
  - pms3003    module for PMS3003 sensor
  - try [nodemcu-custom-build][]

[strapdown.js]: http://strapdownjs.com
[luatool.py]: https://github.com/4refr0nt/luatool
[nodemcu-custom-build]: http://frightanic.com/nodemcu-custom-build
