# AQmon Hardware

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

The current version of the firmware does not supports the BME280.
Support is planned for future versions, so footprints for a breakout board
is included on several of the AQmon boards currently in development.

## Boards

### ESP-01

The ESP-01 was the board that introduced the [ESP8266][] to the diy/maker community.
It needs a reliable 3.3V supply and provides 4 GPIO pins.
The original ESP-01 had only 512 KiB of flash memory.
On this project we need the more modern version with 1 MiB of flash.

![esp01](https://upload.wikimedia.org/wikipedia/commons/thumb/0/08/ESP8266_01_PinOut.png/530px-ESP8266_01_PinOut.png)

[ESP8266]: https://en.wikipedia.org/wiki/ESP8266

### D1 mini

The [d1_mini][] board is the most popular ESP8266 board for weekend projects.
It comes with 4 MiB of flash and a CH340G USB to serial converter.
It is easy to program thanks to the builtin reset circuitry
and has enough memory for OTA updates.

![d1mini](https://wiki.wemos.cc/_media/products:d1:d1_mini_v3.1.0_1_16x9.jpg)

[d1_mini]: https://wiki.wemos.cc/products:d1:d1_mini

### AQmon

At the time of writing, 3 AQmon boards are in development.

The [AQmonV2-ESP01][] is a compact board for the ESP-01.
It has the 8-pin connector used by the PMS3003 and PMS5003
(Molex 1.25mm "PicoBlade" 51021 compatible, found online as 1.25mm JST).
This board also includes a footprint for the DHT12 and a 1.25mm 4 pin connetor
for a different I2C sensor, such as the BME280.
The PCB for this board is currently been manufactured...

![AQmonV2-ESP01](https://image.easyeda.com/histories/c21576176590435a99e9380fa947cace.png)


The other 2 boards under development are for the [d1_mini][].
One is a shield with connectors for the PMS3003/PMS5003 and BME280.
The other is a base plate for a 5x7 cm2 case, with footprints for
PMS3003/PMS5003 or PMS7003 sensor...

[AQmonV2-ESP01]: https://easyeda.com/avaldebe/AQmonV2-ESP01