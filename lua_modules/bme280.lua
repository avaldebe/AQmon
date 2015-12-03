--[[
bme280.lua for ESP8266 with nodemcu-firmware
  Read temperature, preassure and relative humidity from BME280 sensors
  More info at  https://github.com/avaldebe/AQmon

Written by Álvaro Valdebenito.

MIT license, http://opensource.org/licenses/MIT
]]

local M={
  name=...,         -- module name, upvalue from require('module-name')
  oss=1,            -- default pressure oversamplig: 0 .. 5
  temperature=nil,  -- integer value of temperature [10*C]
  pressure   =nil,  -- integer value of preassure [100*hPa]
  humidity   =nil   -- integer value of relative humidity [10*%]
}
_G[M.name]=M

local ADDR = 0x77 -- BME280 address

-- calibration coefficients
local cal={} -- T1,..,T3,P1,..,P9,H1,..,H7

-- initialize module
local id=0
local SDA,SCL -- buffer device pinout
local init=false
function M.init(sda,scl,volatile)
-- volatile module
   if volatile==true then
    _G[M.name],package.loaded[M.name]=nil,nil
  end

  init=false
end

-- read temperature, pressure and relative humidity from BME
-- oss: oversampling setting. 0..5
function M.read(oss)
-- ensure module is initialized
  assert(init,('Need %s.init(...) before %s.read(...)'):format(M.name,M.name))
-- check input varables
  assert(type(oss)=='number' or oss==nil,
    ('%s.init %s argument should be %s'):format(M.name,'1st','number'))

-- expose results
  M.temperature=nil -- integer value of temperature [10*C]
  M.pressure   =nil -- integer value of preassure [100*hPa]
  M.humidity   =nil -- integer value of relative humidity [10*%]
end
