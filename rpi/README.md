# AQmon Raspberry Pi instance
Stable plataform for sensor evaluation.

## Phython libraries
- [tentacle_pi][]: Collection of drivers for popular I2C devices.
- [python-yr][]:   Retreieve weather forecasts from [yr.no][].
- [thingspeak log]: Short tutorial posting data to [thingspeak][] using Python.

[tentacle_pi]:    https://github.com/lexruee/tentacle_pi
[python-yr]:      https://github.com/wckd/python-yr
[thingspeak log]: http://www.australianrobotics.com.au/news/how-to-talk-to-thingspeak-with-python-a-memory-cpu-monitor
[yr.no]:          http://www.yr.no/place/Norway/Oslo/Oslo/Marienlyst_skole
[thingspeak]:     https://thingspeak.com

## Lua libraries
Test AQmon lua modules on the Pi.

- [rpi-gpio][]: GPIO only.
  - [intro][] with example.
- [lua-periphery][]: GPIO, SPI, I2C, MMIO, and Serial peripheral I/O.
- [luabitop][]: bitwise operations on numbers for Lua 5.1.

```bash
# install lua 5.1 and luarocks
sudo apt-get install lua5.1 liblua5.1-0-dev
sudo apt-get install luarocks
# install lua-periphery
sudo luarocks install lua-periphery
# install luabitop
luarocks install luabitop
```

[intro]:         http://www.andre-simon.de/doku/rpi_gpio_lua/en/rpi_gpio_lua.php
[rpi-gpio]:      https://luarocks.org/modules/luarocks/rpi-gpio
[lua-periphery]: https://luarocks.org/modules/vsergeev/lua-periphery
[luabitop]:      https://luarocks.org/modules/luarocks/luabitop

## RPi management, maintinence & other
### Password-less login
```bash
ssh-keygen                         # create key on local machine
ssh-copy-id pi@raspberrypi.local   # copy key to raspberrypi
ssh pi@raspberrypi.local           # ssh to raspberrypi
```

### Sleep & wake
The command ``sudo halt`` puts the cpu/gpu into a very low power state
making the system safe to power off.
To wake up, short ``GPIO3`` & ``GND`` (``P1-05`` & ``P1-06``).
The reset switch on the [X100][] shorts ``RUN`` & ``GND`` (``P6-01`` & ``P6-02``).
This will cause a soft reset of the CPU (which can also 'wake' the Pi from halt/shutdown state).

### Update
```bash
sudo apt-get update       # resync package index files from sources
sudo apt-get -s upgrade   # simulate upgrade (update installed packages)
sudo apt-get -y upgrade   # update installed packages (yes to all)
```
[unattended upgrades]: http://blog.benoitblanchon.fr/unattended-upgrades/
[changelog before upgrade]: http://jxf.me/entries/better-apt-ubuntu/
### [Unattended upgrades]
```bash
sudo apt-get install unattended-upgrades apt-listchanges
sudo dpkg-reconfigure -plow unattended-upgrades
sudo dpkg-reconfigure apt-listchanges
```

### [X100][] shield
[X100]: http://www.suptronics.com/Xseries/x100.html
The installation instructions for the RTC on the X100 (NXP PCF2127AT/ PCF2129AT) suggest a custom kernel (3.6.11+).
Kernel 3.12.20+ includes rtc-pcf2127.ko, so the custom kernel/additional rtc-pcf2127a.ko module is not necessary.
append to ``/etc/modules``

```bash
i2c-bcm2708
rtc-pcf2127
```
and add to ``/etc/rc.local`` before ‘exit 0’

```bash
echo pcf2127 0x51 > /sys/class/i2c-adapter/i2c-1/new_device
[ "$_IP" ] || ( sleep 2; hwclock -s ) &
```

### SoC panel
[article (in Spanish)]: https://geekytheory.com/panel-de-monitorizacion-para-raspberry-pi-con-node-js/
[web dashboard]: http://raspberrypi.local:8000/
The [article (in Spanish)][] implements a [web dashboard][]
for SoC temperature, CPU load and mmemory ussage.

```bash
# install node.js and dependencies
sudo apt-get install nodejs npm git
sudo npm config set registry http://registry.npmjs.org/

# clone article repo
mkdir -p ~/Projects; cd ~/Projects
git clone https://github.com/GeekyTheory/Raspberry-Pi-Status.git
cd Raspberry-Pi-Status/

# instal node.js modules
npm install soket.io
npm install
sudo apt-get install nodejs-legacy
sudo npm install forever -g
forever start ~/Projects/Raspberry-Pi-Status/server.js

# start service on reboot
cat << _EOF >> ~/.crontab
@reboot /usr/local/bin/forever start -c /usr/bin/node ...
@daily  crontab       ~/.crontab
_EOF
crontab ~/.crontab
sudo reboot
```
