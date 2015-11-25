# External Tools
[esptool]: https://github.com/themadinventor/esptool
[luatool]: https://github.com/4refr0nt/luatool

- [esptool][]: communicate with the ROM bootloader in the ESP8266
- [luatool][]: loade Lua-based scripts from file to ESP8266 with nodemcu firmware

### Install submodules
```bash
git submodule update --init path-to-AQmon/tools/
```

### Set up
```bash
# create a path for local/personal executables
mkdir -p ~/bin/

# link Python scripts to ~/bin/
ln -s path-to-AQmon/tools/esptool/esptool.py ~/bin/
ln -s path-to-AQmon/tools/luatool/luatool/luatool.py ~/bin/

# include ~/bin/ in path
export PATH=$PATH:$HOME/bin
```

### Usage
[upload.sh]: https://github.com/avaldebe/AQmon/blob/master/lua_modules/upload.sh

see [upload.sh][]

