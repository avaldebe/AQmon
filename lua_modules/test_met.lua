local moduleName = ...
local M = {}
_G[moduleName] = M

M.p,M.t,M.h='NaN','NaN','NaN'
function M.tostring(tag)
  print(('%-7s: %s[C], %s[%%], %s[hPa]'):format(tag,M.t,M.h,M.p))
end

function M.read(verbose)
  local mod,p,t,h

  mod='bmp180'
  require(mod)
  _G[mod].init(3,4) -- (sda,scl)
  _G[mod].read(0)   -- low power, do not oversample
  p,t = _G[mod].getPressure(),_G[mod].getTemperature()
  _G[mod],package.loaded[mod] = nil,nil -- release memory

  M.p = p and ('%.2f'):format(p/100) or M.p
  M.t = p and ('%.1f'):format(t/10)  or M.t
  if verbose then
    M.tostring('bmp085')
  end

  mod='dht22'
  require(mod)
  _G[mod].read(1)
  h,t = _G[mod].getHumidity(),_G[mod].getTemperature()
--_G[mod],package.loaded[mod] = nil,nil -- release memory

  M.h = h and ('%.1f'):format(h/10) or M.h
  M.t = h and ('%.1f'):format(t/10) or M.t
  if verbose then
    M.tostring('dht22')
  end

--mod='dht22'
--require(mod)
  _G[mod].read(2)
  h,t = _G[mod].getHumidity(),_G[mod].getTemperature()
  _G[mod],package.loaded[mod] = nil,nil -- release memory

  M.h = h and ('%.1f'):format(h/10) or M.h
  M.t = h and ('%.1f'):format(t/10) or M.t
  if verbose then
    M.tostring('am2321')
  end
  
  mod,p,t,h = nil,nil,nil,nil -- release memory
  return M.t,M.h,M.p
end

return M
