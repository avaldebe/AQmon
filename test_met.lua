--[[ compile
  for _,f in pairs({'bmp180.lua', 'dht22.lua', 'test_met.lua'}) do
    if file.open(f) then
      print('Compiling: '..f)
      node.compile(f)
      file.remove(f)
      node.restart()
    end
  end
  package.loaded['test_met']=nil
]]

local moduleName = ...
local M = {}
_G[moduleName] = M

M.p,M.t,M.h='NaN','NaN','NaN'

function M.read()
  local mod,met,p,t,h

  mod = 'bmp180'
  met = require(mod)
  met.init(3,4) -- (sda,scl)
  met.read(0)   -- low power, do not oversample
  p,t = met.getPressure(),met.getTemperature()
  met = nil
  package.loaded[mod]=nil

  M.p = p and ('%.2f'):format(p/100) or M.p
  M.t = p and ('%.1f'):format(t/10)  or M.t
  print(('%-7s: %s[C], %s[%%], %s[hPa]'):format('bmp085',M.t,M.h,M.p))

  mod = 'dht22'
  met = require(mod)
  met.read(1)
  h,t = met.getHumidity(),met.getTemperature()
--met = nil
--package.loaded[mod]=nil

  M.h = h and ('%.1f'):format(h/10) or M.h
  M.t = h and ('%.1f'):format(t/10) or M.t
  print(('%-7s: %s[C], %s[%%], %s[hPa]'):format('dht22',M.t,M.h,M.p))

--mod = 'dht22'
--met = require(mod)
  met.read(2)
  h,t = met.getHumidity(),met.getTemperature()
  met = nil
  package.loaded[mod]=nil
  M.h = h and ('%.1f'):format(h/10) or M.h
  M.t = h and ('%.1f'):format(t/10) or M.t
  print(('%-7s: %s[C], %s[%%], %s[hPa]'):format('am2321',M.t,M.h,M.p))
end

return M
