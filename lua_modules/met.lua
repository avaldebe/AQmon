local moduleName = ...
local M = {}
_G[moduleName] = M

M.p,M.t,M.h,M.stat='null','null','null','null'
function M.tostring(tag)
  if M.stat~='null' then
    print(('  %-6s:%5s[C],%5s[%%],%7s[hPa] %s'):format(tag,M.t,M.h,M.p,M.stat))
  else
    print(('  %-6s:%5s[C],%5s[%%],%7s[hPa] heap=%d'):format(tag,M.t,M.h,M.p,node.heap()))
  end
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

  assert(type(SDA)=="number","met.init 1st argument sould be SDA")
  assert(type(SCL)=="number","met.init 2nd argument sould be SCL")
  init=true
end

function M.read(outStr,verbose,status)
  assert(type(outStr)=="string" or type(outStr)=="nil",
    "met.read 1st argument sould be a string")
  assert(type(verbose)=="boolean" or type(verbose)=="nil",
    "met.read 2nd argument sould be boolean")
  assert(type(status)=="boolean" or type(status)=="nil",
    "met.read 3rd argument sould be boolean")

  local p,t,h
  if not persistence then
    M.p,M.t,M.h,M.stat='null','null','null','null'
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
  if status then
    local uptime=tmr.time()
    M.stat=('heap=%d,uptime=%04d:%02d:%02d'):format(
      node.heap(),uptime/36e2,uptime%36e2/60,uptime%60)
    if verbose then M.tostring('Status') end
  end

  if outStr then
    return outStr:gsub("{(.-)}",M)
  end
end

return M
