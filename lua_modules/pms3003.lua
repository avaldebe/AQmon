--[[
pms3003.lua for ESP8266 with nodemcu-firmware
  Read Particulated Matter (PM) concentrations on air from a PMS3003 sensor
  More info at  https://github.com/avaldebe/AQmon

Written by Álvaro Valdebenito.

MIT license, http://opensource.org/licenses/MIT

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
  bytes 17..24: no idea what they are.
]]

local moduleName = ...
local M = {}
_G[moduleName] = M

local pms={}
local function decode(data,verbose)
  local i,n,msb,lsb
  for i=1,#data,2 do
    n=(i-1)/2 -- index of byte pair (msb,lsb): 0..10
    msb,lsb=data:byte(i,i+1)                          -- 2*char-->2*byte
    pms[n]=tonumber(('%02X%02X'):format(msb,lsb),16)  -- 2*byte-->hex-->dec
    if verbose==true then
      print(('  data#%2d byte:%3d..%03d hex:%2X%02X dec:%6d'):format(n,
        msb,lsb,msb,lsb,pms[n]))
    end
  end
--[[
We use the byte pair 'BM' (dec 16973) as end message
instead of Begin Mesage. The 1st byte pair (pms[0]) after 'BM'
should be dec20, folowed by 10 byte pairs (20 bytes).
]]
--assert(pms[0]==20 and #pms==10,'pms3003: wrongly phrased data.')
  if pms[0]~=20 or #pms~=10 then pms={} end
end

M.pm01,M.pm25,M.pm10=nil,nil,nil
function M.read(verbose,stdATM)
  if #pms~=10 then
    M.pm01,M.pm25,M.pm10='null','null','null'
  elseif stdATM==true then
    M.pm01,M.pm25,M.pm10=pms[4],pms[5],pms[5]
  else -- TSI standard
    M.pm01,M.pm25,M.pm10=pms[1],pms[2],pms[3]
  end
  if verbose==true then
    print(('pms3003: %4s[ug/m3],%4s[ug/m3],%4s[ug/m3]'):format(M.pm01,M.pm25,M.pm10))
  end
end

local init=nil
function M.init(verbose)
  if init then return end
  if verbose==true then
    print('pms3003: start acquisition. Type stopM+ENTER twice to stop.')
  end
  uart.on('data','M',function(data)
    local msg=data:match('(......................)BM$')
    if msg then
      decode(msg,verbose)
    elseif data:find('stop') then
      if verbose==true then
        print('pms3003: stop acquisition.')
      end
      uart.on('data')
      init=nil
    end
  end,0)
end

return M
