--[[
am2321.lua for ESP8266 with nodemcu-firmware
  Read temperature and relative humidity from AM2320/AM2321 sensors (tested),
  and AM2315/AM2322 sensors (untested).
  More info at  https://github.com/avaldebe/AQmon

Written by Álvaro Valdebenito,
  unsigned to signed conversion, eg uint16_t (unsigned short) to int16_t (short)
    http://stackoverflow.com/questions/17152300/unsigned-to-signed-without-comparison

MIT license, http://opensource.org/licenses/MIT
]]


local M={
  name=...,       -- module name, upvalue from require('module-name')
  model=nil,      -- sensor model: AM23xx
  temperature=nil,-- integer value of temperature [0.01 C]
  humidity   =nil -- integer value of rel.humidity[0.01 %]
}
_G[M.name]=M

local ADDR=0x5C -- 7bit address

-- consistency check
local function crc_check(c)
  local len=c:len()
  local crc=0xFFFF
  local l,i
  for l=1,len-2 do
    crc=bit.bxor(crc,c:byte(l))
    for i=1,8 do
      if bit.band(crc,1) ~= 0 then
        crc=bit.rshift(crc,1)
        crc=bit.bxor(crc,0xA001)
      else
        crc=bit.rshift(crc,1)
      end
    end
  end
  return crc==c:byte(len)*256+c:byte(len-1)
end

-- initialize i2c
local id=0
local SDA,SCL -- buffer device address and pinout
local init=false
local last    -- wait at least 500 ms between reads
function M.init(sda,scl,volatile)
-- volatile module
  if volatile==true then
    _G[M.name],package.loaded[M.name]=nil,nil -- volatile module
  end

-- buffer pin set-up
  if (sda and sda~=SDA) or (scl and scl~=SCL) then
    SDA,SCL=sda,scl
    i2c.setup(id,SDA,SCL,i2c.SLOW)
  end

-- initialization
  if not init then
-- wakeup
    i2c.start(id)
    i2c.address(id,ADDR,i2c.TRANSMITTER)
    i2c.stop(id)
-- verify device address
    i2c.start(id)
    local found=i2c.address(id,ADDR,i2c.TRANSMITTER)
    if found then
    -- request MODEL_MSB 0x08 .. MODEL_LSB 0x09
      i2c.write(id,0x03,0x08,0x02)
    end
    i2c.stop(id)
    if found then
    -- read MODEL_MSB 0x08 .. MODEL_LSB 0x09
      i2c.start(id)
      i2c.address(id,ADDR,i2c.RECEIVER)
      local c=i2c.read(id,6)  -- cmd(2)+data(2)+crc(2)
      i2c.stop(id)
    -- MODEL: AM2320 2320, AM2321 2321
      found=crc_check(c)
      if found then
        local m=c:byte(3)*256+c:byte(4)
        M.model=({[0]='AM23xx',-- my AM2320 responds 0
          [2315]='AM2315',[2320]='AM2320',[2321]='AM2321',[2322]='AM2322'})[m]
        found=(M.model~=nil)
      end
    end
    last=tmr.now() -- wait at least 500 ms between reads
    -- M.init suceeded
    init=found
  end

-- M.init suceeded if an AM23?? was found on SDA,SCL
  return init
end

function M.read(wait_ms)
-- ensure module is initialized
  assert(init,('Need %s.init(...) before %s.read(...)'):format(M.name,M.name))
-- wait_ms between reads: default 500 ms
  if type(wait_ms)~='number' then wait_ms=500 end
--print(tmr.now()-last+wait_ms*1000)
  if (tmr.now()-last+wait_ms*1000)>0 then
    tmr.delay(tmr.now()-last+wait_ms*1000)
  end
-- wakeup
  i2c.start(id)
  i2c.address(id,ADDR,i2c.TRANSMITTER)
  i2c.stop(id)
-- request HUMIDITY_MSB 0x00 .. TEMPERATURE_LSB 0x03
  i2c.start(id)
  i2c.address(id,ADDR,i2c.TRANSMITTER)
  i2c.write(id,0x03,0x00,0x04)
  i2c.stop(id)
  tmr.delay(1600)         -- wait at least 1.5ms
-- read HUMIDITY_MSB 0x00 .. TEMPERATURE_LSB 0x03
  i2c.start(id)
  i2c.address(id,ADDR,i2c.RECEIVER)
  local c=i2c.read(id,8)  -- cmd(2)+data(4)+crc(2)
  i2c.stop(id)
-- expose results
  if crc_check(c) then
    local h,t=c:byte(3)*256+c:byte(4),c:byte(5)*256+c:byte(6)
    if bit.isset(t,15) then t=-bit.band(t,0x7fff) end
    M.humidity   =h*10    -- rel.humidity[0.01 %]
    M.temperature=t*10    -- temperature [0.01 C]
    last=tmr.now()        -- wait at least 500 ms between reads
  else
    M.humidity   =nil
    M.temperature=nil
  end
end

return M
