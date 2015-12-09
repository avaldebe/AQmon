--[[
am2321.lua for ESP8266 with nodemcu-firmware
  Read temperature and relative humidity from AM2320/AM2321 sensors
  More info at  https://github.com/avaldebe/AQmon

Written by Álvaro Valdebenito.

MIT license, http://opensource.org/licenses/MIT
]]


local M={
  name=...,       -- module name, upvalue from require('module-name')
  temperature=nil,-- integer value of temperature [0.01 C]
  humidity   =nil -- integer value of rel.humidity[0.01 %]
}
_G[M.name]=M

local ADDR=bit.rshift(0xB8,1) -- use 7bit address

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
    i2c.stop(id)
-- verify device MODEL
    if found then
    -- request MODEL_MSB 0x08 .. MODEL_LSB 0x09
      i2c.start(id)
      i2c.address(id,ADDR,i2c.TRANSMITTER)
      i2c.write(id,0x03,0x08,0x02)
      i2c.stop(id)
      tmr.delay(1600)         -- wait at least 1.5ms
    -- read MODEL_MSB 0x08 .. MODEL_LSB 0x09
      i2c.start(id)
      i2c.address(id,ADDR,i2c.RECEIVER)
      local c=i2c.read(id,6)  -- cmd(2)+data(2)+crc(2)
      i2c.stop(id)
    -- MODEL: AM2320 2320, AM2321 2321
      found=crc_check(c)
      if found then
        local m=c:byte(3)*256+c:byte(4)
        found=(m==2321) or (m==2320) or (m==0) -- my AM2320 responds 0
      end
    end
    last=tmr.now() -- wait at least 500 ms between reads
    -- M.init suceeded
    init=found
  end

-- M.init suceeded if an AM2320/AM2321 is found on SDA,SCL
  return init
end

function M.read()
-- ensure module is initialized
  assert(init,('Need %s.init(...) before %s.read(...)'):format(M.name,M.name))
-- wait at least 500 ms between reads
--print(tmr.now()-last+500000)
  if (tmr.now()-last+500000)>0 then
    tmr.delay(tmr.now()-last+500000)
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
    M.humidity   =c:byte(3)*2560+c:byte(4)*10 -- rel.humidity[0.01 %]
    M.temperature=c:byte(5)*2560+c:byte(6)*10 -- temperature [0.01 C]
--  print((('{name}:{humidity},{temperature}'):gsub('{(.-)}',M)))
    last=tmr.now() -- wait at least 500 ms between reads
  else
    M.humidity   =nil
    M.temperature=nil
--  print((('{name}: failed crc'):gsub('{(.-)}',M)))
  end
end

return M
