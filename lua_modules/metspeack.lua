print('Start WiFi')
require('wifi_init').connect(wifi.STATION)
print('Sleep mode: MODEM_SLEEP')
wifi.sleeptype(wifi.MODEM_SLEEP)
-- release memory
wifi_init,package.loaded.wifi_init=nil,nil

local api=require('keys').api
api.update={
  "GET /update?key={put}&status={stat}&field1={f1}&field2={f2}&field3={f3} HTTP/1.1\r\n",
  "Host: {url}\r\n","Accept: */*\r\n",
  "User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n","\r\n"
}

gpio.mode(0,gpio.OUTPUT)
local function speack()
  print('Sleep mode: NONE_SLEEP')
  wifi.sleeptype(wifi.NONE_SLEEP)
  if wifi.sta.status()~=5 then
    print('No WiFi, restart!')
    node.restart() -- connection failed
  end
  print("Read sensors")
  require('met').read(true) -- verbose
  api.f1,api.f2,api.f3=met.t,met.h,met.p
  met,package.loaded.met=nil,nil
  local uptime=tmr.time()
  uptime=('%04d:%02d:%02d'):format(uptime/36e2,uptime%36e2/60,uptime%60)
  api.stat=('uptime:%s, heap:%d, freq[min]:%d'):format(uptime,node.heap(),api.freq)
  print('  '..api.stat)

  conn=net.createConnection(net.TCP,0)
  conn:on("receive",   function(conn,payload)
    print(payload:find("Status: 200 OK") and "  Posted OK" or "  Recieved: "..payload)
  end)
  conn:on("connection",function(conn,payload)
    print("  Connected")
    gpio.write(0,0)
    print("  Send data")
    local i=0
    for i=1,#api.update do
    --print(api.update[i]:gsub("{(.-)}",api))
      conn:send(api.update[i]:gsub("{(.-)}",api))
    end
  end)
  conn:on("sent",function(conn,payload)
    print("  Data sent")
    conn:close()
  end)
  conn:on("disconnection",function(conn,payload)
    print("  Disconnected")
    gpio.write(0,1)
    print('Sleep mode: MODEM_SLEEP')
    wifi.sleeptype(wifi.MODEM_SLEEP)
    collectgarbage()
  end)
  print('Send sensor data to '..api.url)
  conn:connect(80,api.url)
end

print(('Send data every %s min'):format(api.freq))
tmr.alarm(0,api.freq*60e3,1,function() speack() end)

print('Press KEY_FLASH to send NOW')
gpio.mode(3,gpio.INT)
gpio.trig(3,"low",function(state) speack() end)


