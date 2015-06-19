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
- config page
- remove DHT22
- finish shield
- lua module for [AM2321][] (i2c) sensor
- lua module for [AM2321][] (uart) sensor
- add [PMS3003][] sensor to shield
- lua module for [PMS3003][] sensor
- i2c.bmpXXX module: add native firmware support for BMP085/BMP180 sensors
- i2c.am2321 module: add native firmware support for [AM2321][] sensor
- pms3003 module: add native firmware support for [PMS3003][] sensor
