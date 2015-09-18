--[[
arduino_hub.lua for ESP8266 with nodemcu-firmware
  Use a 3.3V Arduino compatible module (eg 3.3V/8MHz clone) as a
  8-channel 10-bit ADC and programable sensor hub.
  Interface the Arduino module trough serial.
  More info at  https://github.com/avaldebe/AQmon

Written by Álvaro Valdebenito.

MIT license, http://opensource.org/licenses/MIT

Arduino Sketch:
  The Arduino module should be programed with all libreres required.
  More info at  https://github.com/avaldebe/AQmon
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
  assert(1/2~=0,"sensors.format uses floating point operations")
  if type(t)=='number' then M.t=('%5.1f'):format(t/10) end
  if type(h)=='number' then M.h=('%5.1f'):format(h/10) end
  if type(p)=='number' then M.p=('%7.2f'):format(p/100) end
  if type(pm01)=='number' then M.pm01=('%4d'):format(pm01) end
  if type(pm25)=='number' then M.pm25=('%4d'):format(pm25) end
  if type(pm10)=='number' then M.pm10=('%4d'):format(pm10) end

-- process message for csv/column output
  if type(message)=='string' then
    local uptime=tmr.time()
    M.upTime=('%02d:%02d:%02d:%02d'):format(uptime/864e2, -- days:
              uptime%864e2/36e2,uptime%36e2/60,uptime%60) -- hh:mm:ss
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
local SDA,SCL           -- buffer device address and pinout
local init=false
function M.init(sda,scl,lowHeap,keepVal)
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

  if verbose then
    print(M.format(payload:format('Sensed'),false))
  else
    M.format(nil,nil,t,h,p,pm01,pm25,pm10) -- only format module outputs
  end
end

return M
