--[[
metspeak.lua for ESP8266 with nodemcu-firmware
  Read sensors (met.lua) and publish to thingspeak.com

Written by Álvaro Valdebenito.

MIT license, http://opensource.org/licenses/MIT
]]

blink=require('rgbLED').blink(1,2,4)
blink('normal')

print('Start WiFi')
require('wifi_init').connect(wifi.STATION)
print('WiFi sleep')
wifi.sta.disconnect()
wifi.sleeptype(wifi.MODEM_SLEEP)
-- release memory
wifi_init,package.loaded.wifi_init=nil,nil
blink('iddle')

local api=require('keys').api
gpio.mode(0,gpio.OUTPUT)
local function sendData(method,url)
  blink('alert')
  assert(type(method)=='string' and type(url)=='string',
    'Use app.sendData(method,url)')
  blink('normal')
  if api.sent~=nil then -- already sending data
    blink('iddle')
    return
  end
  api.sent=false

  if wifi.sta.status()~=5 then
    print('WiFi wakeup')
    wifi.sta.connect()
    blink('alert')
  end
  wifi.sleeptype(wifi.NONE_SLEEP)

  local sk=net.createConnection(net.TCP,0)
  sk:on('receive',   function(conn,payload)
    blink('alert')
    assert(conn~=nil and type(payload)=='string','socket:on(receive)')
    blink('normal')
  --print(('  Recieved: "%s"'):format(payload))
    if payload:find('Status: 200 OK') then
      print('  Posted OK')
    end
    blink('iddle')
  end)
  sk:on('connection',function(conn)
    blink('alert')
    assert(conn~=nil,'socket:on(connection)')
    blink('normal')
    print('  Connected')
    gpio.write(0,0)
    print('  Send data')
    local payload=(("%s /%s HTTP/1.1\r\n"):format(method,url)
              .."Host: {url}\r\nConnection: close\r\nAccept: */*\r\n"
            --.."User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n"
              .."\r\n"):gsub('{(.-)}',api)
  --print(payload)
    conn:send(payload)
    blink('iddle')
  end)
  sk:on('sent',function(conn)
    blink('alert')
    assert(conn~=nil,'socket:on(sent)')
    blink('normal')
    print('  Data sent')
    api.sent=true
  --conn:close()
    blink('iddle')
  end)
  sk:on('disconnection',function(conn)
    blink('alert')
    assert(conn~=nil,'socket:on(disconnection)')
    blink('normal')
    conn:close()
    print('  Disconnected')
    gpio.write(0,1)
    print('WiFi sleep')
    wifi.sta.disconnect()
    wifi.sleeptype(wifi.MODEM_SLEEP)
    api.sent=nil
  --collectgarbage()
    blink('iddle')
  end)
  print(('Send data to %s.'):format(api.url))
  sk:connect(80,api.url)
--sk=nil
end

api.last=tmr.now()
local function speak()
  if (tmr.now()-api.last<5e6) then -- 5s since last (debounce/long press)
    return
  end
  local lowHeap=true
  print('Read data')
  require('met').init(5,6,lowHeap) -- sda,scl,lowHeap
  met.read(true)                   -- verbose
  local url=met.format(
   'update?key={put}&status=uptime={upTime},heap={heap}&field1={t}&field2={h}&field3={p}',
    true) -- remove spaces
-- release memory
  if lowHeap then
    met,package.loaded.met=nil,nil
    collectgarbage()
  end
  sendData('GET',url)
  api.last=tmr.now()
end

--api.freq=1 -- debug
print(('Send data every %s min'):format(api.freq))
tmr.alarm(0,api.freq*60e3,1,function() speak() end)

print('Press KEY_FLASH to send NOW')
gpio.mode(3,gpio.INT)
gpio.trig(3,'low',function(state) speak() end)
