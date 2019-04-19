# AQmon

DIY Air Quality Monitor

## NodeMCU/Lua version

The previous version of the project ([v1][]) went stale on 2016.
It started before the esp8266 Arduino core,
when the [nodemcu-firmware][] was the only game in town...

It used a [nodemcu-devkit][] board with a [PMS3003][] sensor,
and supported a variety of temperature, relative humidity and preassure sensors.
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
for IDE, tooling and library management.

The measurements are sent via MQTT. A private MQTT broker,
logging and visualization are hosted on a Raspberry Pi on the local network.

### Hardware

For compactness, this version uses a
ESP-01 board with a [PMS3003][] sensor,
and [DHT12][] sensor for temperature and relative humidity.

Alas, 512 KiB of flash memory is just too litle for this project.
Fortunately, almost all ESP-01 boards currently available come with **1 MiB** of flash memory.

### Firmware

It uses [Homie][] for MQTT messaging and WiFi configuration.
The  handles the PMS3003 sensor is handled by the [PMSerial][] library,
and the [DHT12][] sensor by the [DHT12][DHT12lib] library.

[Homie]: https://platformio.org/lib/show/555/Homie/installation
[PMSerial]: https:github.com/avaldebe/PMserial.git
[DHT12lib]: https://platformio.org/lib/show/5554/DHT12

### Software

The private broker, logging and visualization on the Raspberry Pi,
follow the MQTT, InfluxDB and Grafana docker setup as descried by [Nilhcem][].

[Nilhcem]: http://nilhcem.com/iot/home-monitoring-with-mqtt-influxdb-grafana

## Configuration and testing

### Setup a new AQmon device

Write a [config file][config] in `data/homie/config.json`, and
use the following commands to upload the firmware and configuration:

```bash
# upload the configuration
pio run -d firmware -e esp01 -e uploadfs

# upload the firmware
pio run -d firmware -e esp01 -e upload
```

[config]: https://homieiot.github.io/homie-esp8266/docs/2.0.0/configuration/json-configuration-file/

### Config example

The following example defines an AQmon named `"AQmon test"`,
which will send sensor measurements every 60 s
to test.mosquitto.org, which is a **public** MQTT broker.
Replace the `wifi.ssid`, `wifi.password` and other relevant fields,
such as `name`, `device_id` and `mqtt.host` before uploading the file.

```json
{
  "name": "AQmon test",
  "device_id": "test",
  "device_stats_interval": 60,
  "wifi": {
    "ssid": "Network_1",
    "password": "I'm a Wi-Fi password!"
  },
  "mqtt": {
    "host": "test.mosquitto.org",
    "port": 1883,
    "base_topic": "aqmon/"
  },
  "ota": {
    "enabled": false
  }
}  
```

### MQTT messages

The example configuration defined a new AQmon device with `device_id=test` and `mqtt.host=test.mosquitto.org`.

Subscribe to the new device messages with:

```bash
mosquitto_sub -h test.mosquitto.org -t "aqmon/test/#" -v
```

Each time the device boots, you should see a something like:

```mqtt
aqmon/test/$homie 2.0.0
aqmon/test/$mac XX:XX:XX:XX:XX
aqmon/test/$name AQmon test
aqmon/test/$localip X.X.X.X
aqmon/test/$stats/interval 0
aqmon/test/$fw/name AQmon
aqmon/test/$fw/version v2.0.0-rc2
aqmon/test/$fw/checksum ab0ef7c4435e557a027a92c091360228
aqmon/test/$implementation esp8266
aqmon/test/$implementation/config {"name":"AQmon test","device_id":"test","device_stats_interval":60,"wifi":{"ssid":"Network_1"},"mqtt":{"host":"test.mosquitto.org","port":1883,"base_topic":"aqmon/"},"ota":{"enabled":false}}
aqmon/test/$implementation/version 2.0.0
aqmon/test/$implementation/ota/enabled false
aqmon/test/temperature/$type temperature
aqmon/test/temperature/$properties sensor,unit,degrees
aqmon/test/humidity/$type humidity
aqmon/test/humidity/$properties sensor,unit,percentage
aqmon/test/pm01/$type PM1
aqmon/test/pm01/$properties sensor,unit,concentration
aqmon/test/pm25/$type PM2.5
aqmon/test/pm25/$properties sensor,unit,concentration
aqmon/test/pm10/$type PM10
aqmon/test/pm10/$properties sensor,unit,concentration
aqmon/test/$online true
aqmon/test/temperature/sensor DHT12
aqmon/test/temperature/unit c
aqmon/test/humidity/sensor DHT12
aqmon/test/$stats/signal 82
aqmon/test/$stats/uptime 37
```

Every 5 minutes should get a new set of messages like:

```mqtt
aqmon/test/temperature/degrees 25.0
aqmon/test/humidity/percentage 10.0
aqmon/test/pm01/concentration 2
aqmon/test/pm25/concentration 2
aqmon/test/pm10/concentration 2
aqmon/test/$stats/signal 82
aqmon/test/$stats/uptime 338
```

If the device lose connection to the broker you should get a message like:

```mqtt
aqmon/test/$online false
```