--[[
am2321.lua for ESP8266 with nodemcu-firmware
  Read temperature and relative humidity from AM2320/AM2321 sensors
  More info at  https://github.com/avaldebe/AQmon

Written by Álvaro Valdebenito.

MIT license, http://opensource.org/licenses/MIT
]]


local M={
  name=...,       -- module name, upvalue from require('module-name')
  temperature=nil,-- integer value of temperature [10*C]
  humidity   =nil -- integer value of relative humidity [10*%]
}
_G[M.name]=M

local ADDR=bit.rshift(0xB8,1) -- use 7bit address

-- initialize i2c
local id=0
local SDA,SCL -- buffer device address and pinout
local init=false
function M.init(sda,scl,volatile)
-- volatile module
  if volatile==true then
    _G[M.name],package.loaded[M.name]=nil,nil -- volatile module
  end

-- buffer pin set-up
  if (sda and sda~=SDA) or (scl and scl~=SCL) then
    SDA,SCL=sda,scl
    i2c.setup(id,SDA,SCL,i2c.SLOW)
  end

-- initialization
  if not init then
-- wakeup
    i2c.start(id)
    i2c.address(id,ADDR,i2c.TRANSMITTER)
    i2c.stop(id)
-- device found?
    i2c.start(id)
    init=i2c.address(id,ADDR,i2c.TRANSMITTER)
    i2c.stop(id)
  end

-- M.init suceeded if ADDR is found on SDA,SCL
  return init
end

function M.read()
-- ensure module is initialized
  assert(init,('Need %s.init(...) before %s.read(...)'):format(M.name,M.name))
-- wakeup
  i2c.start(id)
  i2c.address(id,ADDR,i2c.TRANSMITTER)
  i2c.stop(id)
-- request HUMIDITY_MSB 0x00 .. TEMPERATURE_LSB 0x03
  i2c.start(id)
  i2c.address(id,ADDR,i2c.TRANSMITTER)
  i2c.write(id,0x03,0x00,0x04)
  i2c.stop(id)
  tmr.delay(1600)         -- wait at least 1.5ms
-- read HUMIDITY_MSB 0x00 .. TEMPERATURE_LSB 0x03
  i2c.start(id)
  i2c.address(id,ADDR,i2c.RECEIVER)
  local c=i2c.read(id,8)  -- cmd(2)+data(4)+crc(2)
-- consistency check
  local len=c:len()
  local crc=0xFFFF
  local l,i
  for l=1,len-2 do
    crc=bit.bxor(crc,c:byte(l))
    for i=1,8 do
      if bit.band(crc,1) ~= 0 then
        crc=bit.rshift(crc,1)
        crc=bit.bxor(crc,0xA001)
      else
        crc=bit.rshift(crc,1)
      end
    end
  end
-- expose results
  if crc==c:byte(len)*256+c:byte(len-1) then
    M.humidity   =c:byte(3)*256+c:byte(4)
    M.temperature=c:byte(5)*256+c:byte(6)
  else
    M.humidity   =nil
    M.temperature=nil
  end
end

return M
