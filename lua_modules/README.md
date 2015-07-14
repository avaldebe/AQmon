# lua_modules
Lua modules for [AQmon][] project.<br/>

[luatool.py]: https://github.com/4refr0nt/luatool

### Sensor modules
- `bmp180.lua`: BMP085 / BMP180 sensors.
- `am2321.lua`: AM2320 / AM2321 sensors.
- `i2d.lua`: i2c utility library.

#### Upload from command line with [luatool.py][]

```sh
# find the port
PORT=`ls /dev/ttyUSB? /dev/rfcomm? 2>/dev/null`
# remove all *.lua and *.lc files
luatool.py -p $PORT -w -r
# upload, compile and restart
luatool.py -p $PORT -c -r -f bmp180.lua
luatool.py -p $PORT -c -r -f am2321.lua
luatool.py -p $PORT -c -r -f i2d.lua
```

### Ussage example

```lua
-- module setup
sda,scl=3,4
require('bmp180').init(sda,scl)
bmp180.read(0)   -- 0:low power .. 3:oversample
p,t = bmp180.pressure,bmp180.temperature

-- release memory
bmp180,package.loaded.bmp180 = nil,nil
i2d,package.loaded.i2d = nil,nil

-- format and print the results
p = p and ('%.2f'):format(p/100) or 'null'
t = p and ('%.1f'):format(t/10)  or 'null'
print(('p:%s, t:%s, heap:%d'):format(p,t,node.heap()))
```

```lua
-- module setup
sda,scl=2,1
require('am2321').init(sda, scl)
am2321.read()
h,t = am2321.humidity,am2321.temperature

-- release memory
am2321,package.loaded.am2321 = nil,nil
i2d,package.loaded.i2d = nil,nil

-- format and print the results
h=h and ('%.1f'):format(h/10) or 'null'
t=t and ('%.1f'):format(t/10) or 'null'
print(('h:%s, t:%s, heap:%d'):format(h,t,node.heap()))
```

### Acknowledgements
After many round of write/rewrite code it becomes hard to keep track of
sources for code and ideas. Please let me know, if I have missed you.

My biggest thanks to the following authors:

- [bigdanz][]: `init.lua` is based on ideas form his article abut [interrupting][] `init.lua`.
- @javieryanez: I used his nodemcu modules for the [BMP180 and DTH22][] sensors before I wrote my own module.
  My `bmp180.lua` module is based on his.
- @saper-2: I used his nodemcu modules for the [AM2321][] sensor before I wrote my own module.
  My `am2321.lua` module is based on his.
- [captain-slow][]: His short article on [posting to thingspeak][] helped me to get my data out.
- @geekscape: his [skeleton][]/`setup.lua` is almost esactly the same as my first version of `wifi.init`.
  From him I took the idea of using a generic module name (`appliation.lua`) for the appliation specific code.
- @hwiguna: his [esp8266 videos][] are an inspiration go out and play (or code).

[AQmon]: https://github.com/avaldebe/AQmon
[bigdanz]:      https://bigdanzblog.wordpress.com
[interrupting]: https://bigdanzblog.wordpress.com/2015/04/24/esp8266-nodemcu-interrupting-init-lua-during-boot
[BMP180 and DTH22]: https://github.com/javieryanez/nodemcu-modules
[skeleton]:        https://github.com/geekscape/nodemcu_esp8266/tree/master/skeleton
[esp8266 videos]:  https://www.youtube.com/user/hwiguna
[captain-slow]:    http://captain-slow.dk
[posting to thingspeak]: http://captain-slow.dk/2015/04/16/posting-to-thingspeak-with-esp8266-and-nodemcu
[AM2321]:         https://github.com/saper-2/esp8266-am2321-remote-sensor
