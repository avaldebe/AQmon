# Sensor modules
Lua modules for [AQmon][] project.<br/>

[AQmon]:      https://github.com/avaldebe/AQmon

### Sensor modules
- `bmp180.lua`: BMP085 / BMP180 sensors.
- `am2321.lua`: AM2320 / AM2321 sensors.
- `bme280.lua`: BME280 sensor, can replace BMPxxx and AM232x sensors.
- `pms3003.lua`: PMS3003 (tested) sensors and
                 PMS1003 / PMS2003 / PMS5003 / PMS7003 (untested) sensors via UART.
- `sensor_hub.lua`: Read all sensors above.

#### Notes
- The [nodemcu-devkit][] has a pull-up resistors on pins
  `D3` (`gpio0`) and  `D4` (`gpio0`). `D3` is attacked to `KEY_FLASH`.
  - The pull-down resistor could be usefull for `I2C` bus,
    as long as `KEY_FLASH` is not used.
- The [nodemcu-devkit][] has a pull-down resistor on pin
  `D8` (`gpio15`), in order to boot from the `SPI FLASH IC`:
  - Do not use it for the `I2C` bus
    as the pull-up resistors will interfeere with the bootiung process.
  - Do not use it to drive `PMS3003`'s `PMset` pin as it floats high
    (needs to be driven low to put the `PMS3003` on standby),
    and will interfeere with the bootiung process.
- I2C address (in 7-bit format):
  - BMP085 and BMP180 sensors have the same address: 0x77.
    Can ony have one of them on the same bus.
  - BME280 sensors can have one of 2 addresses: 0x76 or 0x77.
    Can have two of them on the same bus if the addresses differ.
  - AM2320 and AM2321 sensors have the same address: 0x5C.
    Can ony have one of them on the same bus.
  - The `i2c-autoscan.lua` script can help to find connected I2C devises.

[nodemcu-devkit]:   https://github.com/nodemcu/nodemcu-devkit

### Ussage example

#### BMP085, BMP180
```lua
-- module setup and read
sda,scl=3,4 -- GPIO0,GPIO2
found=require('bmp180').init(sda,scl)
if found then
  bmp180.read(0)   -- 0:low power .. 3:oversample
  pres,temp = bmp180.pressure,bmp180.temperature
end

-- release memory
bmp180,package.loaded.bmp180 = nil,nil

-- format and print the results
function f7p2(v)
  if v==nil then
    return ('%7s'):format('null')
  elseif (1/2)==0 then  -- no floating point operations
    v=(v>=0 and '%03d' or '%04d'):format(v)
    return ('%4s.%2s'):format(v:sub(1,-3),v:sub(-2))
  else                  -- use floating point fomatting
    return ('%7.2f'):format(v/100)
  end
end

print(('pres:%s hPa, temp:%s C, heap:%d')
  :format(f7p2(pres),f7p2(temp),node.heap()))

-- release memory
f7p2 = nil
```

#### AM2320, AM2321
```lua
-- module setup and read
sda,scl=3,4 -- GPIO0,GPIO2
found=require('am2321').init(sda,scl)
if found then
  am2321.read()
  rhum,temp = am2321.humidity,am2321.temperature
end

-- release memory
am2321,package.loaded.am2321 = nil,nil

-- format and print the results
function f7p2(v)
  if v==nil then
    return ('%7s'):format('null')
  elseif (1/2)==0 then  -- no floating point operations
    v=(v>=0 and '%03d' or '%04d'):format(v)
    return ('%4s.%2s'):format(v:sub(1,-3),v:sub(-2))
  else                  -- use floating point fomatting
    return ('%7.2f'):format(v/100)
  end
end

print(('rhum:%s %%, temp:%s C, heap:%d')
 :format(f7p2(rhum),f7p2(temp),node.heap()))

-- release memory
f7p2 = nil
```

#### BME280
```lua
-- module setup and read
sda,scl=3,4 -- GPIO0,GPIO2
found=require('bme280').init(sda,scl)
if found then
  bme280.read()
  pres,temp,rhum = bme280.pressure,bme280.temperature,bme280.humidity
end

-- release memory
bme280,package.loaded.bme280 = nil,nil

-- format and print the results
function f7p2(v)
  if v==nil then
    return ('%7s'):format('null')
  elseif (1/2)==0 then  -- no floating point operations
    v=(v>=0 and '%03d' or '%04d'):format(v)
    return ('%4s.%2s'):format(v:sub(1,-3),v:sub(-2))
  else                  -- use floating point fomatting
    return ('%7.2f'):format(v/100)
  end
end

print(('pres:%s hPa, temp:%s C, rhum:%s %%, heap:%d')
 :format(f7p2(pres),f7p2(temp),f7p2(rhum),node.heap()))

-- release memory
f7p2 = nil
```

#### PMS3003
```lua
-- module setup and read
PMset=7
require('pms3003').init(PMset)
pms3003.verbose=true -- verbose mode
pms3003.read(function()
  pm01 = pms3003.pm01 or 'null'
  pm25 = pms3003.pm25 or 'null'
  pm10 = pms3003.pm10 or 'null'

-- release memory
  pms3003,package.loaded.pms3003 = nil,nil

-- print the results
  print(('pm1:%s, pm2.5:%s, pm10:%s [ug/m3], heap:%d'):format(pm01,pm25,pm10,node.heap()))
end)
```
#### Sensor Hub
```lua
-- module setup and read: no PMS3003
sda,scl,PMset=3,4,nil -- GPIO0,GPIO2
require('sensors').init(sda,scl,PMset)
sensors.verbose=true -- verbose mode
sensors.read()

-- module setup and read: all sensors
sda,scl,PMset=5,6,7
require('sensors').init(sda,scl,PMset)
sensors.read(function()
  print(sensors.format({heap=node.heap(),time=tmr.time()},
    '{name}:{time}[s],{temp}[C],{rhum}[%],{pres}[hPa],{pm01},{pm25},{pm10}[ug/m3],{heap}[b]'))
end)

-- release memory
sensors,package.loaded.sensors = nil,nil
```
