--[[
sensor_hub.lua for ESP8266 with nodemcu-firmware
  Read atmospheric (ambient) temperature, relative humidity and pressure
  from BMP085/BMP180 and AM2320/AM2321 sensors, and particulate matter
  from a PMS3003.
  More info at  https://github.com/avaldebe/AQmon

Written by Álvaro Valdebenito.

MIT license, http://opensource.org/licenses/MIT
]]

-- persistence: use last values when read fails
local M = {name=...,persistence=nil,verbose=nil}
_G[M.name] = M
-- M.persistence: use last read set of output when/if reading fails
-- M.verbose: verbose output

-- Format module outputs
function M.format(vars,message,squeese)
  local k,v
  for k,v in pairs(vars) do
-- formatted output (w/padding) from integer values
    if type(v)=='number' then
      if k=='pm01' or k=='pm25' or k=='pm10' then
        M[k]=('%4d'):format(v)
      elseif k=='t' or k=='temperature' then  -- t/10 --> %5.1f
        v=('%4d'):format(v)
        M.t=('%3s.%1s'):format(v:sub(1,3),v:sub(4))
      elseif k=='h' or k=='humidity' then     -- h/10 --> %5.1f
        v=('%4d'):format(v)
        M.h=('%3s.%1s'):format(v:sub(1,3),v:sub(4))
      elseif k=='p' or k=='pressure' then      -- p/100 --> %7.2f
        v=('%6d'):format(v)
        M.p=('%4s.%2s'):format(v:sub(1,4),v:sub(5))
      elseif k=='upTime' then                 -- days:hh:mm:ss
        M[k]=('%02d:%02d:%02d:%02d')
            :format(v/86400,v%86400/3600,v%3600/60,v%60)
      else                                    -- heap|time|*
        M[k]=('%d'):format(v)
      end
-- formatted output (w/padding) default values ('null')
    elseif type(v)=='string' then
      if v=='' then v='null' end
      if k=='pm01' or k=='pm25' or k=='pm10' then
        M[k]=('%4s'):format(v)
      elseif k=='t' or k=='h' then
        M[k]=('%5s'):format(v)
      elseif k=='p' then
        M[k]=('%7s'):format(v)
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

local SDA,SCL,PMset     -- buffer pinout
local init=false
function M.init(sda,scl,pm_set,volatile)
-- volatile module
  if volatile==true then
    _G[M.name],package.loaded[M.name]=nil,nil
  end

-- Output variables (padded for csv/column output)
  M.format({p='',h='',t='',pm01='',pm25='',pm10=''})

-- buffer pin set-up
  if type(sda)=='number' then SDA=sda end
  if type(scl)=='number' then SCL=scl end
  if type(pm_set)=='number' then PMset=pm_set end

-- initialization
  assert(type(SDA)=='number',
    ('%s.init %s argument sould be %s'):format(M.name,'1st','SDA'))
  assert(type(SCL)=='number',
    ('%s.init %s argument sould be %s'):format(M.name,'2nd','SCL'))
  assert(type(PMset)=='number' or PMset==nil,
    ('%s.init %s argument sould be %s'):format(M.name,'3rd','PMset'))
  require('pms3003').init(PMset,true) -- volatile module

-- M.init suceeded
  init=true
  return init
end

function M.read(callBack)
-- ensure module is initialized
  assert(init,('Need %s.init(...) before %s.read(...)'):format(M.name,M.name))
-- check input varables
  assert(type(callBack)=='function' or callBack==nil,
    ('%s.init %s argument should be %s'):format(M.name,'1st','function'))

-- reset output
  if not M.persistence then M.init() end
-- verbose print: csv/column output
  local payload='%s:{time}[s],{t}[C],{h}[%%],{p}[hPa],{pm01},{pm25},{pm10}[ug/m3],{heap}[b]'
  local sensor -- local "name" for sensor module

  sensor=require('bmp180')
  if sensor.init(SDA,SCL,true) then -- volatile module
    sensor.read(0)   -- 0:low power .. 3:oversample
    if M.verbose then
      sensor.heap,sensor.time=node.heap(),tmr.time()
      print(M.format(sensor,payload:format(sensor.name)))
    else
      M.format(sensor)
    end
  elseif M.verbose then
    print(('--Sensor "%s" not found!'):format(sensor.name))
  end
  sensor=nil -- release sensor module

  sensor=require('am2321')
  if sensor.init(SDA,SCL,true) then -- volatile module
    sensor.read()
    if M.verbose then
      sensor.heap,sensor.time=node.heap(),tmr.time()
      print(M.format(sensor,payload:format(sensor.name)))
    else
      M.format(sensor)
    end
  elseif M.verbose then
    print(('--Sensor "%s" not found!'):format(sensor.name))
  end
  sensor=nil -- release sensor module

  sensor=require('pms3003')
  if sensor.init(PMset,true) then -- volatile module
    sensor.read(function()
      if M.verbose then
        sensor.heap,sensor.time=node.heap(),tmr.time()
        print(M.format(sensor,payload:format(sensor.name)))
      else
        M.format(sensor)
      end
      sensor=nil -- release sensor module
      if type(callBack)=='function' then callBack() end
    end)
  elseif M.verbose then
    print(('--Sensor "%s" not found!'):format(sensor.name))
    sensor=nil -- release sensor module
    if type(callBack)=='function' then callBack() end
  end
end

return M
