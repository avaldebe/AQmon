# lua_modules
Lua modules for [AQmon][] project.<br/>

### Upload files
From command line with [luatool.py][]

```sh
luatool.py --src my_conf.lua --dst keys.lua --compile --restart
# or
luatool.py -f my_conf.lua -t keys.lua -c -r
```
[luatool.py]: https://github.com/4refr0nt/luatool

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
