--[[
sensor_hub.lua for ESP8266 with nodemcu-firmware
  Read atmospheric (ambient) temperature, relative humidity and pressure
  from BMP085/BMP180 and AM2320/AM2321 sensors, and particulate matter
  from a PMS3003.
  More info at  https://github.com/avaldebe/AQmon

Written by Álvaro Valdebenito.

MIT license, http://opensource.org/licenses/MIT
]]

local moduleName = ...
local M = {}
_G[moduleName] = M

-- Output variables
M.p,M.h,M.t='null','null','null' -- atm.pressure,rel.humidity,teperature
M.pm01,M.pm25,M.pm10='null','null','null' -- particulate matter (PM)

-- Format module outputs
function M.format(message,squeese,t,h,p,pm01,pm25,pm10)
-- padd initial values for csv/column output
  if M.p   =='null' then M.p   =('%7s'):format(M.p) end
  if M.h   =='null' then M.h   =('%5s'):format(M.h) end
  if M.t   =='null' then M.t   =('%5s'):format(M.t) end
  if M.pm01=='null' then M.pm01=('%4s'):format(M.pm01) end
  if M.pm25=='null' then M.pm25=('%4s'):format(M.pm25) end
  if M.pm10=='null' then M.pm10=('%4s'):format(M.pm10) end

-- formatted output (w/padding) from integer values
  if type(p)=='number' then
    M.p=('%6d'):format(p) -- p/100 --> %7.2f
    M.p=('%4s.%2s'):format(M.p:sub(1,4),M.p:sub(5))
  end
  if type(h)=='number' then
    M.h=('%4d'):format(h) -- h/10  --> %5.1f
    M.h=('%3s.%1s'):format(M.h:sub(1,3),M.h:sub(4))
  end
  if type(t)=='number' then
    M.t=('%4d'):format(t) -- t/10  --> %5.1f
    M.t=('%3s.%1s'):format(M.t:sub(1,3),M.t:sub(4))
  end
  if type(pm01)=='number' then M.pm01=('%4d'):format(pm01) end
  if type(pm25)=='number' then M.pm25=('%4d'):format(pm25) end
  if type(pm10)=='number' then M.pm10=('%4d'):format(pm10) end

-- process message for csv/column output
  if type(message)=='string' then
    local uptime=tmr.time()
    M.upTime=('%02d:%02d:%02d:%02d'):format(uptime/86400, -- days:
              uptime%86400/3600,uptime%3600/60,uptime%60) -- hh:mm:ss
    M.heap  =('%d'):format(node.heap())
    local payload=message:gsub('{(.-)}',M)
    M.upTime,M.heap,M.tag=nil,nil,nil -- release memory

    if squeese then                   -- remove all spaces (and padding)
      payload=payload:gsub(' ','')      -- from output
    end
    return payload
  end
end

local cleanup=false     -- release modules after use
local persistence=false -- use last values when read fails
local SDA,SCL,PMset      -- buffer device address and pinout
local init=false
function M.init(sda,scl,pm_set,lowHeap,keepVal)
  if type(sda)=='number' then SDA=sda end
  if type(scl)=='number' then SCL=scl end
  if type(pm_set)=='number' then PMset=pm_set end
  if type(lowHeap)=='boolean' then cleanup=lowHeap     end
  if type(keepVal)=='boolean' then persistence=keepVal end

  assert(type(SDA)=='number','sensors.init 1st argument sould be SDA')
  assert(type(SCL)=='number','sensors.init 2nd argument sould be SCL')
  assert(type(PMset)=='number','sensors.init 3rd argument sould be PMset')
  init=true
end

function M.read(verbose)
  assert(type(verbose)=='boolean' or verbose==nil,
    'sensors.read 1st argument sould be boolean')
  if not init then
    print('Need to call init(...) call before calling read(...).')
    return
  end

  local p,t,h,pm01,pm25,pm10

  if not persistence then
    M.p,M.t,M.h='null','null','null'
    M.pm01,M.pm25,M.pm10='null','null','null'
  end
  local payload='{upTime}  %-7s:{t}[C],{h}[%%],{p}[hPa],{pm01},{pm25},{pm10}[ug/m3]  heap:{heap}'

  require('i2d').init(nil,SDA,SCL)
  require('bmp180').init(SDA,SCL)
  bmp180.read(0)   -- 0:low power .. 3:oversample
  p,t = bmp180.pressure,bmp180.temperature
  if cleanup then  -- release memory
    bmp180,package.loaded.bmp180 = nil,nil
    i2d,package.loaded.i2d = nil,nil
  end
  if verbose then
    print(M.format(payload:format('bmp085'),false,t,h,p,pm01,pm25,pm10))
    p,t = nil,nil -- release variables to avoid re-formatting
  end

  require('i2d').init(nil,SDA,SCL)
  require('am2321').init(SDA,SCL)
  am2321.read()
  h,t = am2321.humidity,am2321.temperature
  if cleanup then  -- release memory
    am2321,package.loaded.am2321=nil,nil
    i2d,package.loaded.i2d = nil,nil
  end
  if verbose then
    print(M.format(payload:format('am2321'),false,t,h,p,pm01,pm25,pm10))
    h,t = nil,nil -- release variables to avoid re-formatting
  end

  require('pms3003').init(PMset)
  pms3003.read()
  tmr.alarm(2,650,0,function() -- 650 ms after read
    pm01,pm25,pm10=pms3003.pm01,pms3003.pm25,pms3003.pm10
    if cleanup then  -- release memory
      pms3003,package.loaded.pms3003=nil,nil
    end
    if verbose then
      print(M.format(payload:format('pms3003'),false,t,h,p,pm01,pm25,pm10))
      pm01,pm25,pm10 = nil,nil,nil -- release variables to avoid re-formatting
    end
    if verbose then
      print(M.format(payload:format('Sensed'),false))
    else
      M.format(nil,nil,t,h,p,pm01,pm25,pm10) -- only format module outputs
    end
  end)
end

return M
