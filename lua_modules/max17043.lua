--[[
max17043.lua for ESP8266 with nodemcu-firmware
  Squeleton module for MAX17043 sensors
  More info at  https://github.com/avaldebe/AQmon

Written by Álvaro Valdebenito,
  based on:
  - SparkFunMAX17043.cpp by sparkfun
    https://github.com/sparkfun/SparkFun_MAX17043_Particle_Library

MIT license, http://opensource.org/licenses/MIT
]]

local M={
  name=...,         -- module name, upvalue from require('module-name')
  vcell=nil,        -- 12-bit A/D measurement of battery voltage
  soc=nil           -- 16-bit state of charge (SOC)
}
_G[M.name]=M

local ADDR = 0x36 -- 7-bit address

-- initialize module
local id=0
local SDA,SCL -- buffer device pinout
local init=false
function M.init(sda,scl,volatile)
-- volatile module
   if volatile==true then
    _G[M.name],package.loaded[M.name]=nil,nil
  end

-- buffer pin set-up
  if (sda and sda~=SDA) or (scl and scl~=SCL) then
    SDA,SCL=sda,scl
    i2c.setup(id,SDA,SCL,i2c.SLOW)
  end

-- M.init suceeded ...
  return init
end

function M.read()
-- ensure module is initialized
  assert(init,('Need %s.init(...) before %s.read(...)'):format(M.name,M.name))

end
