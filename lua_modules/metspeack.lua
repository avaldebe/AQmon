print('Start WiFi')
require('wifi_init').connect(wifi.STATION)
print('Sleep mode: MODEM_SLEEP')
wifi.sleeptype(wifi.MODEM_SLEEP)
-- release memory
wifi_init,package.loaded.wifi_init=nil,nil

local api=require('keys').api
gpio.mode(0,gpio.OUTPUT)
local function sendData(method,url)
  assert(type(method)=='string' and type(url)=='string',
    'Use app.sendData(method,url)')
  if api.sent~=nil then -- already sending data
    return
  end
  api.sent=false

  print('Sleep mode: NONE_SLEEP')
  wifi.sleeptype(wifi.NONE_SLEEP)
  if wifi.sta.status()~=5 then
    print('No WiFi, restart!')
    node.restart() -- connection failed
  end
  local sk
  sk=net.createConnection(net.TCP,0)
  sk:on('receive',   function(conn,payload)
    assert(conn~=nil and type(payload)=='string','socket:on(receive)')
    print(('  Recieved: '%s''):format(payload))
    if payload:find('Status: 200 OK') then
      print('  Posted OK')
    end
  end)
  sk:on('connection',function(conn)
    assert(conn~=nil,'socket:on(connection)')
    print('  Connected')
    gpio.write(0,0)
    print('  Send data')
    local payload=table.concat({('%s /%s HTTP/1.1'):format(method,url),
    'Host: {url}','Connection: close','Accept: */*',
    'User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)',
    ''},'\r\n'):gsub('{(.-)}',api)
print(payload)
    conn:send(payload)--,function(sent) conn:close() end)
  end)
  sk:on('sent',function(conn)
    assert(conn~=nil,'socket:on(sent)')
    print('  Data sent')
    api.sent=true
    conn:close()
  end)
  sk:on('disconnection',function(conn)
    assert(conn~=nil,'socket:on(disconnection)')
  --if conn then conn:close() end
    print('  Disconnected')
    gpio.write(0,1)
    print('Sleep mode: MODEM_SLEEP')
    wifi.sleeptype(wifi.MODEM_SLEEP)
    api.sent=nil
    collectgarbage()
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
    'update?api_key={put}&status=uptime={upTime},heap={heap}&field1={t}&field2={h}&field3={p}',
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
