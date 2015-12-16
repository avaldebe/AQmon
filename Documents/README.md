# AQmon Miscelaneous Info

### Connect via bluetooth
Using a BT-UART module instead of a USB-UART module

```bash
# scan for BT devises
hcitool scan
# Scanning ...
#    20:13:06:19:21:35    HC-06

# connect to HC-06 on /dev/rfcomm1, and hold the port
sudo rfcomm connect /dev/rfcomm1 20:13:06:19:21:35 1

# or 1-time setup
sudo cat << _EOF >> /etc/bluetooth/rfcomm.conf
rfcomm1 { bind no;device 20:13:06:19:21:35;channel 1;comment "HC-06"; }
# now /dev/rfcomm1 is HC-06's port

# connect to HC-06 and hold the port
sudo rfcomm connect 1
# or, enable automatic connection to HC-06
sudo rfcomm bind 1
# and disable with automatic connection to HC-06
sudo rfcomm release 1
```

### Connect via telnet (partally working)
Using a [telnet script][] and [socat][].

[socat]: https://gist.github.com/ajfisher/1fdbcbbf96b7f2ba73cd#socat-to-the-rescue-mac--linux
[telnet script]: ../lua_modules/telnet_app.lua


```bash
# assume that esp8266 has IP 192.168.15.110, and listen to port 2323
sudo socat -d -d \
  pty,nonblock,link=/dev/rfcomm9,group=dialout,mode=760,ispeed=9600,ospeed=9600,raw \
  tcp:192.168.15.110:2323
```

### Console
```bash
minicom -b 9600 -D /dev/ttyUSB0 -s # USB-UART on ttyUSB0
minicom -b 9600 -D /dev/rfcomm1 -s # BT-UART  on rfcomm1
minicom -b 9600 -D /dev/rfcomm9 -s # telnet   on rfcomm9
```
