# **NodeMCU**
version: [0.9.5](https://github.com/nodemcu/nodemcu-firmware) (20150318)<br/>
Custom firmware built for [AQmonitor project](https://github.com/avaldebe/AQmon).<br/>
`node.heap()` after flash, `file.format()` and `node.restart()`: 25112

##Build options
Available modules:
string,
[node](http://www.nodemcu.com/docs/node-module),
[file](http://www.nodemcu.com/docs/file-module),
[gpio](http://www.nodemcu.com/docs/gpio-module),
[wifi](http://www.nodemcu.com/docs/wifi-module),
[net](http://www.nodemcu.com/docs/net-module),
[i2c](http://www.nodemcu.com/docs/i2c-module),
[tmr](http://www.nodemcu.com/docs/timer-module),
[adc](http://www.nodemcu.com/docs/adc-module),
[uart](http://www.nodemcu.com/docs/uart-module),
[bit](http://www.nodemcu.com/docs/bit-module).<br/>
Disabled modules:
table,
coroutine,
math,
[pwm](http://www.nodemcu.com/docs/pwm-module/),
[ow](http://www.nodemcu.com/docs/onewire-module),
[mqtt](http://www.nodemcu.com/docs/mqtt-module),
u8g,
ws2812,
cjson.<br/>

####file ./app/include/user_modules.h
```c
#define LUA_USE_BUILTIN_STRING       // for string.xxx()
// #define LUA_USE_BUILTIN_TABLE     // for table.xxx()
// #define LUA_USE_BUILTIN_COROUTINE // for coroutine.xxx()
// #define LUA_USE_BUILTIN_MATH      // for math.xxx(), partially work
// #define LUA_USE_BUILTIN_IO        // for io.xxx(), partially work

// #define LUA_USE_BUILTIN_OS        // for os.xxx(), not work
// #define LUA_USE_BUILTIN_DEBUG     // for debug.xxx(), not work

#define LUA_USE_MODULES

#ifdef LUA_USE_MODULES
#define LUA_USE_MODULES_NODE
#define LUA_USE_MODULES_FILE
#define LUA_USE_MODULES_GPIO
#define LUA_USE_MODULES_WIFI
#define LUA_USE_MODULES_NET
// #define LUA_USE_MODULES_PWM
#define LUA_USE_MODULES_I2C
// #define LUA_USE_MODULES_SPI
#define LUA_USE_MODULES_TMR
#define LUA_USE_MODULES_ADC
#define LUA_USE_MODULES_UART
// #define LUA_USE_MODULES_OW
#define LUA_USE_MODULES_BIT
// #define LUA_USE_MODULES_MQTT
// #define LUA_USE_MODULES_COAP
// #define LUA_USE_MODULES_U8G
// #define LUA_USE_MODULES_WS2812
// #define LUA_USE_MODULES_CJSON
#endif /* LUA_USE_MODULES */
```

##Compile and flash

```sh
make
make blank
make flash

```

