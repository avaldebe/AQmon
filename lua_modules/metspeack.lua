print('Start WiFi')
require('wifi_init').connect(wifi.STATION)
print('Sleep mode: MODEM_SLEEP')
wifi.sleeptype(wifi.MODEM_SLEEP)
-- release memory
wifi_init,package.loaded.wifi_init=nil,nil

local api=require('keys').api
gpio.mode(0,gpio.OUTPUT)
local function sendData(data)
  if (data==nil) or
     (api.sent~=nil) then        -- already sending data
    return
  end
  api.sent=false
  print('Sleep mode: NONE_SLEEP')
  wifi.sleeptype(wifi.NONE_SLEEP)
  if wifi.sta.status()~=5 then
    print('No WiFi, restart!')
    node.restart() -- connection failed
  end
--local
  sk=nil
  sk=net.createConnection(net.TCP,0)
  sk:on("receive",   function(conn,payload)
--  print(("  Recieved: '%s'"):format(payload))
    if payload==nil or payload:find("Status: 200 OK") then
      print("  Posted OK")
    elseif conn then
      conn:close()
    end
  end)
  sk:on("connection",function(conn)
    if not conn then
      print("WTF?connection")
      return
    end
    print("  Connected")
    gpio.write(0,0)
    print("  Send data")
    local i=0
    for i=1,#data do
      conn:send(data[i]:gsub("{(.-)}",api),
        print(("    #%d: %s"):format(i,sent)))
    end
    api.sent=true
  end)
  sk:on("sent",function(conn)
    if api.sent then
      print("  Data sent")
    end
  end)
  sk:on("disconnection",function(conn)
    if conn then conn:close() end
    print("  Disconnected")
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
  print("Read data")
  require('met').init(5,6,lowHeap) -- sda,scl,lowHeap
  met.read(true) -- verbose
-- status
  local uptime=tmr.time()
  met.stat=('uptime=%04d:%02d:%02d, heap=%d'):format(
    uptime/36e2,uptime%36e2/60,uptime%60,node.heap())
  print('  '..met.stat)
-- update string
  local update=
    ("GET /update?key={put}&status={stat}&field1={t}&field2={h}&field3={p} HTTP/1.1\r\n"
  .."Host: {url}\r\nConnection: close\r\nAccept: */*\r\n\r\n"):gsub("{(.-)}",met)
-- release memory
  if lowHeap then
    met,package.loaded.met=nil,nil
    collectgarbage()
  end
  sendData({update})
  api.last=tmr.now()
end

--api.freq=0.50 -- debug
print(('Send data every %s min'):format(api.freq))
tmr.alarm(0,api.freq*60e3,1,function() speak() end)

print('Press KEY_FLASH to send NOW')
gpio.mode(3,gpio.INT)
gpio.trig(3,"low",function(state) speak() end)
