# AQmon Hardware

## ESP-01 board

The ESP-01 was the board that introdiced the [ESP8266][] to the diy/maker comunity. It needs a reliable 3.3V supply and provides a 4 GPIO pins.
The original ESP-01 had only 512 KiB of flash memory.
On this project we need the more modern version with 1 MiB of flash.

![esp01](https://upload.wikimedia.org/wikipedia/commons/thumb/0/08/ESP8266_01_PinOut.png/530px-ESP8266_01_PinOut.png)

[ESP8266]: https://en.wikipedia.org/wiki/ESP8266

### Temperature and Humidity

The [DHT12] sensor by [Aosong][], is inexpensive and small.
It reports tempreature (deg C) and relative humidity (%) with 0.1 resoluttion
via I2C. With a Vcc range of 2.7 to 5.5V is well sutted for 3.3V operations.

[Aosong]: http://aosong.com
[DHT12]: ../Documents/DHT12_Aosong.pdf

![dht12](../Documents/dht12_pinout.png)

## Particulate Matter

The PMS3003 is a laser dust sensor by [Plantower][].
It reports PM1, PM2.5 and PM10 esitmates from particle counts, under [Mie scattering][Mie] assumptions.

All sensors on the PMSx003 needs 5V to power the laser,
but comunicate at 3.3V TTL via serial protocol.

[Plantower]: http://www.plantower.com
[Mie]: https://en.wikipedia.org/wiki/Mie_scattering#Atmospheric_science
[PMS3003]: ../Documents/PMS3003_LOGOELE.pdf
[PMS5003]: ../Documents/PMS5003_LOGOELE.pdf

### PMS3003

![pms3003](../Documents/pms3003_pinout.png)

### PMS5003

![pms5003](../Documents/pms5003_pinout.png)
