# lua_modules
Lua modules for [AQmon][] project.<br/>

[luatool.py]: https://github.com/4refr0nt/luatool

### Sensor modules
- `bmp180.lua`: BMP085 / BMP180 sensors.
- `am2321.lua`: AM2320 / AM2321 sensors.
- `pms3003.lua`: PMS3003 sensor.
- `sensor_hub.lua`: Read all sensors above.

#### Upload from command line with [luatool.py][]

```sh
# find the port
PORT=`ls /dev/ttyUSB? /dev/rfcomm? 2>/dev/null`
# remove all *.lua and *.lc files
luatool.py -p $PORT -w -r
# upload, compile and restart
luatool.py -p $PORT -c -r -f bmp180.lua am2321.lua pms3003.lua
# upload, rename, compile and restart
luatool.py -p $PORT -c -r -f sensor_hub.lua -t sensors.lua
```

### Ussage example
*Note*: Do not use pin `D8` (`gpio15`) for `I2C` as the pull-up resistors will
interfeere with the bootiung process.

#### BMP085, BMP180
```lua
-- module setup and read
sda,scl=3,4 -- GPIO0,GPIO2
found=require('bmp180').init(sda,scl)
if found then
  bmp180.read(0)   -- 0:low power .. 3:oversample
  p = bmp180.pressure or 'null'
  t = bmp180.temperature or 'null'
end

-- release memory
bmp180,package.loaded.bmp180 = nil,nil

-- format and print the results
if type(p)=='number' then
  p=('%5d'):format(p)
  p=('%4s.%2s'):format(p:sub(1,4),p:sub(5))
end
if type(t)=='number' then
  t=('%4d'):format(t)
  t=('%3s.%1s'):format(t:sub(1,3),t:sub(4))
end
print(('p:%s hPa, t:%s C, heap:%d'):format(p,t,node.heap()))
```

#### AM2320, AM2321
```lua
-- module setup and read
sda,scl=3,4 -- GPIO0,GPIO2
found=require('am2321').init(sda, scl)
if found then
  am2321.read()
  h = am2321.humidity or 'null'
  t = am2321.temperature or 'null'
end

-- release memory
am2321,package.loaded.am2321 = nil,nil

-- format and print the results
if type(h)=='number' then
  h=('%4d'):format(h)
  h=('%3s.%1s'):format(h:sub(1,3),h:sub(4))
end
if type(t)=='number' then
  t=('%4d'):format(t)
  t=('%3s.%1s'):format(t:sub(1,3),t:sub(4))
end
print(('h:%s %%, t:%s C, heap:%d'):format(h,t,node.heap()))
```

#### PMS3003
```lua
-- module setup and read
pinSET=7
require('pms3003').init(pinSET)
pms3003.verbose=true -- verbose mode
pms3003.read(function()
  pm01 = pms3003.pm01 or 'null'
  pm25 = pms3003.pm25 or 'null'
  pm10 = pms3003.pm10 or 'null'

-- release memory
  pms0330,package.loaded.pms0330 = nil,nil

-- print the results
  print(('pm1:%s, pm2.5:%s, pm10:%s [ug/m3], heap:%d'):format(pm01,pm25,pm10,node.heap()))
end)
```
#### Sensor Hub
```lua
-- module setup and read: no PMS3003
sda,scl,pinSET=5,6,nil
require('sensors').init(sda,scl,pinSET)
sensors.verbose=true -- verbose mode
sensors.read()

-- module setup and read: all sensors
sda,scl,pinSET=5,6,7
require('sensors').init(sda,scl,pinSET)
sensors.read(function()
  print(sensors.format({heap=node.heap(),time=tmr.time()},
    'sensors:{time}[s],{t}[C],{h}[%%],{p}[hPa],{pm01},{pm25},{pm10}[ug/m3],{heap}[b]'))
end)

-- release memory
sensors,package.loaded.sensors = nil,nil
```

### References
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
