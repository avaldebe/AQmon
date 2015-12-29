--[[
pms3003.lua for ESP8266 with nodemcu-firmware
  Read Particulated Matter (PM) concentrations on air from a
  PMS3003 (aka G3) sensor from http://www.plantower.com/.
  It can also read from PMS1003 (aka G1), PMS2003 (aka G2),
  PMS5003 (aka G5) and PMS7003 (aka G7) sensors (untested).
  More info at  https://github.com/avaldebe/AQmon

Written by Álvaro Valdebenito.

MIT license, http://opensource.org/licenses/MIT

Sampling:
- 1 shot/on demand.
- ~650 ms sample & decoding.
- pin3 (SET) of the PMS3003 controles operation mode.
  SET=H(>2.7V; hardware default) continious sampling, SET=L(<0.8V) standby.

Data format:
  The PMS1003 write UART (3.3V TTL) messages 4+28 bytes long.
  The PMS2003 write UART (3.3V TTL) messages 4+20 bytes long.
  The PMS3003 write UART (3.3V TTL) messages 4+20 bytes long.
  The PMS5003 write UART (3.3V TTL) messages 4+28 bytes long.
  The PMS7003 write UART (3.3V TTL) messages 4+28 bytes long.
Header: 4 bytes,  2 pairs of bytes (MSB,LSB)
  bytes  1,  2: Begin message (hex:424D, ASCII 'BM')
  bytes  3,  4: Message lengh (hex:0014, decimal 20)
Body:  20 bytes, 10 pairs of bytes (MSB,LSB)
  bytes  5,  6: MSB,LSB of PM 1.0 [ug/m3] (TSI standard)
  bytes  7,  8: MSB,LSB of PM 2.5 [ug/m3] (TSI standard)
  bytes  9, 10: MSB,LSB of PM 10. [ug/m3] (TSI standard)
  bytes 11, 12: MSB,LSB of PM 1.0 [ug/m3] (std. atmosphere)
  bytes 13, 14: MSB,LSB of PM 2.5 [ug/m3] (std. atmosphere)
  bytes 15, 16: MSB,LSB of PM 10. [ug/m3] (std. atmosphere)
  bytes 17..22: no idea what they are.
  bytes 23..24: cksum=byte01+..+byte22.
]]

local M={
  name=...,   -- module name, upvalue from require('module-name')
  model=nil,  -- sensor model: PMS3003
  mlen=24,    -- lenght of PMS3003 message
  stdATM=nil, -- use standatd atm correction instead of TSI standard
  verbose=nil,-- verbose output
  debug=nil,  -- additional ckecks
  pm01=nil,   -- integer value of PM 1.0 [ug/m3]
  pm25=nil,   -- integer value of PM 2.5 [ug/m3]
  pm10=nil    -- integer value of PM 10. [ug/m3]
}
_G[M.name]=M

local function decode(data)
  -- data beggins with the byte pair 'BM' (dec 16973).
  -- The next byte pair (pms[1]) should be dec20,
  -- folowed by 10 byte pairs (20 bytes).
-- check message lenght
  assert(not M.debug or #data==M.mlen,('%s: incomplete message.'):format(M.name))
  local pms,cksum,mlen={},0,#data/2-1
  local n,msb,lsb
  for n=0,mlen do
    msb,lsb=data:byte(2*n+1,2*n+2)  -- 2*char-->2*byte
    pms[n]=msb*256+lsb               -- 2*byte-->dec
    cksum=cksum+(n<mlen and msb+lsb or 0)
    if M.debug==true then
      print(('  data#%2d byte:%3d,%3d dec:%6d cksum:%6d'):
        format(n,msb,lsb,pms[n],cksum))
    end
  end
  assert(not M.debug or (pms[0]==16973 and pms[1]==20 and #pms==mlen),
    ('%s: wrongly phrased message.'):format(M.name))
  if cksum==pms[#pms] and M.stdATM~=true then
    M.pm01,M.pm25,M.pm10=pms[2],pms[3],pms[4] -- TSI standard
  elseif cksum==pms[#pms] then
    M.pm01,M.pm25,M.pm10=pms[5],pms[6],pms[7] -- stdATM
  else
    M.pm01,M.pm25,M.pm10=nil,nil,nil          -- cksum~=pms[#pms]
  end
  if M.verbose==true then
    print(('%s: %4s,%4s,%4s [ug/m3]')
      :format(M.name,M.pm01 or 'null',M.pm25 or 'null',M.pm10 or 'null'))
  end
end

local pinSET=nil
local init=false
function M.init(pin_set,volatile,status)
-- volatile module
  if volatile==true then
    _G[M.name],package.loaded[M.name]=nil,nil
  end

-- buffer pin set-up
  if type(pin_set)=='number' then
    pinSET=pin_set
    gpio.mode(pinSET,gpio.OUTPUT)
    M.model=({[32]='PMS1003',[24]='PMS3003'})[M.mlen]
  end

-- initialization
  if type(pinSET)=='number' then
    uart.on('data',0,function(data) end,0)  -- flush the uart buffer
    gpio.write(pinSET,gpio.LOW)             -- low-power standby mode
    if M.verbose==true then
      print(('%s: data acquisition %s.\n  Console %s.')
        :format(M.name,type(status)=='string' and status or 'paused','enhabled'))
    end
    uart.on('data')                         -- release uart
  end

-- M.init suceeded if sensor model is set
  init=(M.model~=nil)
  return init
end

function M.read(callBack)
-- ensure module is initialized
  assert(init,('Need %s.init(...) before %s.read(...)'):format(M.name,M.name))
-- check input varables
  assert(type(callBack)=='function' or callBack==nil,
    ('%s.init %s argument should be %s'):format(M.name,'1st','function'))

-- capture and decode message
  uart.on('data',M.mlen*2,function(data)
    local bm=data:find("BM")
    if bm then
  -- stop sampling time-out timer
      tmr.stop(4)
  -- decode message
      decode(data:sub(bm,M.mlen+bm-1))
  -- restore UART & callBack
      M.init(nil,nil,'finished')
      if type(callBack)=='function' then callBack() end
    end
  end,0)

-- start sampling: continuous sampling mode
  if M.verbose==true then
    print(('%s: data acquisition %s.\n  Console %s.')
      :format(M.name,'started','dishabled'))
  end
  gpio.write(pinSET,gpio.HIGH)

-- sampling time-out: 2s after sampling started
  tmr.alarm(4,2000,0,function()
    M.pm01,M.pm25,M.pm10=nil,nil,nil
  -- restore UART & callBack
    M.init(nil,nil,'failed')
    if type(callBack)=='function' then callBack() end
  end)
end

return M
