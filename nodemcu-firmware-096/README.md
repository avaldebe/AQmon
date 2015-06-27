# NodeMCU
[firmware][]: version 0.9.6 (20150618). Custom firmware built for [AQmon][] project.<br/>
`node.heap()` after flash, `file.format()` and `node.restart()`: 23056

[firmware]: https://github.com/nodemcu/nodemcu-firmware
[AQmon]:   https://github.com/avaldebe/AQmon

##Build options
Available modules:
string, [node][], [file][], [gpio][], [wifi][], [net][],
[i2c][], [tmr][], [uart][], [bit][].<br/>
Disabled modules: table, coroutine, math,
[pwm][], spi, [adc][], [ow][], [mqtt][], u8g, ws2812, cjson,
crypto, rc, dht.<br/>

[node]: http://www.nodemcu.com/docs/node-module
[file]: http://www.nodemcu.com/docs/file-module
[gpio]: http://www.nodemcu.com/docs/gpio-module
[wifi]: http://www.nodemcu.com/docs/wifi-module
[net]:  http://www.nodemcu.com/docs/net-module
[i2c]:  http://www.nodemcu.com/docs/i2c-module
[tmr]:  http://www.nodemcu.com/docs/timer-module
[adc]:  http://www.nodemcu.com/docs/adc-module
[uart]: http://www.nodemcu.com/docs/uart-module
[bit]:  http://www.nodemcu.com/docs/bit-module
[pwm]:  http://www.nodemcu.com/docs/pwm-module
[ow]:   http://www.nodemcu.com/docs/onewire-module
[mqtt]: http://www.nodemcu.com/docs/mqtt-module

####file ./app/include/user_modules.h
```c
#ifndef __USER_MODULES_H__
#define __USER_MODULES_H__

#define LUA_USE_BUILTIN_STRING		// for string.xxx()
//-#define LUA_USE_BUILTIN_TABLE		// for table.xxx()
//-#define LUA_USE_BUILTIN_COROUTINE	// for coroutine.xxx()
//-#define LUA_USE_BUILTIN_MATH		// for math.xxx(), partially work
// #define LUA_USE_BUILTIN_IO 			// for io.xxx(), partially work

// #define LUA_USE_BUILTIN_OS			// for os.xxx(), not work
// #define LUA_USE_BUILTIN_DEBUG		// for debug.xxx(), not work

#define LUA_USE_MODULES

#ifdef LUA_USE_MODULES
#define LUA_USE_MODULES_NODE
#define LUA_USE_MODULES_FILE
#define LUA_USE_MODULES_GPIO
#define LUA_USE_MODULES_WIFI
#define LUA_USE_MODULES_NET
//-#define LUA_USE_MODULES_PWM
#define LUA_USE_MODULES_I2C
//-#define LUA_USE_MODULES_SPI
#define LUA_USE_MODULES_TMR
//-#define LUA_USE_MODULES_ADC
#define LUA_USE_MODULES_UART
//-#define LUA_USE_MODULES_OW
#define LUA_USE_MODULES_BIT
//-#define LUA_USE_MODULES_MQTT
//-#define LUA_USE_MODULES_COAP
//-#define LUA_USE_MODULES_U8G
//-#define LUA_USE_MODULES_WS2812
//-#define LUA_USE_MODULES_CJSON
//-#define LUA_USE_MODULES_CRYPTO
//-#define LUA_USE_MODULES_RC
//-#define LUA_USE_MODULES_DHT

#endif /* LUA_USE_MODULES */

#endif	/* __USER_MODULES_H__ */
```

##Compile and flash

```sh
make &&
esptool.py --port /dev/ttyUSB0 write_flash 0x00000 bin/0x00000.bin 0x10000 bin/0x10000.bin
```
