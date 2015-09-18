--[[
am2321.lua for ESP8266 with nodemcu-firmware
  Read temperature and relative humidity from AM2320/AM2321 sensors
  More info at  https://github.com/avaldebe/AQmon

Written by Álvaro Valdebenito.

MIT license, http://opensource.org/licenses/MIT
]]


local moduleName = ...
local M = {}
_G[moduleName] = M

require('i2d') -- i2c utility library

local ADDR=bit.rshift(0xB8,1) -- use 7bit address

local function crc_check(c)
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
  return (crc==i2d.b2i(c:byte(len),c:byte(len-1)))
end

function M.init(...)
  i2d.init(ADDR,...)
end

function M.read()
-- wakeup
  i2d.wake()
-- request HUMIDITY_MSB 0x00 .. TEMPERATURE_LSB 0x03
  i2d.write(0x03,0x00,0x04)
  tmr.delay(1600)         -- wait at least 1.5ms
-- read HUMIDITY_MSB 0x00 .. TEMPERATURE_LSB 0x03
  local c=i2d.read(8)     -- cmd(2)+data(4)+crc(2)

  if crc_check(c) then
    M.humidity   =i2d.b2i(c:byte(3,4))
    M.temperature=i2d.b2i(c:byte(5,6))
  else
    M.humidity   =nil
    M.temperature=nil
  end
end

return M
