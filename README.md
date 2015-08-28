# AQmon
DIY Air Quality Monitor

### Controler

- ESP8266: [nodemcu-devkit][] with [nodemcu-firmware][] ([0.9.6 20150627][]).
- Send met data to [ThingSpeak][].

[nodemcu-devkit]:   https://github.com/nodemcu/nodemcu-devkit
[nodemcu-firmware]: https://github.com/nodemcu/nodemcu-firmware
[0.9.6 20150704]:   https://github.com/nodemcu/nodemcu-firmware/releases/tag/0.9.6-dev_20150704
[0.9.6 20150627]:   https://github.com/nodemcu/nodemcu-firmware/releases/tag/0.9.6-dev_20150627
[thingspeak]:       https://thingspeak.com

### Sensors

- BMP085/[BMP180][]: pressure and temperature
- [AM2320][]/[AM2321][]: relative humidity and temperature
- [BME280][]: pressure, relative humidity and temperature
- [PMS3003][]: PM1, PM2.5 and PM10

[BMP180]:  http://www.aliexpress.com/snapshot/6747685613.html?orderId=67922658930843
[BME280]:  http://www.aliexpress.com/snapshot/6857975909.html?orderId=68901285360843
[AM2320]:  http://www.aliexpress.com/snapshot/6399232524.html?orderId=65033515010843
[AM2321]:  http://www.aliexpress.com/snapshot/6863602671.html?orderId=68897377730843
[PMS3003]: http://www.aliexpress.com/snapshot/6624872562.html?orderId=66919764160843

### Plugins

- [Meteogram][]: use [Highcharts][] to display met data from [channel][].

[meteogram]: http://thingspeak.com/plugins/15643
[highcharts]:http://www.highcharts.com
[channel]:   http://thingspeak.com/channels/37527

### ToDo
- hardware
  - connect PMS3003 sensor to dev board
- lua_modules
  - BME280 sensor.
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
    - PMS3003 (uart)
- plugins
  - live update for the last hour datapoint
  - PM data pluggin
- nodemcu-firmware (maybe not needed)
  - i2c.bmpXXX module for BMP085/BMP180 sensors
  - i2c.am2321 module for AM2320/AM2321 sensors
  - pms3003    module for PMS3003 sensor
  - try [nodemcu-custom-build][]

[strapdown.js]: http://strapdownjs.com
[luatool.py]: https://github.com/4refr0nt/luatool
[nodemcu-custom-build]: http://frightanic.com/nodemcu-custom-build
