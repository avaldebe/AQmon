--[[
AQmon.lua for ESP8266 with nodemcu-firmware
  Read sensors (sensors.lua) and publish to thingspeak.com
  More info at  https://github.com/avaldebe/AQmon

Written by Álvaro Valdebenito.

MIT license, http://opensource.org/licenses/MIT
]]

-- HW pin assignments
local pin={ledR=1,ledG=2,ledB=4,sda=5,scl=6}

-- LED status indicator
local status=dofile('rgbLED.lc')(500,pin.ledR,pin.ledG,pin.ledB,
  {alert='320000',alert='010000',normal='000100',iddle='000001'})
--local function status(msg) end
status('normal')

print('Start WiFi')
require('wifi_init').connect(wifi.STATION)
print('WiFi sleep')
wifi.sta.disconnect()
wifi.sleeptype(wifi.MODEM_SLEEP)
-- release memory
wifi_init,package.loaded.wifi_init=nil,nil
status('iddle')

local api=require('keys').api
gpio.mode(0,gpio.OUTPUT)
function api.sendData()
  status('normal')
  if api.sent~=nil then -- already sending data
    status('iddle')
    return
  end
  api.sent=false

  if wifi.sta.status()~=5 then
    print('WiFi wakeup')
    wifi.sta.connect()
  --status('alert')
  end
  wifi.sleeptype(wifi.NONE_SLEEP)

  local sk=net.createConnection(net.TCP,0)
  sk:on('receive',   function(conn,payload)
    status('alert')
    assert(conn~=nil,'socket:on(receive) stale socket')
    status('normal')
  --print(('  Recieved: "%s"'):format(payload))
    if payload:find('Status: 200 OK') then
      print('  Posted OK')
    end
    status('iddle')
  end)
  sk:on('connection',function(conn)
    status('alert')
    assert(conn~=nil,'socket:on(connection) stale socket')
    status('normal')
    print('  Connected')
    gpio.write(0,0)
    print('  Send data')
    local payload=('GET /{path} HTTP/1.1\r\n'
              ..'Host: {url}\r\nConnection: close\r\nAccept: */*\r\n'
            --..'User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n'
              ..'\r\n'):gsub('{(.-)}',api)
  --print(payload)
    conn:send(payload)
    status('iddle')
  end)
  sk:on('sent',function(conn)
    status('alert')
    assert(conn~=nil,'socket:on(sent) stale socket')
    status('normal')
    print('  Data sent')
    api.sent=true
  --conn:close()
    status('iddle')
  end)
  sk:on('disconnection',function(conn)
    status('alert')
    assert(conn~=nil,'socket:on(disconnection) stale socket')
    status('normal')
    conn:close()
    print('  Disconnected')
    gpio.write(0,1)
    print('WiFi sleep')
    wifi.sleeptype(wifi.MODEM_SLEEP)
    wifi.sta.disconnect()
    api.sent=nil
    status('iddle')
  end)
  print(('Send data to %s.'):format(api.url))
  sk:connect(80,api.url)
end

api.last=tmr.now()
require('sensors').init(pin.sda,pin.scl,false) -- sda,scl,lowHeap
local function speak()
  if (tmr.now()-api.last<5e6) then -- 5s since last (debounce/long press)
    return
  end
  local lowHeap=true
  print('Read data')
  require('sensors').init(pin.sda,pin.scl,lowHeap) -- sda,scl,lowHeap
  sensors.read(true)                   -- verbose
  api.path=sensors.format('update?key={put}&status=uptime={upTime},heap={heap}'
  ..'&field1={t}&field2={h}&field3={p}&field4={pm01}&field5={pm25}&field6={pm10}',
    true):gsub('{(.-)}',api) -- remove spaces
-- release memory
  if lowHeap then
    sensors,package.loaded.sensors=nil,nil
    collectgarbage()
  end
  api.sendData()
  api.last=tmr.now()
end

--api.freq=1 -- debug
print(('Send data every %s min'):format(api.freq))
tmr.alarm(0,api.freq*60e3,1,function() speak() end)

print('Press KEY_FLASH to send NOW')
gpio.mode(3,gpio.INT)
gpio.trig(3,'low',function(state) speak() end)
