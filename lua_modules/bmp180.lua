-- ***************************************************************************
-- BMP180 module for ESP8266 with nodeMCU
-- BMP085 compatible but not tested
--
-- Written by Javier Yanez
--
-- MIT license, http://opensource.org/licenses/MIT
-- ***************************************************************************

local moduleName = ...
local M = {}
_G[moduleName] = M

local ADDR = 0x77 --BMP180 address
local REG_CALIBRATION = 0xAA
local REG_CONTROL = 0xF4
local REG_RESULT = 0xF6

local COMMAND_TEMPERATURE = 0x2E
local COMMAND_PRESSURE = {[0]=0x34,[1]=0x74,[2]=0xB4,[3]=0xF4}
local WAIT_TEMPERATURE = 5000 -- 5ms
local WAIT_PRESSURE = {[0]=5000,[1]=8000,[2]=14000,[3]=26000}


-- calibration coefficients
local AC1, AC2, AC3, AC4, AC5, AC6, B1, B2, MB, MC, MD

-- temperature and pressure
local t,p

local init = false

-- i2c interface ID
local id = 0


-- 2 bits to signed/unsigned int
local function byte2int(MSB,LSB,signed)
  local w=MSB*256+LSB
  return signed and (w>32767) and (w-65536) or w
end

-- 3 bits to unsigned long
local function byte3int(MSB,LSB,XLSB)
  return MSB*65536+LSB*256+XLSB
end

-- initialize module
-- sda: SDA pin
-- scl SCL pin
function M.init(da,cl)
  local sda,scl=da,cl
  i2c.setup(id, sda, scl, i2c.SLOW)
-- request CALIBRATION
  i2c.start(id)
  i2c.address(id,ADDR,i2c.TRANSMITTER)
  i2c.write(id,REG_CALIBRATION)
  i2c.stop(id)
-- read CALIBRATION
  i2c.start(id)
  i2c.address(id,ADDR,i2c.RECEIVER)
  local c = i2c.read(id,22)
  i2c.stop(id)
-- unpack TEMPERATURE
  AC1= byte2int(c:byte( 1),c:byte( 2),true)
  AC2= byte2int(c:byte( 3),c:byte( 4),true)
  AC3= byte2int(c:byte( 5),c:byte( 6),true)
  AC4= byte2int(c:byte( 7),c:byte( 8))
  AC5= byte2int(c:byte( 9),c:byte(10))
  AC6= byte2int(c:byte(11),c:byte(12))
  B1 = byte2int(c:byte(13),c:byte(14),true)
  B2 = byte2int(c:byte(15),c:byte(16),true)
  MB = byte2int(c:byte(17),c:byte(18),true)
  MC = byte2int(c:byte(19),c:byte(20),true)
  MD = byte2int(c:byte(21),c:byte(22),true)

  init = true
end

-- read temperature from BMP180
local function read_temp()
-- request TEMPERATURE
  i2c.start(id)
  i2c.address(id,ADDR,i2c.TRANSMITTER)
  i2c.write(id,REG_CONTROL,COMMAND_TEMPERATURE)
  i2c.stop(id)
  tmr.delay(WAIT_TEMPERATURE)
-- request RESULT
  i2c.start(id)
  i2c.address(id,ADDR,i2c.TRANSMITTER)
  i2c.write(id,REG_RESULT)
  i2c.stop(id)
-- read RESULT
  i2c.start(id)
  i2c.address(id,ADDR,i2c.RECEIVER)
  local c = i2c.read(id,2)
  i2c.stop(id)
-- unpack TEMPERATURE
  local UT = byte2int(c:byte(1,2))
  local X1 = (UT - AC6) * AC5 / 32768
  local X2 = MC * 2048 / (X1 + MD)
  B5 = X1 + X2
  t = (B5 + 8) / 16
  return t
end

-- read pressure from BMP180
-- must be read after read temperature
local function read_pressure(oss)
-- request PRESSURE
  i2c.start(id)
  i2c.address(id,ADDR,i2c.TRANSMITTER)
  i2c.write(id,REG_CONTROL,COMMAND_PRESSURE[oss])
  i2c.stop(id)
  tmr.delay(WAIT_PRESSURE[oss])
-- request RESULT
  i2c.start(id)
  i2c.address(id,ADDR,i2c.TRANSMITTER)
  i2c.write(id,REG_RESULT)
  i2c.stop(id)
-- read RESULT
  i2c.start(id)
  i2c.address(id,ADDR,i2c.RECEIVER)
  local c = i2c.read(id,3)
  i2c.stop(id)
-- unpack PRESSURE
  local UP = byte3int(c:byte(1,3))
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
  p = (B7 / B4) * 2
  X1 = (p / 256) * (p / 256)
  X1 = (X1 * 3038) / 65536
  X2 = (-7357 * p) / 65536
  p = p +(X1 + X2 + 3791) / 16
  return (p)
end

-- read temperature and pressure from BMP180
-- oss: oversampling setting. 0-3
function M.read(oss)
  if (oss == nil) then
     oss = 0
  end
  if (not init) then
     print("init() must be called before read.")
  else
     read_temp()
     read_pressure(oss)
  end
end;

-- get temperature
function M.getTemperature()
  return t
end

-- get pressure
function M.getPressure()
  return p
end

return M
