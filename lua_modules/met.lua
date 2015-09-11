local moduleName = ...
local M = {}
_G[moduleName] = M

-- Format module outputs
M.p,M.h,M.t='null','null','null' -- atm.pressure,rel.humidity,teperature
local function fmt(t,h,p,tag,msg)
-- padd initial values for csv/column output
  if M.p=='null' then M.p = ('%7s'):format(M.p) end
  if M.h=='null' then M.h = ('%5s'):format(M.h) end
  if M.t=='null' then M.t = ('%5s'):format(M.t) end
-- formatted output (w/padding) from integer values
  if type(p)=="number" then
    M.p = ('%7.2f'):format(p/100)
    M.t = ('%5.1f'):format(t/10)
  end
  if type(h)=="number" then
    M.h = ('%5.1f'):format(h/10)
    M.t = ('%5.1f'):format(t/10)
  end
-- process message for csv/column output
  if msg then
    local uptime=tmr.time()
    M.upTime=('%04d:%02d:%02d'):format(uptime/36e2,uptime%36e2/60,uptime%60)
    M.heap  =('%d'):format(node.heap())
    M.tag   =('%-6s'):format(tag)
    local msg=msg:gsub("{(.-)}",M)
    M.upTime,M.heap,M.tag=nil,nil,nil -- release memory
    return msg
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

function M.read(outStr,squeese,verbose)
  assert(type(outStr)=="string" or type(outStr)=="nil",
    "met.read 1st argument sould be a string")
  assert(type(squeese)=="boolean" or type(squeese)=="nil",
    "met.read 2nd argument sould be boolean")
  assert(type(verbose)=="boolean" or type(verbose)=="nil",
    "met.read 3rd argument sould be boolean")
  if not init then
    print("Need to call init(...) call before calling read(...).")
    return
  end

  local p,t,h,payload
  if not persistence then
    M.p,M.t,M.h='null','null','null'
  end
  if verbose then
    payload='{upTime}  {tag}:{t}[C],{h}[%%],{p}[hPa] heap={heap}'
  end

  require('i2d').init(nil,SDA,SCL)
  require('bmp180').init(SDA,SCL)
  bmp180.read(0)   -- 0:low power .. 3:oversample
  p,t = bmp180.pressure,bmp180.temperature
  if cleanup then  -- release memory
    bmp180,package.loaded.bmp180 = nil,nil
    i2d,package.loaded.i2d = nil,nil
  end
  if verbose then print(fmt(t,h,p,'bmp085',payload)) end

  require('i2d').init(nil,SDA,SCL)
  require('am2321').init(SDA,SCL)
  am2321.read()
  h,t = am2321.humidity,am2321.temperature
  if cleanup then  -- release memory
    am2321,package.loaded.am2321=nil,nil
    i2d,package.loaded.i2d = nil,nil
  end
  if verbose then print(fmt(t,h,p,'am2321',payload)) end

  fmt(t,h,p)          -- format module outputs
  p,t,h = nil,nil,nil -- release memory
  if verbose then
    print(fmt(t,h,p,'met',payload))
  end

  if type(outStr)=="string" then
    payload=fmt(t,h,p,'outStr',outStr)
    if squeese then
      payload=payload:gsub(' ','')
    end
    return payload
  end
end

return M
