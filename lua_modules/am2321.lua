--[[
am2321.lua for ESP8266 with nodemcu-firmware
  Read temperature and relative humidity from AM2320/AM2321 sensors (tested),
  and AM2315/AM2322 sensors (untested).
  More info at  https://github.com/avaldebe/AQmon

Written by Álvaro Valdebenito.

MIT license, http://opensource.org/licenses/MIT
]]


local M={
  name=...,       -- module name, upvalue from require('module-name')
  model=nil,      -- sensor model: AM23xx
  addr=0x5C,      -- 7bit address AM23xx
  debug=nil,      -- additional checks
  temperature=nil,-- integer value of temperature [0.01 C]
  humidity   =nil -- integer value of rel.humidity [0.01 %]
}
_G[M.name]=M

-- i2c helper functions
local reg=require('i2cd')

-- consistency check
local function crc_check(c)
  local crc=0xFFFF
  local l,i
  for l=1,#c-2 do
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
  return crc==reg.int(c:sub(#c-1,#c),'uintBE')
end

-- initialize i2c
local init=false
local last    -- wait at least 500 ms between reads
function M.init(SDA,SCL,volatile)
-- volatile module
  if volatile==true then
    _G[M.name],package.loaded[M.name]=nil,nil -- volatile module
  end

-- init i2c bus
  reg.pedantic=M.debug
  reg.init(SDA,SCL,true) -- 'i2cd' as volatile module, rely on local handle 'reg'

-- initialization
  if not init then
    -- wakeup & verify device address
    local found=reg.io(M.addr) and reg.io(M.addr)
    if found then
    -- read MODEL_MSB 0x08 .. MODEL_LSB 0x09: cmd(2)+data(2)+crc(2)
      local c=reg.io(M.addr,{0,0x03,0x08,0x02},6)
      found=crc_check(c)
      if found then
        c=reg.int(c:sub(3,4),'uintLE')
        M.model=({[0]='AM23xx', -- my AM2320 responds 0
          [2315]='AM2315',[2320]='AM2320',[2321]='AM2321',[2322]='AM2322'})[c]
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
-- wakeup & read HUMIDITY_MSB 0x00 .. TEMPERATURE_LSB 0x03: cmd(2)+data(4)+crc(2)
  local c=reg.io(M.addr) and reg.io(M.addr,{0x03,0x00,0x04},8)
-- expose results
  if crc_check(c) then
    local h,t=reg.int(c:sub(3,4),'uintLE'),reg.int(c:sub(5,6),'uintLE')
    if bit.isset(t,15) then t=-bit.band(t,0x7FFF) end
    M.humidity   =h*10    -- rel.humidity[0.01 %]
    M.temperature=t*10    -- temperature [0.01 C]
    last=tmr.now()        -- wait at least 500 ms between reads
  else
    M.humidity   =nil
    M.temperature=nil
  end
end

return M
