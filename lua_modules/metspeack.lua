print('Start WiFi')
require('wifi_init').connect(wifi.STATION)
print('Sleep mode: MODEM_SLEEP')
wifi.sleeptype(wifi.MODEM_SLEEP)
-- release memory
wifi_init,package.loaded.wifi_init=nil,nil

local api=require('keys').api
api.update={
  "GET /update?key={put}&status={stat}&field1={f1}&field2={f2}&field3={f3} HTTP/1.1\r\n",
  "Host: {url}\r\nAccept: */*\r\n\r\n",
}

--require('met').init(5,6,false) -- sda,scl,lowHeap
gpio.mode(0,gpio.OUTPUT)
api.last=tmr.now()
local function speak()
  if (tmr.now()-api.last<5e6) or -- 5s since last (debounce/long press)
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
  print("Read sensors")
  if met==nil then
    require('met').init(5,6,true) -- sda,scl,lowHeap
  end
  met.read(true) -- verbose
  api.f1,api.f2,api.f3=met.t,met.h,met.p
  met,package.loaded.met=nil,nil
  local uptime=tmr.time()
  uptime=('%04d:%02d:%02d'):format(uptime/36e2,uptime%36e2/60,uptime%60)
  api.stat=('uptime=%s, heap=%d'):format(uptime,node.heap())
  print('  '..api.stat)

  local sk=net.createConnection(net.TCP,0)
  sk:on("receive",   function(conn,payload)
--  print(("  Recieved: '%s'"):format(payload))
    if payload==nil or payload:find("Status: 200 OK") then
      print("  Posted OK")
    end
  end)
  sk:on("connection",function(conn)
    print("  Connected")
    gpio.write(0,0)
    print("  Send data")
    local i=0
    for i=1,#api.update do
      conn:send(api.update[i]:gsub("{(.-)}",api))
    end
    api.sent=true
  end)
  sk:on("sent",function(conn)
    if api.sent then
      print("  Data sent")
    end
  end)
  sk:on("disconnection",function(conn)
    print("  Disconnected")
    gpio.write(0,1)
    print('Sleep mode: MODEM_SLEEP')
    wifi.sleeptype(wifi.MODEM_SLEEP)
    api.last=tmr.now()
    api.sent=nil
    collectgarbage()
  end)
  print('Send sensor data to '..api.url)
  sk:connect(80,api.url)
end

print(('Send data every %s min'):format(api.freq))
tmr.alarm(0,api.freq*60e3,1,function() speak() end)

print('Press KEY_FLASH to send NOW')
gpio.mode(3,gpio.INT)
gpio.trig(3,"low",function(state) speak() end)
