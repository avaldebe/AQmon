# AQmon Hardware

## ESP-01 board

The ESP-01 was the board that introduced the [ESP8266][] to the diy/maker community.
It needs a reliable 3.3V supply and provides 4 GPIO pins.
The original ESP-01 had only 512 KiB of flash memory.
On this project we need the more modern version with 1 MiB of flash.

![esp01](https://upload.wikimedia.org/wikipedia/commons/thumb/0/08/ESP8266_01_PinOut.png/530px-ESP8266_01_PinOut.png)

[ESP8266]: https://en.wikipedia.org/wiki/ESP8266

## Particulate Matter

The PMS3003 is a laser dust sensor by [Plantower][].
It reports PM1, PM2.5 and PM10 estimates from particle counts, under [Mie scattering][Mie] assumptions.

All sensors on the PMSx003 needs 5V to power the laser,
but communicate at 3.3V TTL via serial protocol.

[Plantower]: http://www.plantower.com
[Mie]: https://en.wikipedia.org/wiki/Mie_scattering#Atmospheric_science
[PMS3003]: ../Documents/PMS3003_LOGOELE.pdf
[PMS5003]: ../Documents/PMS5003_LOGOELE.pdf

### PMS3003

![pms3003](../Documents/pms3003_pinout.png)

### PMS5003

![pms5003](../Documents/pms5003_pinout.png)

## Temperature and Humidity

### DHT12

The [DHT12] sensor by [Aosong][], is inexpensive and small.
It reports temperature (deg C) and relative humidity (%) with 0.1 resolution
via I2C. With a Vcc range of 2.7 to 5.5V is well suited for 3.3V operations.

[Aosong]: http://aosong.com
[DHT12]: ../Documents/DHT12_Aosong.pdf

![dht12](../Documents/dht12_pinout.png)

### BME280

The [BME280][] by [bosch-sensortec][] measures pressure, humidity and temperature.
It is a good quality sensor with plenty of libraries, and inexpensive breakout boards available.
Do not confuse with the cheaper [BMP280][], which only measures pressure and temperature.

The [BMP680][] is a more expensive version which also "measures air quality".
In addition to pressure, humidity and temperature, has a gas sensor.
The library provided by the manufacturer calculates an Air Quality Index (AQI) from all measurements.
Alas, the AQI calculation is hidden in a pre-compiled library,
so it is not possible to know what this value really means.

[bosch-sensortec]: https://www.bosch-sensortec.com
[BME280]: https://www.bosch-sensortec.com/bst/products/all_products/bme280
[BMP280]: https://www.bosch-sensortec.com/bst/products/all_products/bmp280
[BME680]: https://www.bosch-sensortec.com/bst/products/all_products/bme680
