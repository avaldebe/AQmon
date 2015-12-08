--[[
AQmon.lua for ESP8266 with nodemcu-firmware
  Read sensors and publish to thingspeak.com
  More info at https://github.com/avaldebe/AQmon

Written by Álvaro Valdebenito.

MIT license, http://opensource.org/licenses/MIT
]]

--[[ HW pin assignment ]]

local pin=require('keys').pin

--[[ Local functions ]]

-- LED status indicator
local status=require('rgbLED')(500,pin.ledR,pin.ledG,pin.ledB,
  {warning='320000',alert='010000',normal='000100',iddle='000001'})
status('normal')
-- low heap(?) alternative: local status=print

local api=require('keys').api
--api:sendData=require('sendData')(status)
local function speak(verbose)
  if api.last and api.last>tmr.time() then -- tmr.time overflow
    print(('time overflow: %d>%d'):format(api.last,tmr.time()))
    api.last=tmr.time()
  end
  if api.last and (tmr.time()-api.last)<5 then -- 5s since last (debounce/long press)
    print('wait 5s...')
    return
  end
  print('Read data')
  require('sensors').init(pin.sda,pin.scl,pin.PMset)
  sensors.verbose=verbose
  sensors.read(function()
    sensors.heap,sensors.upTime=node.heap(),tmr.time()
    api.path=sensors.format(sensors,'status=uptime={upTime},heap={heap}'
      ..'&field1={t}&field2={h}&field3={p}&field4={pm01}&field5={pm25}&field6={pm10}',
      true) -- remove spaces
  -- release memory
    sensors,package.loaded.sensors=nil,nil
    collectgarbage()
    api.path=('update?key={put}&{path}'):gsub('{(.-)}',api)
  --api:sendData()
    require('sendData')(api,status)
    api.last=tmr.time()
  end)
end

--[[ Run code ]]
print('Start WiFi')
require('wifi_connect')(wifi.STATION,nil) -- mode,sleep
status('iddle')

--api.freq=1 -- debug
tmr.alarm(0,10000,0,function() -- 10s after start
  if api.freq>0 then
    require('wifi_connect')(wifi.STATION,true) -- wifi sleep
    print(('Send data every %s min'):format(api.freq))
    speak(false) -- send 1st dataset & start PM sensor data collection
    tmr.alarm(0,api.freq*60000,1,function() speak(false) end)
  else
    print('Press KEY_FLASH to send NOW')
    gpio.mode(3,gpio.INT)
    gpio.trig(3,'low',function(state) speak(true) end)
  end
end)
