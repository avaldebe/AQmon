# lua_modules
Lua modules for [AQmon][] project.<br/>

### Acknowledgements
After many round of write/rewrite code it becomes hard to keep track of
sources for code and ideas. Please let me know, if I have missed you.

My biggest thanks to the following authors:

- [bigdanz][]: `init.lua` is based on ideas form his article abut [interrupting][] `init.lua`.
- @javieryanez: I took his [nodemcu-modules] for BMP180 and DTH22 sensors.
- [captain-slow][]: His short article on [posting to thingspeak][] helped me to get my data out.
- @geekscape: his [skeleton][]/`setup.lua` is almost esactly the same as my first version of `wifi.init`. From him I took the idea of using a generic module name (`appliation.lua`) for the appliation specific code.
- @hwiguna: his [esp8266 videos][] are an inspiration go out and play (or code).

[AQmon]: https://github.com/avaldebe/AQmon
[bigdanz]:      https://bigdanzblog.wordpress.com
[interrupting]: https://bigdanzblog.wordpress.com/2015/04/24/esp8266-nodemcu-interrupting-init-lua-during-boot
[nodemcu-modules]: https://github.com/javieryanez/nodemcu-modules
[skeleton]:        https://github.com/geekscape/nodemcu_esp8266/tree/master/skeleton
[esp8266 videos]:  https://www.youtube.com/user/hwiguna
[captain-slow]:    http://captain-slow.dk
[posting to thingspeak]: http://captain-slow.dk/2015/04/16/posting-to-thingspeak-with-esp8266-and-nodemcu
