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
  - Unsigned to signed conversion, eg uint16_t (unsigned short) to int16_t (short)
      http://stackoverflow.com/questions/17152300/unsigned-to-signed-without-comparison

Note:
  bit.rshift(x,n)~=x/2^n for n<0, use bit.arshift(x,n) instead

MIT license, http://opensource.org/licenses/MIT
]]

local M={
  name=...,       -- module name, upvalue from require('module-name')
  model=nil,      -- sensor model: BME280
  verbose=nil,    -- verbose output
  debug=nil,      -- additional ckecks
  oss=0x01,       -- default oversamplig: 0=skip, 1=x1 .. 5=x16
  mode=0x03,      -- default sampling: 0=sleep, 1&2=forced(on demand), 3:normal(continious)
  temperature=nil,-- integer value of temperature [0.01 C]
  pressure   =nil,-- integer value of preassure [Pa]=[0.01 hPa]
  humidity   =nil -- integer value of rel.humidity [0.01 %]
}
_G[M.name]=M

-- BME280 has 2 possible addresses
local ADDR = {0x76,0x77}

-- calibration coefficients
local T,P,H={},{},{} -- T1,..,T3,P1,..,P9,H1,..,H6

local function int16_t(uint,nbits)
-- first negative number
  -- uint8_t (unsigned char ): 2^7
  -- uint16_t(unsigned short): 2^15
  -- uint32_t(unsigned long ): 2^31
  local first_neg=({[8]=0x80,[16]=0x8000})[nbits or 16]
  return uint-bit.band(uint,first_neg)*2
end

-- i2c helper functions
local function i2c_write(addr,...)
  local c
  i2c.start(0)
  c = i2c.address(0,addr,i2c.TRANSMITTER)
  if arg.n>0 and c then i2c.write(0,unpack(arg)) end
  i2c.stop(0)
  return c -- device found?
end
local function i2c_read(addr,reg,nbyte)
  local c = i2c_write(addr,reg)
  assert(not M.debug or c,
    ('Failed write REG=0x%02X to device ADDR=0x%02X'):format(reg,addr))
  i2c.start(0)
  i2c.address(0,addr,i2c.RECEIVER)
  c = i2c.read(0,nbyte)
  i2c.stop(0)
  assert(not M.debug or c:len()==nbyte,
    ('Failed read REG=0x%02X from device ADDR=0x%02X'):format(reg,addr))
  return c
end

-- sampling configuration
local init=false
local function config(...)
-- ensure module is initialized
  assert(init,('Need %s.init(...) before %s.config(...)'):format(M.name,M.name))

  local REG_COMMAND
-- sampling: normal/continous mode (M.mode:3)
  if M.mode==0x03 then
  -- Continious sampling setup (if M.mode==0x03), see DS 7.4.6.
  -- dt: sample every dt; dt=1000ms (5<<5).
  -- IIR: data=(data_new+(IIR-1)*data_old)/IIR; IIR=4 (2<<2).
  -- spi3w: enhable 3-wire SPI interface; na (0<<1).
    REG_COMMAND=0xA8 -- 5*2^5+2*2^2+0*2^1
  --REG_COMMAND=0xA0 -- 5*2^5+0*2^2+0*2^1 IIR disabled
  -- REG_CONFIG 0xF5 swriteable only in sleep mode, update only if needed
    local c = i2c_read(ADDR,0xF5,1)
    if REG_COMMAND~=c:byte() then
      i2c_write(ADDR,0xF4,        -- REG_CONTROL_MEAS,REG_CONFIG
                0x00,REG_COMMAND) -- sleep mode      ,config
    end
  end

-- oversampling: all modes
  local oss_t,oss_h,oss_p=...
-- H oversampling 2^(M.oss_h-1):
  i2c_write(ADDR,0xF2,  -- REG_CONTROL_HUM
            bit.band(oss_h or M.oss,0x07))
-- T oversampling 2^(M.oss_t-1), P oversampling 2^(M.oss_p-1),  mode M.mode
  i2c_write(ADDR,0xF4,  -- REG_CONTROL_MEAS
            bit.band(oss_t or M.oss,0x07)*32
           +bit.band(oss_p or M.oss,0x07)*4
           +bit.band(M.mode,0x03))

-- oversampling delay: forced/on-demmand mode (M.mode:1|2), see DS 11.1
  if M.mode==0x01 or M.mode==0x02 then
-- t_meas,max=1.25 [ms]+t_temp,max+t_pres,max+t_rhum,max, where
  -- t_temp,max= 2.3*2^oss_t [ms]
  -- t_pres,max= 2.3*2^oss_p + 0.575 [ms]
  -- t_rhum,max= 2.3*2^oss_h + 0.575 [ms]
-- then, t_meas,max=2.4+2.3*(2^oss_t+2^oss_h+2^oss_p) [ms]
    local WAIT=2400+2300*(bit.bit(oss_t or M.oss)
                         +bit.bit(oss_h or M.oss)
                         +bit.bit(oss_p or M.oss)) -- 9.3,..,112.8 ms
    tmr.delay(WAIT)
  end
end

-- initialize module
function M.init(SDA,SCL,volatile,...)
-- volatile module
  if volatile==true then
    _G[M.name],package.loaded[M.name]=nil,nil
  end

-- init i2c bus
  i2c.setup(0,SDA,SCL,i2c.SLOW)

-- M.init suceeded after/when read calibration coeff.
  init=(next(T)~=nil)and(next(P)~=nil)and(next(H)~=nil)

  if not init then
    local found,c
-- verify device address
    for c=1,#ADDR do
      found=i2c_write(ADDR[c])
      if found then
        ADDR=ADDR[c]
        break
      end
    end
    if M.verbose==true then
      print(found and
        ('%s: address 0x%02X.'):format(M.name,ADDR) or
        ('%s: unknown address.'):format(M.name) )
    end
-- verify device ID
    if found then
      c = i2c_read(ADDR,0xD0,1) -- REG_CHIPID
    -- CHIPID: BMP085/BMP180 0x55, BMP280 0x58, BME280 0x60
      M.model=({[0x55]='BMP180',[0x58]='BMP280',[0x60]='BME280'})[c:byte()]
      found=(M.model=='BME280')
    end
    if M.verbose==true then
      print(found and
        ('%s: model %q.'):format(M.name,M.model) or
        ('%s: unknown model.'):format(M.name))
    end
-- read calibration coeff.
    if found then
      c = i2c_read(ADDR,0x88,24) -- calib00 0x88 .. calib23 0x9F
        ..i2c_read(ADDR,0xA1, 1) -- calib25 0xA1
        ..i2c_read(ADDR,0xE1, 7) -- calib26 0xE1 .. calib32 0xE7
      if M.debug==true then
        print(('%s:'):format(M.name))
        local i
        for i=1,24 do
          print(('--calib%02d=0x%02X:c:byte(%02d)=0x%02X')
            :format(i-1,0x88+i-1,i,c:byte(i)))
        end
        i=25
          print(('--calib%02d=0x%02X:c:byte(%02d)=0x%02X')
            :format(i,0xA1,i,c:byte(i)))
        for i=26,32 do
          print(('--calib%02d=0x%02X:c:byte(%02d)=0x%02X')
            :format(i,0xE1+i-26,i,c:byte(i)))
        end
      end
    -- unpack CALIBRATION: T1,..,T3,P1,..,P9,H1,..,H7
      T[1]=        c:byte( 1)+c:byte( 2)*256  -- 0x88,0x89; unsigned short
      T[2]=int16_t(c:byte( 3)+c:byte( 4)*256) -- 0x8A,0x8B; (signed) short
      T[3]=int16_t(c:byte( 5)+c:byte( 6)*256) -- 0x8C,0x8D; (signed) short
      P[1]=        c:byte( 7)+c:byte( 8)*256  -- 0x8E,0x8F; unsigned short
      P[2]=int16_t(c:byte( 9)+c:byte(10)*256) -- 0x90,0x91; (signed) short
      P[3]=int16_t(c:byte(11)+c:byte(12)*256) -- 0x92,0x93; (signed) short
      P[4]=int16_t(c:byte(13)+c:byte(14)*256) -- 0x94,0x95; (signed) short
      P[5]=int16_t(c:byte(15)+c:byte(16)*256) -- 0x96,0x97; (signed) short
      P[6]=int16_t(c:byte(17)+c:byte(18)*256) -- 0x98,0x99; (signed) short
      P[7]=int16_t(c:byte(19)+c:byte(20)*256) -- 0x9A,0x9B; (signed) short
      P[8]=int16_t(c:byte(21)+c:byte(22)*256) -- 0x9C,0x9D; (signed) short
      P[9]=int16_t(c:byte(23)+c:byte(24)*256) -- 0x9E,0x9F; (signed) short
      H[1]=        c:byte(25)                 -- 0xA1     ; unsigned char
      H[2]=int16_t(c:byte(26)+c:byte(27)*256) -- 0xE1,0xE2; (signed) short
      H[3]=        c:byte(28)                 -- 0xE3     ; unsigned char
      H[4]=bit.band(c:byte(30),0x0F)          -- 0xE5[3:0],...
      H[4]=int16_t(H[4]+c:byte(29)*16)      --  ...,0xE4; (signed) short
      H[5]=bit.rshift(c:byte(30),4)           -- 0xE5[7:4],...
      H[5]=int16_t(H[5]+c:byte(31)*16)      --  ...,0xE6; (signed) short
      H[6]=int16_t(c:byte(32),8)              -- 0xE7     ; (signed) char
      c=nil
    end
    -- M.init suceeded
    init=found
  end
  if init and M.verbose==true then
    print(('%s: cal.coeff.'):format(M.name))
    print(('--T={%d,%d,%d}.'):format(unpack(T)))
    print(('--P={%d,%d,%d,%d,%d,%d,%d,%d,%d}.'):format(unpack(P)))
    print(('--H={%d,%d,%d,%d,%d,%d}.'):format(unpack(H)))
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

-- RAW DATA
  local c = i2c_read(ADDR,0xF7,8) -- REG_PRESSURE_MSB 0xF7 .. REG_HUMIDITY_LSB 0xFE
  local p,t,h                                 -- uncompensated
  p=c:byte(1)*4096+c:byte(2)*16+c:byte(3)/16  --   pressure
  t=c:byte(4)*4096+c:byte(5)*16+c:byte(6)/16  --   temperature
  h=c:byte(7)* 256+c:byte(8)                  --   humidity
  c=nil
  if M.verbose==true then
    print(('%s: UP=%d,UT=%d,UH=%d.'):format(M.name,p,t,h))
  end

--[[ Temperature: Adapted from bme280_compensate_temperature_int32.
  Calculate actual temperature from uncompensated temperature.
  Returns the value in 0.01 degree Centigrade (DegC),
  an output value of "5123" equals 51.23 DegC. ]]
  local v1,v2,v3,tfine
  v1 = t/8 - T[1]*2
  v2 = bit.arshift(v1*T[2],11)
  v3 = bit.rshift((v1/2)*(v1/2),12)
  tfine = v2 + bit.arshift(v3*T[3],14)
  t = bit.arshift(tfine*5 + 128,8)
  if M.verbose==true then
    print(('%s: tfine=%d.'):format(M.name,tfine))
  end

--[[ Pressure: Adapted from bme280_compensate_pressure_int32.
  Calculate actual pressure from uncompensated pressure.
  Returns the value in Pascal (Pa),
  and output value of "96386" equals 96386 Pa = 963.86 hPa. ]]
  v1 = tfine - 128000
  v2 = bit.rshift((v1/8)*(v1/8),12)
  v3 = bit.rshift(v2*P[3]/8 + v1*P[2],20) + 32768
  v2 = (v2*P[6] + v1*P[5])/4 + bit.lshift(P[4],16)
  v1 = bit.rshift(v3*P[1],15)
  v3 = nil
  if v1==0 then -- p/0 will lua-panic
    p = nil
  else
    p = (1048576 - p - bit.rshift(v2,12))*3125
    if p*2>0 then -- avoid overflow (signed) int32
      p = p*2/v1
    else
      p = p/v1*2
    end
    v1 = bit.rshift((p/8)*(p/8),13)
    v1 = bit.arshift(v1*P[9],12)
    v2 = bit.arshift(p*P[8],15)
    p = p + bit.arshift(v1 + v2 + P[7],4)
  end

--[[ Humidity: Adapted from bme280_compensate_humidity_int32.
  Calculte actual humidity from uncompensated humidity.
  Returns the value in 0.01 %rH.
  An output value of "4132.1" represents 41.321 %rH ]]
  v1 = tfine - 76800
  v2 = bit.rshift(v1*H[6],10)*(bit.rshift(v1*H[3],11) + 32768)
  v1 = bit.lshift(h,14) - bit.lshift(H[4],20) - H[5]*v1
  v2 = bit.rshift(v2,10) + 2097152
-- Whit this line (based on orig lib) h~=observed rel.hum./2
--v1 = bit.rshift(v1 +16384,15)*bit.rshift(v2*H[2] + 8192,14)
-- Hack, gets within 5%rH observed rel.hum.
--v1 = bit.rshift(v1 +16384,15)*bit.rshift(v2*H[2]*2+8192,14)
-- Likely fix, as the orig code dops the last bit of adc_h
  v1 = bit.rshift(v1 + 8192,14)*bit.rshift(v2*H[2] + 8192,14)
  v2 = bit.rshift(v1,15)
  v2 = bit.rshift(v2*v2,7)
  v1 = v1 - bit.rshift(v2*H[1],4)
-- v1 between 0 and 100*2^22
  if v1 < 0 then
    h = 0                   --   0 %rH
  elseif v1 > 0x19000000 then
    h = 10000               -- 100 %rH
  else
    h = bit.rshift(v1,12)   -- Q22.10, ie 42313 means 42313/1024=41.321 %rH
    h = bit.rshift(h*25,8)  -- 0.01 %, ie 4132.1 means 41.321 %rH
  end

-- expose results
  M.temperature=t -- integer value of temperature [0.01 C]
  M.pressure   =p -- integer value of preassure   [0.01 hPa]
  M.humidity   =h -- integer value of rel.humidity[0.01 %]
  if M.verbose==true then
    print(('%s: p=%d[hPa],t=%d[C],h=%d[%%].'):format(M.name,p/100,t/100,h/100))
  end
end

return M
