--[[
pms3003.lua for ESP8266 with nodemcu-firmware
  Read Particulated Matter (PM) concentrations on air from a PMS3003 sensor.
  More info at  https://github.com/avaldebe/AQmon

Written by Álvaro Valdebenito.

MIT license, http://opensource.org/licenses/MIT

Sampling:
- 1 shot/on demand.
- ~650 ms sample & decoding.
- pin3 (SET) of the PMS3003 controles operation mode.
  SET=H continious sampling, SET=L standby.

Data format:
  The PMS3003 write UART (3.3V TTL) messages 4+20 bytes long.
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

local moduleName = ...
local M = {}
_G[moduleName] = M

local pms={}
local function decode(data,verbose,stdATM)
  local i,n,msb,lsb,cksum
  cksum=0
  for i=1,#data,2 do
    n=(i-1)/2 -- index of byte pair (msb,lsb): 0..10
    msb,lsb=data:byte(i,i+1)  -- 2*char-->2*byte
    pms[n]=msb*256+lsb        -- 2*byte-->dec
    cksum=cksum+(i<#data-1 and msb+lsb or 0)
  --print(('  data#%2d byte:%3d,%3d dec:%6d cksum:%6d'):format(n,msb,lsb,pms[n],cksum))
  end
--[[
Message beggins with the byte pair 'BM' (dec 16973).
The next byte pair (pms[1]) should be dec20, folowed by 10 byte pairs (20 bytes).
]]
--assert(pms[0]==16973 and pms[1]==20 and #pms==11,'pms3003: wrongly phrased data.')
  if cksum~=pms[#pms] then
    M.pm01,M.pm25,M.pm10='null','null','null'
  elseif stdATM==true then
    M.pm01,M.pm25,M.pm10=pms[5],pms[6],pms[7]
  else -- TSI standard
    M.pm01,M.pm25,M.pm10=pms[2],pms[3],pms[4]
  end
  if verbose==true then
    print(('pms3003: %4s[ug/m3],%4s[ug/m3],%4s[ug/m3]'):format(M.pm01,M.pm25,M.pm10))
  end
end

local pinSET=nil
function M.init(pin_set,verbose,status)
  if type(pin_set)=='number' then
    pinSET=pin_set
    gpio.mode(pinSET,gpio.OUTPUT)
  end
  if verbose==true then
    print(('pms3003: data acquisition %s.\n  Console enhabled.')
      :format(type(status)=='string' and status or 'paused'))
  end
  gpio.write(pinSET,gpio.LOW)  -- low-power standby mode
  uart.on('data')
end

M.pm01,M.pm25,M.pm10='null','null','null'
function M.read(verbose,stdATM,callBack)
  local tmrus=nil
  if verbose==true then
    print('pms3003: data acquisition started.\n  Console dishabled.')
  end
  M.pm01,M.pm25,M.pm10='null','null','null'
  uart.on('data',24,function(data)
    tmr.stop(4)                 -- stop fail timer
    decode(data,verbose,stdATM)
    M.init(nil,verbose,'finished')
    if type(callBack)=='function' then callBack() end
  end,0)
  gpio.write(pinSET,gpio.HIGH)  -- continuous sampling mode
  tmr.alarm(4,1000,0,function() -- 1s after sampling started
    M.init(nil,verbose,'failed')
    if type(callBack)=='function' then callBack() end
  end)
end

return M
