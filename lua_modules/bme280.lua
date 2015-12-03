--[[
bme280.lua for ESP8266 with nodemcu-firmware
  Read temperature, preassure and relative humidity from BME280 sensors
  More info at  https://github.com/avaldebe/AQmon

Written by Álvaro Valdebenito,
  based on:
  - bme280.lua by WG
    https://github.com/wogum/esp12
  - bme280.py  by Kieran Brownlees
    https://github.com/kbrownlees/bme280
  -

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

local ADDR = 0x77 -- BME280 address, could also be 0x76

-- calibration coefficients
local cal={} -- T1,..,T3,P1,..,P9,H1,..,H6

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
-- device found?
    i2c.start(id)
    local found=i2c.address(id,addr,i2c.TRANSMITTER)
    i2c.stop(id)
-- read calibration coeff.
    if found then
      local c
    -- request CALIBRATION: T1,..,T3,P1,..,P9
      i2c.start(id)
      i2c.address(id,ADDR,i2c.TRANSMITTER)
      i2c.write(id,0x88) -- REG_DIG_T1
      i2c.stop(id)
    -- read CALIBRATION: T1,..,T3,P1,..,P9
      i2c.start(id)
      i2c.address(id,ADDR,i2c.RECEIVER)
      c = i2c.read(id,24) -- T1:2byte,..,P2:2byte
      i2c.stop(id)
    -- request CALIBRATION: H1
      i2c.start(id)
      i2c.address(id,ADDR,i2c.TRANSMITTER)
      i2c.write(id,0xA1) -- REG_DIG_H1
      i2c.stop(id)
    -- read CALIBRATION: H1
      i2c.start(id)
      i2c.address(id,ADDR,i2c.RECEIVER)
      c = c..i2c.read(id,1) -- H1:1byte
      i2c.stop(id)
    -- request CALIBRATION: H2,..,H7
      i2c.start(id)
      i2c.address(id,ADDR,i2c.TRANSMITTER)
      i2c.write(id,0xE1) -- REG_DIG_H2
      i2c.stop(id)
    -- read CALIBRATION: H2,..,H7
      i2c.start(id)
      i2c.address(id,ADDR,i2c.RECEIVER)
      c = c..i2c.read(id,7) -- H2:2byte,H3:1byte,..,H7:1byte
      i2c.stop(id)
    -- unpack CALIBRATION: T1,..,T3,P1,..,P9,H1,..,H7
    --http://stackoverflow.com/questions/17152300/unsigned-to-signed-without-comparison
      local w
      w=c:byte( 1)   +c:byte( 2)*256;cal.T1=w
      w=c:byte( 3)   +c:byte( 4)*256;cal.T2=w-bit.band(w,32768)*2
      w=c:byte( 5)   +c:byte( 6)*256;cal.T3=w-bit.band(w,32768)*2
      w=c:byte( 7)   +c:byte( 8)*256;cal.P1=w
      w=c:byte( 9)   +c:byte(10)*256;cal.P2=w-bit.band(w,32768)*2
      w=c:byte(11)   +c:byte(12)*256;cal.P3=w-bit.band(w,32768)*2
      w=c:byte(13)   +c:byte(14)*256;cal.P4=w-bit.band(w,32768)*2
      w=c:byte(15)   +c:byte(16)*256;cal.P5=w-bit.band(w,32768)*2
      w=c:byte(17)   +c:byte(18)*256;cal.P6=w-bit.band(w,32768)*2
      w=c:byte(19)   +c:byte(20)*256;cal.P7=w-bit.band(w,32768)*2
      w=c:byte(21)   +c:byte(22)*256;cal.P8=w-bit.band(w,32768)*2
      w=c:byte(23)   +c:byte(24)*256;cal.P9=w-bit.band(w,32768)*2
      w=c:byte(25)                  ;cal.H1=w
      w=c:byte(26)   +c:byte(27)*256;cal.H2=w-bit.band(w,32768)*2
      w=c:byte(28)                  ;cal.H3=w
      w=c:byte(29)*16+c:byte(30)%16 ;cal.H4=w
      w=c:byte(31)*16+c:byte(30)/16 ;cal.H4=w
      w=c:byte(32)                  ;cal.H6=w
    end
  end

-- M.init suceeded after/when read calibration coeff.
  return init
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
