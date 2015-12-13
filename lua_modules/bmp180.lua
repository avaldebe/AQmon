--[[
bmp180.lua for ESP8266 with nodemcu-firmware
  Read temperature and preassure from BMP085/BMP180 sensors
  More info at  https://github.com/avaldebe/AQmon

Written by Álvaro Valdebenito,
  based on bmp180.lua by Javier Yanez
    https://github.com/javieryanez/nodemcu-modules
  unsigned to signed conversion, eg uint16_t (unsigned short) to int16_t (short)
    http://stackoverflow.com/questions/17152300/unsigned-to-signed-without-comparison

MIT license, http://opensource.org/licenses/MIT
]]

local M={
  name=...,       -- module name, upvalue from require('module-name')
  oss=1,          -- default pressure oversamplig: 0 .. 3
  model=nil,      -- sensor model: BMP180
  temperature=nil,-- integer value of temperature [0.01 C]
  pressure   =nil -- integer value of preassure [Pa]=[0.01 hPa]
}
_G[M.name]=M

local ADDR = 0x77 -- BMP085/BMP180 address

-- calibration coefficients
local cal={} -- AC1, AC2, AC3, AC4, AC5, AC6, B1, B2, MB, MC, MD

local function int16_t(uint,nbits)
-- first negative number uint16_t(unsigned short): 2^15
  return uint-bit.band(uint,0x8000)*2
end

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

-- M.init suceeded after/when read calibration coeff.
  init=(next(cal)~=nil)

  if not init then
    local found,c
-- verify device address
    i2c.start(id)
    found=i2c.address(id,ADDR,i2c.TRANSMITTER)
    i2c.stop(id)
-- verify device ID
    if found then
    -- request REG_CHIPID 0xD0
      i2c.start(id)
      i2c.address(id,ADDR,i2c.TRANSMITTER)
      i2c.write(id,0xD0)  -- REG_CHIPID
      i2c.stop(id)
    -- read REG_CHIPID 0xD0
      i2c.start(id)
      i2c.address(id,ADDR,i2c.RECEIVER)
      c = i2c.read(id,1)  -- CHIPID:1byte
      i2c.stop(id)
    -- CHIPID: BMP085/BMP180 0x55, BMP280 0x58, BME280 0x60
      M.model=({[0x55]='BMP180',[0x58]='BMP280',[0x60]='BME280'})[c:byte()]
      found=(M.model=='BMP180')
    end
-- read calibration coeff.
    if found then
    -- request CALIBRATION
      i2c.start(id)
      i2c.address(id,ADDR,i2c.TRANSMITTER)
      i2c.write(id,0xAA) -- REG_CALIBRATION
      i2c.stop(id)
    -- read CALIBRATION
      i2c.start(id)
      i2c.address(id,ADDR,i2c.RECEIVER)
      c = i2c.read(id,22)
      i2c.stop(id)
    -- unpack CALIBRATION
      cal.AC1=int16_t(c:byte( 1)*256+c:byte( 2))  -- (signed) short
      cal.AC2=int16_t(c:byte( 3)*256+c:byte( 4))  -- (signed) short
      cal.AC3=int16_t(c:byte( 5)*256+c:byte( 6))  -- (signed) short
      cal.AC4=        c:byte( 7)*256+c:byte( 8)   -- unsigned short
      cal.AC5=        c:byte( 9)*256+c:byte(10)   -- unsigned short
      cal.AC6=        c:byte(11)*256+c:byte(12)   -- unsigned short
      cal.B1 =int16_t(c:byte(13)*256+c:byte(14))  -- (signed) short
      cal.B2 =int16_t(c:byte(15)*256+c:byte(16))  -- (signed) short
      cal.MB =int16_t(c:byte(17)*256+c:byte(18))  -- (signed) short
      cal.MC =int16_t(c:byte(19)*256+c:byte(20))  -- (signed) short
      cal.MD =int16_t(c:byte(21)*256+c:byte(22))  -- (signed) short
    end
    -- M.init suceeded
    init=found
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
  X1 = (UT - cal.AC6)*cal.AC5/32768
  X2 = cal.MC*2048/(X1 + cal.MD)
  B5 = X1 + X2
  t = (B5 + 8)/16

-- read pressure from BMP
  if type(oss)~="number" or oss<0 or oss>3 then oss=M.oss end
  REG_COMMAND = ({0x34,0x74,0xB4 ,0xF4 })[oss+1] -- 0x34+64*oss
  WAIT        = ({4500,7500,13500,25500})[oss+1] -- 4.5,..,25.5 ms
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
  -- Note that, bit.rshift(x,n)~=x/2^n for n<0
  UP = c:byte(1)*65536+c:byte(2)*256+c:byte(3)
  UP = bit.rshift(UP,8-oss)
  B6 = B5 - 4000
  X1 = bit.rshift(B6*B6,12)*cal.B2
  X2 = B6*cal.AC2
  X3 = (X1+X2)/2048
  B3 = bit.lshift(1,oss)
  B3 = ((cal.AC1*4 + X3)*B3 + 2) / 4
  X1 = cal.AC3*B6/8192
  X2 = bit.rshift(B6*B6,12)*cal.B1/65536
  X3 = (X1 + X2 + 2) / 4
  B4 = bit.rshift((X3 + 32768)*cal.AC4,15)  -- unsigned long
  B7 = (UP - B3)*bit.rshift(50000,oss)      -- unsigned long
-- retain preccision, avoid oveflow
  if B7*2>0 then
    p = B7 * 2 / B4
  else
    p = B7 / B4 * 2
  end
  X1 = (p/256) * (p/256)
  X1 = bit.rshift(X1*3038,16)
  X2 = -7357 * p / 65536
  p = p + (X1 + X2 + 3791) / 16

-- expose results
  M.temperature = t*10  -- integer value of temp [0.01 C]
  M.pressure    = p     -- integer value of pres [0.01 hPa]
end

return M
