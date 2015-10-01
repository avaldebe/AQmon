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
- [BME280][]: pressure, relative humidity and temperature (alternative)
- [PMS3003][]: PM1, PM2.5 and PM10
- [MAX17043][]: LiPo fuel gauge (optional)
- Other ICs/sensors/modules not relevant for this aplication, but nonetheless interesting:
  - [Arduino pro mini][] ([ATMEGA328P][], 8bit AVR, 3.3V 8MHz):
      8-channel 10-bit ADC, 6-channel 8-bit PWM, and programable sensor hub
  - [Maple mini][] ([STM32F103CB][], 32-bit ARM Cortex M3, 3.3V 72MHz):
      9-channel 12-bit ADC, 12-channel 16-bit PWM, and programable sensor hub
  - [CD4051][]:   8-channel analog multiplexer/demultiplexer, to extend the esp8266 ADC
  - [INA219][]:  voltage, current and power
  - PCF8591:      4-channel  8-bit ADC and 1-channel 8-bit DAC, 4 addresses
  - [ADS1115][]:  4-channel 16-bit ADC,  4 addresses
  - [MCP4725][]:  1-channel 12-bit DAC,  2 addresses
  - [PCA9685][]: 16-channel 12-bit PWM, 62 addresses

[BMP180]:  http://www.aliexpress.com/snapshot/6747685613.html?orderId=67922658930843
[BME280]:  http://www.aliexpress.com/snapshot/6857975909.html?orderId=68901285360843
[AM2320]:  http://www.aliexpress.com/snapshot/6399232524.html?orderId=65033515010843
[AM2321]:  http://www.aliexpress.com/snapshot/6863602671.html?orderId=68897377730843
[PMS3003]: http://www.aliexpress.com/snapshot/6624872562.html?orderId=66919764160843
[MAX17043]:http://www.aliexpress.com/snapshot/6857975910.html?orderId=68901285370843

[Arduino pro mini]: http://www.aliexpress.com/snapshot/6857975906.html?orderId=68901285330843
[ATMEGA328P]: http://www.atmel.com/devices/atmega328p.aspx
[Maple mini]: http://www.aliexpress.com/item/leaflabs-Leaf-maple-mini-ARM-STM32-compatibility/32229442295.html
[STM32F103CB]: http://www.st.com/internet/mcu/product/189782.jsp
[CD4051]:  http://www.taydaelectronics.com/cd4051-4051-ic-cmos-multiplex-demultiplexer.html
[INA219]:  http://www.aliexpress.com/snapshot/6817337392.html?orderId=68495646070843
[ADS1115]: http://www.aliexpress.com/snapshot/6659529844.html?orderId=67204657930843
[MCP4725]: http://www.aliexpress.com/snapshot/6817337390.html?orderId=68495646090843
[PCA9685]: http://www.aliexpress.com/snapshot/6763611745.html?orderId=68109608820843


### Development HW
- Status RGB LED
- [OLED][]: I2C 128X64 display driven by an SSD1306
- [Base Shield][]:  base board for wide nodemcu modules (devkit-0.9).
  Incudes a 5V/1A buck regulator.
- [Motor Shield][]: base board for thin nodemcu modules (devkit-1.0).
  Incudes a L293D dual H-bridge IC.

[OLED]:         http://www.aliexpress.com/snapshot/6905821870.html?orderId=69209225370843
[Base Shield]:  http://www.aliexpress.com/snapshot/6817337393.html?orderId=68495646110843
[Motor Shield]: http://www.aliexpress.com/snapshot/6775562583.html?orderId=68153436410843

### Plugins

- [Meteogram][]: use [Highcharts][] to display met data from [channel][].

[meteogram]: http://thingspeak.com/plugins/15643
[highcharts]:http://www.highcharts.com
[channel]:   http://thingspeak.com/channels/37527

### ToDo

- lua_modules: There is bearly enough RAM for the current modules.
  A [nodemcu-custom-build][] for 0.9.6 could be the way forward.
  - BME280 sensor.
  - MAX17043 sensor.
  - read sensor ids and write it as metadata(?).
  - sleep between measurements(?)
    - note: dsleep is incompatible with user blink of ledD0
  - browser side makrdown with [strapdown.js][]
  - index.md: index page with thingspeak plugins and external widgets
  - config.md: config page
    - save params to `keys.lua`
    - wifi.SOFTAP only(?)
  - decode forecast & obervations from [yr.no][] using [highcharts][] pharser:<br/>
      GET http://www.highcharts.com/samples/data/jsonp.php?url=http://www.yr.no/place/Norway/Oslo/Oslo/Marienlyst_skole/forecast.xml&callback=cjson.decode<br/>
      ... loadstrng(payload)
- plugins
  - live update for the last hour datapoint(?)
  - PM data pluggin
- nodemcu-firmware (maybe not needed)
  - i2c.bmpXXX   module for BMP085/BMP180 sensors
  - i2c.am232X   module for AM2320/AM2321 sensors
  - pms3003      module for PMS3003 sensor
  - i2c.bme280   module for BME280 sensor
  - i2c.max17043 module for MAX17043 sensor
  - try [nodemcu-custom-build][]

[strapdown.js]: http://strapdownjs.com
[luatool.py]: https://github.com/4refr0nt/luatool
[nodemcu-custom-build]: http://frightanic.com/nodemcu-custom-build
