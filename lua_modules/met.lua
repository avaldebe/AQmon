local moduleName = ...
local M = {}
_G[moduleName] = M

M.p,M.t,M.h='null','null','null'
function M.tostring(tag)
  print(('  %-6s:%5s[C],%5s[%%],%7s[hPa] heap:%d'):format(tag,M.t,M.h,M.p,node.heap()))
end

local persistence=false -- use last values when read fails
local cleanup=false     -- release modules after use
function M.read(verbose)
  local p,t,h
  local sda,scl
  if not persistence then
    M.p,M.t,M.h='null','null','null'
  end

  sda,scl=3,4
  require('i2d').init(nil,sda,scl)
  require('bmp180').init()
  bmp180.read(0)   -- 0:low power .. 3:oversample
  p,t = bmp180.pressure,bmp180.temperature
  if cleanup then  -- release memory
    bmp180,package.loaded.bmp180 = nil,nil
    i2d,package.loaded.i2d = nil,nil
  end
  M.p = p and ('%.2f'):format(p/100) or M.p
  M.t = p and ('%.1f'):format(t/10)  or M.t
  if verbose then
    M.tostring('bmp085')
  end

  sda,scl=2,1
  require('i2d').init(nil,sda,scl)
  require('am2321').init()
  am2321.read()
  h,t = am2321.humidity,am2321.temperature
  if cleanup then  -- release memory
    am2321,package.loaded.am2321=nil,nil
    i2d,package.loaded.i2d = nil,nil
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
