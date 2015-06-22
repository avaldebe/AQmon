local moduleName = ...
local M = {}
_G[moduleName] = M

M.p,M.t,M.h='NaN','NaN','NaN'
function M.tostring(tag)
  print(('  %-6s:%5s[C],%5s[%%],%7s[hPa]'):format(tag,M.t,M.h,M.p))
end

function M.read(verbose)
  local p,t,h

  require('bmp180').init(3,4) -- (sda,scl)
  bmp180.read(0)   -- low power, do not oversample
  p,t = bmp180.getPressure(),bmp180.getTemperature()
  bmp180,package.loaded.bmp180 = nil,nil -- release memory

  M.p = p and ('%.2f'):format(p/100) or M.p
  M.t = p and ('%.1f'):format(t/10)  or M.t
  if verbose then
    M.tostring('bmp085')
  end

  require('dht22').read(1)
  h,t = dht22.getHumidity(),dht22.getTemperature()
--dht22,package.loaded.dht22 = nil,nil -- release memory

  M.h = h and ('%.1f'):format(h/10) or M.h
  M.t = h and ('%.1f'):format(t/10) or M.t
  if verbose then
    M.tostring('dht22')
  end

--require('dht22').read(2)
  dht22.read(2)
  h,t = dht22.getHumidity(),dht22.getTemperature()
  dht22,package.loaded.dht22 = nil,nil -- release memory

  M.h = h and ('%.1f'):format(h/10) or M.h
  M.t = h and ('%.1f'):format(t/10) or M.t
  if verbose then
    M.tostring('am2321')
  end

  mod,p,t,h = nil,nil,nil,nil -- release memory
  return M.t,M.h,M.p
end

return M
