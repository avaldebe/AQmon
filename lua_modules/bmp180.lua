--[[
bmp180.lua for ESP8266 with nodemcu-firmware
  Read temperature and preassure from BMP085/BMP180 sensors
  More info at  https://github.com/avaldebe/AQmon

Written by Álvaro Valdebenito,
  based on bmp180.lua by Javier Yanez
  https://github.com/javieryanez/nodemcu-modules

MIT license, http://opensource.org/licenses/MIT
]]

local M={
  name=..., -- module name, upvalue from require('module-name')
  oss=1}    -- default pressure oversamplig setting, 0:low power .. 3:oversample
_G[M.name]=M

local ADDR = 0x77 -- BMP085/BMP180 address

-- calibration coefficients
local cal={} -- AC1, AC2, AC3, AC4, AC5, AC6, B1, B2, MB, MC, MD

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

-- read calibration coeff.
  if not init then
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
    local w
--http://stackoverflow.com/questions/17152300/unsigned-to-signed-without-comparison
    w=c:byte( 1)*256+c:byte( 2);cal.AC1=w-bit.band(w,32768)*2
    w=c:byte( 3)*256+c:byte( 4);cal.AC2=w-bit.band(w,32768)*2
    w=c:byte( 5)*256+c:byte( 6);cal.AC3=w-bit.band(w,32768)*2
    w=c:byte( 7)*256+c:byte( 8);cal.AC4=w
    w=c:byte( 9)*256+c:byte(10);cal.AC5=w
    w=c:byte(11)*256+c:byte(12);cal.AC6=w
    w=c:byte(13)*256+c:byte(14);cal.B1 =w-bit.band(w,32768)*2
    w=c:byte(15)*256+c:byte(16);cal.B2 =w-bit.band(w,32768)*2
    w=c:byte(17)*256+c:byte(18);cal.MB =w-bit.band(w,32768)*2
    w=c:byte(19)*256+c:byte(20);cal.MC =w-bit.band(w,32768)*2
    w=c:byte(21)*256+c:byte(22);cal.MD =w-bit.band(w,32768)*2

  -- M.init suceeded
    init=true
  end

-- M.init suceeded after/when read calibration coeff.
  return init
end

-- read temperature and pressure from BMP
-- oss: oversampling setting. 0-3
function M.read(oss)
-- ensure module is initialized
  assert(init,('Need %s.init(...) before %s.read(...)'):format(M.name,M.name))
-- check input varables
  assert(type(oss)=='number' or oss==nil,
    ('%s.init %s argument should be %s'):format(M.name,'1st','number'))

  local REG_COMMAND,WAIT,c,UT,UP,X1,X2,X3,B3,B4,B5,B6,B7,t,p
-- read temperature from BMP
  REG_COMMAND = 0x2E
  WAIT        = 5000 -- 5 ms
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
  c = i2c.read(id,2)
  i2c.stop(id)
-- unpack TEMPERATURE
  UT = c:byte(1)*265+c:byte(2)
  X1 = (UT - cal.AC6) * cal.AC5 / 32768
  X2 = cal.MC * 2048 / (X1 + cal.MD)
  B5 = X1 + X2
  t = (B5 + 8) / 16

-- read pressure from BMP
  if type(oss)~="number" or oss<0 or oss>3 then oss=M.oss end
  REG_COMMAND = ({[0]=0x34,[1]=0x74,[2]=0xB4, [3]=0xF4 })[oss] -- 0x34+64*oss
  WAIT        = ({[0]=5000,[1]=8000,[2]=14000,[3]=26000})[oss] -- 5,..,26 ms
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
  c = i2c.read(id,3)
  i2c.stop(id)
-- unpack PRESSURE
  UP = c:byte(1)*65536+c:byte(2)*256+c:byte(3)
  UP = UP / 2^(8-oss)
  B6 = B5 - 4000
  X1 = cal.B2 * (B6 * B6 / 4096) / 2048
  X2 = cal.AC2 * B6 / 2048
  X3 = X1 + X2
  B3 = ((cal.AC1 * 4 + X3) * 2^oss + 2) / 4
  X1 = cal.AC3 * B6 / 8192
  X2 = (cal.B1 * (B6 * B6 / 4096)) / 65536
  X3 = (X1 + X2 + 2) / 4
  B4 = cal.AC4 * (X3 + 32768) / 32768
  B7 = (UP - B3) * (50000/2^oss)
--p = (B7<0x80000000) and (B7*2)/B4 or (B7/B4)*2  -- retain preccision, avoid oveflow -- node.compile() fails
  p = (B7 / B4) * 2
  X1 = (p / 256) * (p / 256)
  X1 = (X1 * 3038) / 65536
  X2 = (-7357 * p) / 65536
  p = p +(X1 + X2 + 3791) / 16

-- expose results
  M.temperature = t -- integer value of temp[C]*10
  M.pressure    = p -- integer value of pres[hPa]*100
end

return M
