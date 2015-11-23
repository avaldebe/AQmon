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

local ADDR = 0x77 -- BMP085/BMP180 address

-- calibration coefficients
local cal={} -- AC1, AC2, AC3, AC4, AC5, AC6, B1, B2, MB, MC, MD
local B5

-- initialize module
function M.init(sda,scl)
  if (sda and sda~=SDA) or (scl and scl~=SCL) then
    SDA,SCL=sda,scl
    i2c.setup(id,SDA,SCL,i2c.SLOW)
  end

-- read calibration coeff., if cal table is empty
  if next(cal)==nil then
-- request CALIBRATION
    i2c.start(id)
    i2c.address(id,ADDR,i2c.TRANSMITTER)
    i2c.write(id,0xAA) -- REG_CALIBRATION
    i2c.stop(id)
-- read CALIBRATION
    i2c.start(id)
    i2c.address(id,ADDR,i2c.RECEIVER)
    local c = i2c.read(id,22)
    i2c.stop(id)
-- unpack CALIBRATION
    cal.AC1=c:byte( 1)*256+c:byte( 2)+(cal.AC1>32767 and -65536 or 0)
    cal.AC2=c:byte( 3)*256+c:byte( 4)+(cal.AC2>32767 and -65536 or 0)
    cal.AC3=c:byte( 5)*256+c:byte( 6)+(cal.AC3>32767 and -65536 or 0)
    cal.AC4=c:byte( 7)*256+c:byte( 8)
    cal.AC5=c:byte( 9)*256+c:byte(10)
    cal.AC6=c:byte(11)*256+c:byte(12)
    cal.B1 =c:byte(13)*256+c:byte(14)+(cal.B1 >32767 and -65536 or 0)
    cal.B2 =c:byte(15)*256+c:byte(16)+(cal.B2 >32767 and -65536 or 0)
    cal.MB =c:byte(17)*256+c:byte(18)+(cal.MB >32767 and -65536 or 0)
    cal.MC =c:byte(19)*256+c:byte(20)+(cal.MC >32767 and -65536 or 0)
    cal.MD =c:byte(21)*256+c:byte(22)+(cal.MD >32767 and -65536 or 0)
  end
end

-- read temperature from BMP
local function readTemperature()
  local REG_COMMAND = 0x2E
  local WAIT = 5000 -- 5ms
-- request TEMPERATURE
  i2c.start(id)
  i2c.address(id,ADDR,i2c.TRANSMITTER)
  i2c.write(id,0xF4,REG_COMMAND) -- REG_CONTROL,REG_COMMAND
  i2c.stop(id)
  tmr.delay(WAIT)
-- request RESULT
  i2c.start(id)
  i2c.address(id,ADDR,i2c.TRANSMITTER)
  i2c.write(id,0xF6) -- REG_RESULT
  i2c.stop(id)
-- read RESULT
  i2c.start(id)
  i2c.address(id,ADDR,i2c.RECEIVER)
  local c = i2c.read(id,2)
  i2c.stop(id)
-- unpack TEMPERATURE
  local UT = c:byte(1)*265+c:byte(2)
  local X1 = (UT - cal.AC6) * cal.AC5 / 32768
  local X2 = cal.MC * 2048 / (X1 + cal.MD)
  B5 = X1 + X2
  local t = (B5 + 8) / 16
  return t
end

-- read pressure from BMP
-- must be read after read temperature
local function readPressure(oss)
  local REG_COMMAND = ({[0]=0x34,[1]=0x74,[2]=0xB4, [3]=0xF4 })[oss]
  local WAIT        = ({[0]=5000,[1]=8000,[2]=14000,[3]=26000})[oss]
-- request PRESSURE
  i2c.start(id)
  i2c.address(id,ADDR,i2c.TRANSMITTER)
  i2c.write(id,0xF4,REG_COMMAND) -- REG_CONTROL,REG_COMMAND
  i2c.stop(id)
  tmr.delay(WAIT)
-- request RESULT
  i2c.start(id)
  i2c.address(id,ADDR,i2c.TRANSMITTER)
  i2c.write(id,0xF6) -- REG_RESULT
  i2c.stop(id)
-- read RESULT
  i2c.start(id)
  i2c.address(id,ADDR,i2c.RECEIVER)
  local c = i2c.read(id,3)
  i2c.stop(id)
-- unpack PRESSURE
  local UP = c:byte(1)*65536+c:byte(2)*256+c:byte(3)
  UP = UP / 2 ^ (8 - oss)
  local B6 = B5 - 4000
  local X1 = cal.B2 * (B6 * B6 / 4096) / 2048
  local X2 = cal.AC2 * B6 / 2048
  local X3 = X1 + X2
  local B3 = ((cal.AC1 * 4 + X3) * 2 ^ oss + 2) / 4
  X1 = cal.AC3 * B6 / 8192
  X2 = (cal.B1 * (B6 * B6 / 4096)) / 65536
  X3 = (X1 + X2 + 2) / 4
  local B4 = cal.AC4 * (X3 + 32768) / 32768
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
  if not init then
    print('Need to call bmp180.init(...) call before calling bmp180.read(...).')
    return
  end
  if type(oss)~="number" or oss<0 or oss>3 then oss=0 end
  M.temperature=readTemperature()
  M.pressure   =readPressure(oss)
end

return M
