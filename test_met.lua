local moduleName = ...
local M = {}
_G[moduleName] = M

M.p,M.t,M.h='NaN','NaN','NaN'

--[[ compile
  for _,f in pairs({'bmp180.lua', 'dht22.lua', 'test_met.lua'}) do
    if file.open(f) then
      print('Compiling: '..f)
      node.compile(f)
      file.remove(f)
      node.restart()
    end
  end
]]

function M.read()
  local mod,met,p,t,h

  mod = 'bmp180'
  met = require(mod)
  met.init(3,4) -- (sda,scl)
  met.read(0)   -- low power, do not oversample
  p,t = met.getPressure(),met.getTemperature()
  met = nil
  package.loaded[mod]=nil

  M.p = p and string.format('%.2f',p/100) or M.p
  M.t = p and string.format('%.1f',t/10)  or M.t
  print('bmp085 : '..M.p..'[hPa], '..M.t..'[C]')

  mod = 'dht22'
  met = require(mod)
  met.read(1)
  h,t = met.getHumidity(),met.getTemperature()
--met = nil
--package.loaded[mod]=nil

  M.h = h and string.format('%.1f',h/10) or M.h
  M.t = h and string.format('%.1f',t/10) or M.t
  print('dht22  : '..M.h..'[%], '..M.t..'[C]')

--mod = 'dht22'
--met = require(mod)
  met.read(2)
  h,t = met.getHumidity(),met.getTemperature()
  met = nil
  package.loaded[mod]=nil
  M.h = h and string.format('%.1f',h/10) or M.h
  M.t = h and string.format('%.1f',t/10) or M.t
  print('ams2321: '..M.h..'[%], '..M.t..'[C]')
end

return M