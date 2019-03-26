# AQmon

DIY Air Quality Monitor

## NodeMCU/Lua version

The previous version of the project ([v1][]) went stale on 2016.
It started before the esp8266 Arduino core,
when the [nodemcu-firmware][] was the only game in town...

It used a [nodemcu-devkit][] board with a [PMS3003][] sensor,
and supported a variety of tempereture, relative humidity and preassure sensors.
The measurements were logged to [thingspeak][].
For more details, see [v1][]

[v1]: https://github.com/avaldebe/AQmon/tree/v1
[nodemcu-devkit]:   https://github.com/nodemcu/nodemcu-devkit
[nodemcu-firmware]: https://github.com/nodemcu/nodemcu-firmware
[thingspeak]:       https://thingspeak.com
[PMS3003]: Documents/PMS3003_LOGOELE.pdf
[DHT12]: Documents/DHT12_Aosong.pdf

## Arduino version

This version of the project takes advantage of the Arduino library ecosystem, and [PlatformIO](https://platformio.org/)
for IDE, tooling and library mangement.

The measurements are sent via MQTT. A private MQTT broker,
logging and visualization are hosted on a Raspberry Pi on the local network.

### Hardware

For compactnes, this version uses a
ESP-01 board with a [PMS3003][] sensor,
and [DHT12][] sensor for temperature and relative humidity.

Alas, 512 KiB of flash memory is just too litle for this project.
Fortunatelly, almost all ESP-01 boards currently available come with **1 MiB** of flash memmory.


### Firmware

It uses [Homie][] for MQTT messaging and WiFi configuration.
The  handles The PMS3003 sensor is handeled by the [PMSerial][] library,
and the [DHT12][] sensor by the [DHT12][DHT12lib] library.

[Homie]: https://platformio.org/lib/show/555/Homie/installation
[PMSerial]: https:github.com/avaldebe/PMserial.git
[DHT12lib]: https://platformio.org/lib/show/5554/DHT12

### Software

The private broker, logging and visualization on the Raspberry Pi,
follow the MQTT, InfluxDB and Grafana docker setup as descrbed by [Nilhcem][].

[Nilhcem]: http://nilhcem.com/iot/home-monitoring-with-mqtt-influxdb-grafana
