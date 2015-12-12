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
local M={
  name=...,       -- module name, upvalue from require('module-name')
  persistence=nil,-- use last read set of output when/if reading fails
  verbose=nil,    -- verbose output
  temp=nil,       -- string value of temperature [C]
  rhum=nil,       -- string value of rel.humidity[%]
  pres=nil,       -- string value of preassure [hPa]
  pm01=nil,       -- string value of PM 1.0 [ug/m3]
  pm25=nil,       -- string value of PM 2.5 [ug/m3]
  pm10=nil        -- string value of PM 10. [ug/m3]
}
_G[M.name]=M

-- Format module outputs
function M.format(vars,message,squeese)
  local k,v
  local varD4={pm01='pm01',pm25='pm25',pm10='pm10'} -- %d4 format
  local varF7={temp='temp',temperature='temp',
               rhum='rhum',humidity='rhum',
               pres='pres',pressure='pres'}         -- %7.2f format

  for k,v in pairs(vars) do
-- formatted output (w/padding) from integer values
    if type(v)=='number' then
      if varD4[k]~=nil then
        k=varD4[k]
        M[k]=('%4d'):format(v)
      elseif varF7[k]~=nil then     -- x/100 --> %7.2f
        k=varF7[k]
        if (1/2)==0 then  -- no floating point operations
          M[k]=('%4d.%02d'):format(v/100,(v>=0 and v or -v)%100)
        else              -- use floating point fomatting
          M[k]=('%7.2f'):format(v)
        end
      elseif k=='upTime' then                 -- days:hh:mm:ss
        M[k]=('%02d:%02d:%02d:%02d')
            :format(v/86400,v%86400/3600,v%3600/60,v%60)
      else                                    -- heap|time|*
        M[k]=('%d'):format(v)
      end
-- formatted output (w/padding) default values ('null')
    elseif type(v)=='string' then
      if v=='' then v='null' end
      if varD4[k]~=nil then
        k=varD4[k]
        M[k]=('%4s'):format(v)
      elseif varF7[k]~=nil then
        k=varF7[k]
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
  M.format({temp='',rhum='',pres='',pm01='',pm25='',pm10=''})

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
  local payload='%s:{time}[s],{temp}[C],{rhum}[%%],{pres}[hPa],{pm01},{pm25},{pm10}[ug/m3],{heap}[b]'
  local sensor -- local "name" for sensor module

  sensor=require('bmp180')
  if sensor.init(SDA,SCL,true) then -- volatile module
    sensor.read() -- default sampling
    if M.verbose then
      sensor.heap,sensor.time=node.heap(),tmr.time()
      print(M.format(sensor,payload:format(sensor.model)))
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
      print(M.format(sensor,payload:format(sensor.model)))
    else
      M.format(sensor)
    end
  elseif M.verbose then
    print(('--Sensor "%s" not found!'):format(sensor.name))
  end
  sensor=nil -- release sensor module

  sensor=require('bme280')
  if sensor.init(SDA,SCL,true) then -- volatile module
    sensor.read() -- default sampling
    if M.verbose then
      sensor.heap,sensor.time=node.heap(),tmr.time()
      print(M.format(sensor,payload:format(sensor.model)))
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
        print(M.format(sensor,payload:format(sensor.model)))
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
