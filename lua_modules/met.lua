local moduleName = ...
local M = {}
_G[moduleName] = M

M.p,M.t,M.h='null','null','null'
function M.tostring(tag)
  print(('  %-6s:%5s[C],%5s[%%],%7s[hPa] heap:%d'):format(tag,M.t,M.h,M.p,node.heap()))
end

local persistence=false -- use last values when read fails
function M.read(verbose)
  local p,t,h
  local sda,scl
  if not persistence then
    M.p,M.t,M.h='null','null','null'
  end

  sda,scl=3,4
  require('bmp180').init(sda,scl)
  bmp180.read(0)   -- low power, do not oversample
  p,t = bmp180.getPressure(),bmp180.getTemperature()
  bmp180,package.loaded.bmp180 = nil,nil -- release memory

  M.p = p and ('%.2f'):format(p/100) or M.p
  M.t = p and ('%.1f'):format(t/10)  or M.t
  if verbose then
    M.tostring('bmp085')
  end

  sda,scl=2,1
  gpio.mode(scl,gpio.INPUT)
  if gpio.read(scl)==0 then
--  print('am2321:dht')
    require('dht22').read(sda)
    h,t = dht22.getHumidity(),dht22.getTemperature()
    dht22,package.loaded.dht22 = nil,nil -- release memory
  else
--  print('am2321:i2c')
    require('am2321').init(sda,scl)
    am2321.read()
    h,t = am2321.getHumidity(),am2321.getTemperature()
    am2321,package.loaded.am2321=nil,nil -- release memory
  end

  M.h = h and ('%.1f'):format(h/10) or M.h
  M.t = h and ('%.1f'):format(t/10) or M.t
  if verbose then
    M.tostring('am2321')
  end

  p,t,h = nil,nil,nil -- release memory
  return M.t,M.h,M.p
end

return M
