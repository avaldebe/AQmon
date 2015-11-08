--[[
AQmon.lua for ESP8266 with nodemcu-firmware
  Read sensors (sensors.lua) and publish to thingspeak.com
  More info at  https://github.com/avaldebe/AQmon

Written by Álvaro Valdebenito.

MIT license, http://opensource.org/licenses/MIT
]]

--[[ HW pin assignment ]]

local pin={ledR=1,ledG=2,ledB=4,sda=5,scl=6}

--[[ Local functions ]]

-- LED status indicator
local status=dofile('rgbLED.lc')(500,pin.ledR,pin.ledG,pin.ledB,
  {alert='320000',alert='010000',normal='000100',iddle='000001'})
status('normal')
-- low heap(?) alternative: local status=print

print('Start WiFi')
require('wifi_init').connect(wifi.STATION,wifi.MODEM_SLEEP)
-- release memory
wifi_init,package.loaded.wifi_init=nil,nil
status('iddle')

local api=require('keys').api
--api:sendData=dofile('sendData.lua')(status)
function speak(verbose)
  if api.last and api.last>tmr.time() then -- tmr.time overflow
    print(('time overflow: %d>%d'):format(api.last,tmr.time()))
    api.last=tmr.time()
  end
  if api.last and (tmr.time()-api.last)<5 then -- 5s since last (debounce/long press)
    print('wait 5s...')
    return
  end
  local lowHeap=true
  print('Read data')
  require('sensors').init(pin.sda,pin.scl,lowHeap) -- sda,scl,lowHeap
  sensors.read(verbose)
  api.path=sensors.format('status=uptime={upTime},heap={heap}'
  ..'&field1={t}&field2={h}&field3={p}&field4={pm01}&field5={pm25}&field6={pm10}',
    true) -- remove spaces
-- release memory
  if lowHeap then
    sensors,package.loaded.sensors=nil,nil
    collectgarbage()
  end
  api.path=('update?key={put}&{path}'):gsub('{(.-)}',api)
--api:sendData()
  dofile('sendData.lc')(api,status)
  api.last=tmr.time()
end

--[[ Run code ]]

-- start PM sensor data collection
require('sensors').init(pin.sda,pin.scl) -- sda,scl

--api.freq=1 -- debug
if api.freq>0 then
  print(('Send data every %s min'):format(api.freq))
  tmr.alarm(0,api.freq*60000,1,function() speak(false) end)
else
  print('Press KEY_FLASH to send NOW')
  gpio.mode(3,gpio.INT)
  gpio.trig(3,'low',function(state) speak(true) end)
end
