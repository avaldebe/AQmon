--[[
bmp180.lua for ESP8266 with nodemcu-firmware
  Read temperature and preassure from BMP085/BMP180 sensors
  More info at  https://github.com/avaldebe/AQmon

Written by Álvaro Valdebenito,
  based on bmp180.lua by Javier Yanez
  https://github.com/javieryanez/nodemcu-modules

MIT license, http://opensource.org/licenses/MIT
]]

local moduleName = ...
local M = {}
_G[moduleName] = M

require('i2d') -- i2c utility library

local ADDR = 0x77 -- BMP085/BMP180 address
local REG_CALIBRATION = 0xAA
local REG_CONTROL = 0xF4
local REG_RESULT  = 0xF6

local COMMAND_TEMPERATURE = 0x2E
local COMMAND_PRESSURE = {[0]=0x34,[1]=0x74,[2]=0xB4,[3]=0xF4}
local WAIT_TEMPERATURE = 5e3 -- 5ms
local WAIT_PRESSURE    = {[0]= 5e3,[1]= 8e3,[2]=14e3,[3]=26e3}

-- calibration coefficients
local AC1, AC2, AC3, AC4, AC5, AC6, B1, B2, MB, MC, MD
local init = false
local B5

-- initialize module
function M.init(...)
  i2d.init(ADDR,...)
  if not init then
-- request CALIBRATION
    i2d.write(REG_CALIBRATION)
-- read CALIBRATION
    local c=i2d.read(22,REG_CALIBRATION)
-- unpack CALIBRATION
    AC1=i2d.b2i(c:byte( 1),c:byte( 2),true)
    AC2=i2d.b2i(c:byte( 3),c:byte( 4),true)
    AC3=i2d.b2i(c:byte( 5),c:byte( 6),true)
    AC4=i2d.b2i(c:byte( 7),c:byte( 8))
    AC5=i2d.b2i(c:byte( 9),c:byte(10))
    AC6=i2d.b2i(c:byte(11),c:byte(12))
    B1 =i2d.b2i(c:byte(13),c:byte(14),true)
    B2 =i2d.b2i(c:byte(15),c:byte(16),true)
    MB =i2d.b2i(c:byte(17),c:byte(18),true)
    MC =i2d.b2i(c:byte(19),c:byte(20),true)
    MD =i2d.b2i(c:byte(21),c:byte(22),true)
-- initialization completed
    init = true
  end
end

-- read temperature from BMP
local function readTemperature()
-- request TEMPERATURE
  i2d.write(REG_CONTROL,COMMAND_TEMPERATURE)
  tmr.delay(WAIT_TEMPERATURE)
-- request RESULT
  i2d.write(REG_RESULT)
-- read RESULT
  local c = i2d.read(2)
-- unpack TEMPERATURE
  local UT = i2d.b2i(c:byte(1,2))
  local X1 = (UT - AC6) * AC5 / 32768
  local X2 = MC * 2048 / (X1 + MD)
  B5 = X1 + X2
  local t = (B5 + 8) / 16
  return t
end

-- read pressure from BMP
-- must be read after read temperature
local function readPressure(oss)
-- request PRESSURE
  i2d.write(REG_CONTROL,COMMAND_PRESSURE[oss])
  tmr.delay(WAIT_PRESSURE[oss])
-- request RESULT
  i2d.write(REG_RESULT)
-- read RESULT
  local c = i2d.read(3)
-- unpack PRESSURE
  local UP = i2d.b3i(c:byte(1,3))
  UP = UP / 2 ^ (8 - oss)
  local B6 = B5 - 4000
  local X1 = B2 * (B6 * B6 / 4096) / 2048
  local X2 = AC2 * B6 / 2048
  local X3 = X1 + X2
  local B3 = ((AC1 * 4 + X3) * 2 ^ oss + 2) / 4
  X1 = AC3 * B6 / 8192
  X2 = (B1 * (B6 * B6 / 4096)) / 65536
  X3 = (X1 + X2 + 2) / 4
  local B4 = AC4 * (X3 + 32768) / 32768
  local B7 = (UP - B3) * (50000/2 ^ oss)
  local p = (B7 / B4) * 2
  X1 = (p / 256) * (p / 256)
  X1 = (X1 * 3038) / 65536
  X2 = (-7357 * p) / 65536
  p = p +(X1 + X2 + 3791) / 16
  return p
end

-- read temperature and pressure from BMP
-- oss: oversampling setting. 0-3
function M.read(oss)
  if type(oss)~="number" or oss<0 or oss>3 then
    oss=0
  end
  if not init then
    print("Need to call init(...) call before calling read(...).")
    M.temperature=nil
    M.pressure   =nil
  else
    M.temperature=readTemperature()
    M.pressure   =readPressure(oss)
  end
end

return M
