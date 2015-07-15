local moduleName = ...
local M = {}
_G[moduleName] = M

M.p,M.t,M.h='null','null','null'
function M.tostring(tag)
  print(('  %-6s:%5s[C],%5s[%%],%7s[hPa] heap:%d'):format(tag,M.t,M.h,M.p,node.heap()))
end

local cleanup=false     -- release modules after use
local persistence=false -- use last values when read fails
local SDA,SCL           -- buffer device address and pinout
local init=false

function M.init(sda,scl,lowHeap,keepVal)
  if type(sda)=="number" then SDA=sda end
  if type(scl)=="number" then SCL=scl end
  if type(lowHeap)=="boolean" then cleanup=lowHeap     end
  if type(keepVal)=="boolean" then persistence=keepVal end
  init=true
end

function M.read(verbose)
  local p,t,h
  if not persistence then
    M.p,M.t,M.h='null','null','null'
  end
  if not init then
    print("Need to call init(...) call before calling read(...).")
    if verbose then M.tostring('ERROR') end
    return
  end

  require('i2d').init(nil,SDA,SCL)
  require('bmp180').init(SDA,SCL)
  bmp180.read(0)   -- 0:low power .. 3:oversample
  p,t = bmp180.pressure,bmp180.temperature
  if cleanup then  -- release memory
    bmp180,package.loaded.bmp180 = nil,nil
    i2d,package.loaded.i2d = nil,nil
  end
  M.p = p and ('%.2f'):format(p/100) or M.p
  M.t = p and ('%.1f'):format(t/10)  or M.t
  if verbose then M.tostring('bmp085') end

  require('i2d').init(nil,SDA,SCL)
  require('am2321').init(SDA,SCL)
  am2321.read()
  h,t = am2321.humidity,am2321.temperature
  if cleanup then  -- release memory
    am2321,package.loaded.am2321=nil,nil
    i2d,package.loaded.i2d = nil,nil
  end
  M.h = h and ('%.1f'):format(h/10) or M.h
  M.t = h and ('%.1f'):format(t/10) or M.t
  if verbose then M.tostring('am2321') end

  p,t,h = nil,nil,nil -- release memory
--return M.t,M.h,M.p
end

return M
