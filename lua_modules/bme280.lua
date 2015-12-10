--[[
bme280.lua for ESP8266 with nodemcu-firmware
  Read temperature, preassure and relative humidity from BME280 sensors
  More info at  https://github.com/avaldebe/AQmon

Written by Álvaro Valdebenito,
  based on:
  - bme280.lua by WG
      https://github.com/wogum/esp12
  - BME280_driver by BoschSensortec
      https://github.com/BoschSensortec/BME280_driver
  - bme280.py by Kieran Brownlees
      https://github.com/kbrownlees/bme280
  - Adafruit_BME280.py by adafruit
      https://github.com/adafruit/Adafruit_Python_BME280
  - SparkFunBME280.cpp by sparkfun
      https://github.com/sparkfun/SparkFun_BME280_Arduino_Library

MIT license, http://opensource.org/licenses/MIT
]]

local M={
  name=...,       -- module name, upvalue from require('module-name')
  model=nil,      -- sensor model: BME280
  oss=0x01,       -- default oversamplig: 0=skip, 1=x1 .. 5=x16
  mode=0x03,      -- default sampling: 0=sleep, 1&2=forced(on demand), 3:normal(continious)
  temperature=nil,-- integer value of temperature [10*C]
  pressure   =nil,-- integer value of preassure [100*hPa]
  humidity   =nil -- integer value of relative humidity [10*%]
}
_G[M.name]=M

local ADDR = 0x77 -- BME280 address, could also be 0x76

-- calibration coefficients
local cal={} -- T1,..,T3,P1,..,P9,H1,..,H6

-- sampling configuration
local function config(...)
-- ensure module is initialized
  assert(init,('Need %s.init(...) before %s.config(...)'):format(M.name,M.name))

-- sampling: normal/continous mode (M.mode:3)
  if M.mode==0x03 then
  -- config writeable only in sleep mode
    local REG_COMMAND=0x00 -- sleep mode
    i2c.start(id)
    i2c.address(id,ADDR,i2c.TRANSMITTER)
    i2c.write(id,0xF4,REG_COMMAND)  -- REG_CONTROL_MEAS
    i2c.stop(id)
  -- Continious sampling setup (if M.mode==0x03), see DS 7.4.6.
  -- dt: sample every dt; dt=1000ms (5<<5).
  -- IIR: data=(data_new+(IIR-1)*data_old)/IIR; IIR=4 (2<<2).
  -- spi3w: enhable 3-wire SPI interface; na (0<<1).
    REG_COMMAND=0xA8 -- 5*2^5+2*2^2+0*2^1
    i2c.start(id)
    i2c.address(id,ADDR,i2c.TRANSMITTER)
    i2c.write(id,0xF5,REG_COMMAND)  -- REG_CONFIG
    i2c.stop(id)
  end

-- oversampling: all modes
  local oss_t,oss_h,oss_p=...
  if type(oss_t)~="number" or oss_t<1 or oss_t>5 then oss_t=M.oss end
  if type(oss_h)~="number" or oss_h<1 or oss_h>5 then oss_h=M.oss end
  if type(oss_p)~="number" or oss_p<1 or oss_p>5 then oss_p=M.oss end
-- H oversampling 2^(M.oss_h-1):
  local REG_COMMAND=bit.band(oss_h,0x07)
  i2c.start(id)
  i2c.address(id,ADDR,i2c.TRANSMITTER)
  i2c.write(id,0xF2,REG_COMMAND)  -- REG_CONTROL_HUM
  i2c.stop(id)
-- T oversampling 2^(M.oss_t-1), P oversampling 2^(M.oss_p-1),  mode M.mode
  REG_COMMAND=bit.band(oss_t,0x07)*32
             +bit.band(oss_p,0x07)*4
             +bit.band(M.mode,0x03)
  i2c.start(id)
  i2c.address(id,ADDR,i2c.TRANSMITTER)
  i2c.write(id,0xF4,REG_COMMAND)  -- REG_CONTROL_MEAS
  i2c.stop(id)

-- oversampling delay: forced/on-demmand mode (M.mode:1|2), see DS 11.1
  if M.mode==0x01 or M.mode==0x02 then
-- t_meas,max=1.25 [ms]+t_temp,max+t_pres,max+t_rhum,max, where
  -- t_temp,max= 2.3*2^oss_t [ms]
  -- t_pres,max= 2.3*2^oss_p + 0.575 [ms]
  -- t_rhum,max= 2.3*2^oss_h + 0.575 [ms]
-- then, t_meas,max=2.4+2.3*(2^oss_t+2^oss_h+2^oss_p) [ms]
    local WAIT=2400+2300*(bit.lshift(1,oss_t)
                         +bit.lshift(1,oss_h)
                         +bit.lshift(1,oss_p)) -- 9.3,..,112.8 ms
    tmr.delay(WAIT)
  end
end

-- initialize module
local id=0
local SDA,SCL -- buffer device pinout
local init=false
function M.init(sda,scl,volatile,...)
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
    local found,c,w
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
      c = i2c.read(id,1)  -- ID:1byte
      i2c.stop(id)
    -- CHIPID: BMP085/BMP180 0x55, BMP280 0x58, BME280 0x60
      M.model=({[0x55]='BMP180',[0x58]='BMP280',[0x60]='BME280'})[c:byte()]
      found=(M.model=='BMP280')
    end
-- read calibration coeff.
    if found then
    -- request REG_DIG_T1 .. REG_DIG_P9+1 0x9F
      i2c.start(id)
      i2c.address(id,ADDR,i2c.TRANSMITTER)
      i2c.write(id,0x88) -- REG_DIG_T1
      i2c.stop(id)
    -- read REG_DIG_T1 .. REG_DIG_P9+1 0x9F
      i2c.start(id)
      i2c.address(id,ADDR,i2c.RECEIVER)
      c = i2c.read(id,24) -- T1:2byte,..,P2:2byte
      i2c.stop(id)
    -- request REG_DIG_H1
      i2c.start(id)
      i2c.address(id,ADDR,i2c.TRANSMITTER)
      i2c.write(id,0xA1) -- REG_DIG_H1
      i2c.stop(id)
    -- read REG_DIG_H1
      i2c.start(id)
      i2c.address(id,ADDR,i2c.RECEIVER)
      c = c..i2c.read(id,1) -- H1:1byte
      i2c.stop(id)
    -- request REG_DIG_H2 0xE1 .. REG_DIG_H6 0xE7
      i2c.start(id)
      i2c.address(id,ADDR,i2c.TRANSMITTER)
      i2c.write(id,0xE1) -- REG_DIG_H2
      i2c.stop(id)
    -- read REG_DIG_H2 0xE1 .. REG_DIG_H6 0xE7
      i2c.start(id)
      i2c.address(id,ADDR,i2c.RECEIVER)
      c = c..i2c.read(id,7) -- H2:2byte,H3:1byte,H3&H4:3byte,H6:1byte
      i2c.stop(id)
    -- unpack CALIBRATION: T1,..,T3,P1,..,P9,H1,..,H7
    --http://stackoverflow.com/questions/17152300/unsigned-to-signed-without-comparison
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
      w=c:byte(31)*16+c:byte(30)/16 ;cal.H5=w
      w=c:byte(32)                  ;cal.H6=w
    end
    -- M.init suceeded
    init=found
  end

-- Sampling setup
  if init then config(...) end

-- M.init suceeded after/when read calibration coeff.
  return init
end

-- read temperature, pressure and relative humidity from BME
-- oss: oversampling setting. 0..5
function M.read(...)
-- ensure module is initialized
  assert(init,('Need %s.init(...) before %s.read(...)'):format(M.name,M.name))

-- oversampling: forced/on-demmand mode (M.mode:1|2)
  if M.mode==0x01 or M.mode==0x02 then config(...) end

-- request REG_PRESSURE_MSB 0xF7 .. REG_HUMIDITY_LSB 0xFE
  i2c.start(id)
  i2c.address(id,ADDR,i2c.TRANSMITTER)
  i2c.write(id,0xF7) -- REG_PRESSURE_MSB
  i2c.stop(id)
-- read REG_PRESSURE_MSB 0xF7 .. REG_HUMIDITY_LSB 0xFE
  i2c.start(id)
  i2c.address(id,ADDR,i2c.RECEIVER)
  local c = i2c.read(id,8) -- p:3byte,t:3byte,h:byte
  i2c.stop(id)
-- unpack RAW DATA
  local p,t,h
  p=c:byte(1)*4096+c:byte(2)*16+c:byte(3)/16  -- uncompensated pressure
  t=c:byte(4)*4096+c:byte(5)*16+c:byte(6)/16  -- uncompensated temperature
  h=c:byte(7)* 256+c:byte(8)                  -- uncompensated humidity

--[[ Temperature: Adapted from bme280_compensate_temperature_int32.
  Calculate actual temperature from uncompensated temperature.
  Returns the value in 0.01 degree Centigrade (DegC),
  an output value of "5123" equals 51.23 DegC. ]]
  local v1,v2,tfine
  t  = t/8 - cal.T1*2
  v1 = bit.rshift(t*cal.T2,11)
  v2 = bit.rshift((t/2)*(t/2),12)
  tfine = v1 + bit.rshift(v2*cal.T3,14)
  t = bit.rshift(tfine*5 + 128,8)

--[[ Pressure: Adapted from bme280_compensate_pressure_int32.
  Calculate actual pressure from uncompensated pressure.
  Returns the value in Pascal (Pa),
  and output value of "96386" equals 96386 Pa = 963.86 hPa. ]]
  v1 = tfine/2 - 64000
  v2 = bit.rshift((v1/4)*(v1/4),11)
  v2 = v2*cal.P6 + v1*cal.P5*2
  v1 = cal.P3*bit.rshift((v1/4)*(v1/4),13)/8
     + bit.rshift(cal.P2*v1/2,18) + 32768
  v1 = bit.rshift(v1*cal.P1,15)
  if v1==0 then
    p = nil
  else
    v2 = v2/4 + bit.lshift(cal.P4,16)
    v2 = bit.rshift(v2,12)
    p = (1048576 - p - v2)*3125
    if p<0x40000000 then
      p = p*2/v1
    else
      p = p/v1*2
    end
    v1 = bit.rshift((p/8)*(p/8),13)
    v1 = bit.rshift(v1*cal.P9,12)
    v2 = bit.rshift(p/4*cal.P8,13)
    p = p + (v1 + v2 + cal.P7)/16
  end

--[[ Humidity: Adapted from bme280_compensate_humidity_int32.
  Calculte actual humidity from uncompensated humidity.
  Returns the value in 0.01 %rH.
  An output value of 4132.1 represents 41.321 %rH ]]
  v1 = tfine - 76800
  v2 = bit.rshift(v1*cal.H6,10)
  v2 = v2*(bit.rshift(v1*cal.H3,11) + 32768)
  v2 =(bit.rshift(v2,10) + 2097152)*cal.H2 + 8192
  v1 = bit.lshift(h,14) - bit.lshift(cal.H4,20) - cal.H5*v1 + 16384
  v1 = bit.rshift(v1,15)*bit.rshift(v2,14)
  v2 = bit.rshift(v1,15)
  v1 = v1 - bit.rshift(v2*v2,7)*cal.H1/16
  if v1 < 0 then
    v1 = 0
  elseif v1 > 419430400 then
    v1 = 419430400
  end
  h = bit.rshift(v1,12)     -- Q22.10, ie 42313 means 42313/1024=41.321 %rH
  h = bit.rshift(h*100,10)  -- 0.01 C, ie 4132.1 means 41.321 %rH

-- expose results
  M.temperature=t -- integer value of temperature [0.01 C]
  M.pressure   =p -- integer value of preassure   [0.01 hPa]
  M.humidity   =h -- integer value of rel.humidity[0.01 %]
end

return M
