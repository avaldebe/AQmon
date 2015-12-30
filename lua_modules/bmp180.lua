--[[
bmp180.lua for ESP8266 with nodemcu-firmware
  Read temperature and preassure from BMP085/BMP180 sensors
  More info at  https://github.com/avaldebe/AQmon

Written by Álvaro Valdebenito,
  based on bmp180.lua by Javier Yanez
    https://github.com/javieryanez/nodemcu-modules

Note:
  bit.rshift(x,n)~=x/2^n for n<0, use bit.arshift(x,n) instead

MIT license, http://opensource.org/licenses/MIT
]]

local M={
  name=...,       -- module name, upvalue from require('module-name')
  model=nil,      -- sensor model: BMP180
  addr=0x77,      -- 7bit address BMP085/BMP180
  verbose=nil,    -- verbose output
  debug=nil,      -- additional checks
  oss=1,          -- default pressure oversamplig: 0 .. 3
  temperature=nil,-- integer value of temperature [0.01 C]
  pressure   =nil -- integer value of preassure [Pa]=[0.01 hPa]
}
_G[M.name]=M

-- i2c helper functions
local reg=require('i2cd')

-- calibration coefficients
local AC,B,M={},{},{} -- AC1..AC6, B1, B2, MB, MC, MD

-- initialize module
local init=false
function M.init(SDA,SCL,volatile)
-- volatile module
   if volatile==true then
    _G[M.name],package.loaded[M.name]=nil,nil
  end

-- init i2c bus
  reg.pedantic=M.debug
  reg.init(SDA,SCL,true) -- 'i2cd' as volatile module, rely on local handle 'reg'

-- M.init suceeded after/when read calibration coeff.
  init=(next(cal)~=nil)

  if not init then
    local found,c
-- verify device address
    found=reg.io(M.addr)
-- verify device ID
    if found then
    -- read REG_CHIPID 0xD0: 1 byte
      c = reg.io(M.addr,{0xD0},1):byte()
    -- CHIPID: BMP085/BMP180 0x55, BMP280 0x58, BME280 0x60
      M.model=({[0x55]='BMP180',[0x58]='BMP280',[0x60]='BME280'})[c]
      found=(M.model=='BMP180')
    end
-- read calibration coeff.
    if found then
    -- read CALIBRATION 0xAA .. 0xBF: 22 byte
      c = reg.io(M.addr,{0xAA},22)
    -- unpack CALIBRATION
      AC[1]=reg.int(c:sub( 1, 2),'sintLE')  -- 0xAA,0xAB; (signed) short
      AC[2]=reg.int(c:sub( 3, 4),'sintLE')  -- 0xAC,0xAD; (signed) short
      AC[3]=reg.int(c:sub( 5, 6),'sintLE')  -- 0xAE,0xAF; (signed) short
      AC[4]=reg.int(c:sub( 7, 8),'uintLE')  -- 0xB0,0xB1; unsigned short
      AC[5]=reg.int(c:sub( 9,10),'uintLE')  -- 0xB2,0xB3; unsigned short
      AC[6]=reg.int(c:sub(11,12),'uintLE')  -- 0xB4,0xB5; unsigned short
      B[1] =reg.int(c:sub(13,14),'sintLE')  -- 0xB6,0xB7; (signed) short
      B[2] =reg.int(c:sub(15,16),'sintLE')  -- 0xB8,0xB9; (signed) short
      M.B  =reg.int(c:sub(17,18),'sintLE')  -- 0xBA,0xBB; (signed) short
      M.C  =reg.int(c:sub(19,20),'sintLE')  -- 0xBC,0xBD; (signed) short
      M.D  =reg.int(c:sub(21,22),'sintLE')  -- 0xBE,0xBF; (signed) short
      if M.verbose==true then
        print(('%s: cal.coeff.'):format(M.name))
        print(('--AC={%d,%d,%d,%d,%d,%d}'):format(unpack(AC)))
        print(('--B={%d,%d}'):format(unpack(B))
        print(('--M={B=%d,C=%d,D=%d}'):format(M.B,M.C,M.D))
      end
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

  local c,t,p,X1,X2,B3,B4,B5
-- read temperature from BMP
  reg.io(M.addr,{0xF4,0x2E})        -- write REG_CONTROL
  tmr.delay(4500)                   -- wait for conversion: 4.5 ms
  c = reg.read(M.addr,{0xF6},2)     -- read REG_RESULT: 2 byte
-- unpack TEMPERATURE
  t = reg.int(c,'uintLE')
  if M.verbose==true then
    print(('%s=%d; 0xF6..0xF7=0x%02X%02X')
      :format('UT',t,c:byte(1),c:byte(2)))
  end
  B5 = bit.arshift((t - AC[6])*AC[5],15) + bit.lshift(M.C,11)/(X1 + M.D)
  t = reg.int((B5 + 8)/16,'short')  -- (signed) short
  if M.verbose==true then print('t,B5:',t,B5) end

-- read pressure from BMP
  if type(oss)~="number" or oss<0 or oss>3 then oss=M.oss end
  reg.io(M.addr,{0xF4,0x34+64*oss}) -- write REG_CONTROL
  tmr.delay(1500+3000*bit.bit(oss)) -- wait for conversion: 4.5 .. 25.5 ms
  c = reg.read(M.addr,{0xF6},3)     -- read REG_RESULT: 3 byte
-- unpack PRESSURE
  p = reg.int(c,'uintLE')
  p = bit.rshift(p,8-oss)
  if M.verbose==true then
    print(('%s=%d; 0xF6..0xF8=0x%02X%02X%02X')
      :format('UP',p,c:byte(1),c:byte(2),c:byte(3)))
  end
  B5 = B5 - 4000
  X1 = bit.rshift(B5*B5,12)
  X2 = bit.arshift(X1*B[2],11) + bit.arshift(B5*AC[2],11)
  X2 = ((AC[1]*4 + X2)*bit.bit(oss) + 2)/4
  B3 = (p - X2)*bit.rshift(50000,oss) -- unsigned long
  X2 = bit.arshift(X1*B[1],16) + bit.arshift(B5*AC[3],13)
  X2 = (X2 + 2)/4 + 32768
  B4 = bit.rshift(X2*AC[4],15)        -- unsigned long
  p=B3*2>0 and B3*2/B4 or p=B3/B4*2   -- avoid overflow (signed) int32
  if M.verbose==true then print('p,B3,B4:',p,B3,B4) end
  X1 = bit.rshift((p/256)*(p/256)*3038,16)
  X2 = bit.rshift(7357*p,16)
  p = p + (X1 - X2 + 3791)/16
  if M.verbose==true then print('p,X1,X2:',p,X1,X2) end

-- expose results
  M.temperature = t*10  -- integer value of temp [0.01 C]
  M.pressure    = p     -- integer value of pres [0.01 hPa]
end

return M
