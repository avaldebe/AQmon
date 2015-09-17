--[[
pms3003.lua for ESP8266 with nodemcu-firmware
  Read Particulated Matter (PM) concentrations on air from a PMS3003 sensor

Written by Álvaro Valdebenito.

MIT license, http://opensource.org/licenses/MIT
]]

local moduleName = ...
local M = {}
_G[moduleName] = M


local function raw2dec(...)
  local i,t=0,{}
  for i=1,arg.n,2 do
    t[#t+1]=tonumber(('%02X%02X'):format(arg[i],arg[i+1]),16)
  end
  return t
end

local function inspect(...)
--assert(arg.n==24,'pms3003: wrong format')
  print('pms3003 raw: '..('%02d&%03d '):rep(12):format(...))
  print('pms3003 hex: '..('"%02X%02X" '):rep(12):format(...))
  print('pms3003 dec: '..('%06d '):rep(12):format(unpack(raw2dec(...))))
end

M.pm01,M.pm25,M.pm10=nil,nil,nil
local pms={}

function M.read(verbose,stdATM)
  if #pms~=12 then
    M.pm01,M.pm25,M.pm10='null','null','null'
  elseif stdATM==true then
    M.pm01,M.pm25,M.pm10=pms[6],pms[7],pms[8]
  else -- TSI standard
    M.pm01,M.pm25,M.pm10=pms[3],pms[4],pms[5]
  end
  if verbose then
    print(('pms3003: %4s[ug/m3],%4s[ug/m3],%4s[ug/m3]'):format(M.pm01,M.pm25,M.pm10))
  end
end

function M.init(verbose)
  uart.on('data',24,function(data)
    if data:find('BM') then
      if verbose then inspect(data:byte(1,24)) end
      pms=raw2dec(data:byte(1,24))
    else
      print('...done')
      uart.on('data')
    end
  end,0)
end

return M
