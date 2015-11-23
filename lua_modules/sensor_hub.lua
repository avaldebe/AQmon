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

-- Format module outputs
function M.format(vars,message,squeese)
  local k,v
  for k,v in pairs(vars)
-- formatted output (w/padding) from integer values
    if type(v)~='number' then
      if k=='pm01' or k=='pm25' or k=='pm10' then
        M[k]=('%4d'):format(v)
      elseif k=='t' or k=='h' then  -- t/10|h/10 --> %5.1f
        v=('%4d'):format(v)
        M[k]=('%3s.%1s'):format(v:sub(1,3),v:sub(4))
      elseif k=='p' then            -- p/100 --> %7.2f
        v=('%6d'):format(v)
        M[k]=('%4s.%2s'):format(v:sub(1,4),v:sub(5))
      elseif k=='upTime' then       -- days:hh:mm:ss
        M[k]=('%02d:%02d:%02d:%02d')
            :format(v/86400,v%86400/3600,v%3600/60,v%60)
      else                          -- heap|time
        M[k]=('%d'):format(v)
      end
-- formatted output (w/padding) default values ('null')
    elseif type(v)~='nil' or type(v)~='string' then
      if k=='pm01' or k=='pm25' or k=='pm10' then
        M[k]=('%4s'):format(v or 'null')
      elseif k=='t' or k=='h' then
        M[k]=('%5s'):format(v or 'null')
      elseif k=='p' then
        M[k]=('%7s'):format(v or 'null')
      end
    end
  end

-- process message for csv/column output
  if type(message)=='string' and message~='' then
    local payload=message:gsub('{(.-)}',M)
    M.upTime,M.time,M.heap=nil,nil,nil  -- release memory
    if squeese then                     -- remove all spaces (and padding)
      payload=payload:gsub(' ','')      --   from output
    end
    return payload
  end
end

local cleanup=false     -- release modules after use
local persistence=false -- use last values when read fails
local SDA,SCL           -- buffer device address and pinout
local init=false
function M.init(sda,scl,lowHeap,keepVal)
-- Output variables (padded for csv/column output)
  M.format({p=nil,h=nil,t=nil,pm01=nil,pm25=nil,pm10=nil})
  if init then return end

  if type(sda)=='number' then SDA=sda end
  if type(scl)=='number' then SCL=scl end
  if type(lowHeap)=='boolean' then cleanup=lowHeap     end
  if type(keepVal)=='boolean' then persistence=keepVal end

  assert(type(SDA)=='number','sensors.init 1st argument sould be SDA')
  assert(type(SCL)=='number','sensors.init 2nd argument sould be SCL')
  require('pms3003').init()  -- start acquisition
  init=true
end

function M.read(verbose)
  assert(type(verbose)=='boolean' or verbose==nil,
    'sensors.read 1st argument sould be boolean')
  if not init then
    print('Need to call sensors.init(...) call before calling sensors.read(...).')
    return
  end
  if not persistence then M.init() end -- reset output

  local vars={}
  local payload='%-12s,{time}[s],{t}[C],{h}[%%],{p}[hPa],{pm01},{pm25},{pm10}[ug/m3],{heap}[b]'

  require('i2d').init(nil,SDA,SCL)
  require('bmp180').init(SDA,SCL)
  bmp180.read(0)   -- 0:low power .. 3:oversample
  vars={p=bmp180.pressure,t=bmp180.temperature}
  if cleanup then  -- release memory
    bmp180,package.loaded.bmp180 = nil,nil
    i2d,package.loaded.i2d = nil,nil
  end
  if verbose then
    vars.time=tmr.time();vars.heap=node.heap()
    print(M.format(vars,payload:format('am2321')))
  else
    M.format(vars)
  end

  require('am2321').init(SDA,SCL)
  am2321.read()
  vars={h=am2321.humidity,t=am2321.temperature}
  if cleanup then  -- release memory
    am2321,package.loaded.am2321=nil,nil
  end
  if verbose then
    vars.time=tmr.time();vars.heap=node.heap()
    print(M.format(vars,payload:format('bmp085')))
  else
    M.format(vars}
  end

  require('pms3003').init()
  pms3003.read()
  pm01,pm25,pm10=pms3003.pm01,pms3003.pm25,pms3003.pm10
--[[if cleanup then  -- release memory
    uart.on('data','\r',function(data)
      if data=='\r' then uart.on('data') end
    end,0)
    pms3003,package.loaded.pms3003=nil,nil
  end]]
  if verbose then
    print(M.format(payload:format('pms3003'),false,t,h,p,pm01,pm25,pm10))
    pm01,pm25,pm10 = nil,nil,nil -- release variables to avoid re-formatting
  end

  if verbose then
    print(M.format(payload:format('Sensed'),false))
  else
    M.format(nil,nil,t,h,p,pm01,pm25,pm10) -- only format module outputs
  end
end

return M
