print('Start WiFi')
require('wifi_init').connect(wifi.STATION)
print('Sleep mode: MODEM_SLEEP')
wifi.sleeptype(wifi.MODEM_SLEEP)
-- release memory
wifi_init,package.loaded.wifi_init=nil,nil

local api=require('keys').api
met=require('met')
met.key=api.put  -- chanel write key
met.dt=api.freq  -- update every X min
api=nil
gpio.mode(0,gpio.OUTPUT)
tmr.alarm(0,met.dt*60e3,1,function()
  print('Sleep mode: NONE_SLEEP')
  wifi.sleeptype(wifi.NONE_SLEEP)
  if wifi.sta.status()~=5 then
    print('No WiFi, restart!')
    node.restart() -- connection failed
  end
  met.stat=('uptime[h]:%.2f, heap:%d, freq[min]:%d'):format(tmr.time()/36e2,node.heap(),met.dt)
  print(met.stat)
  conn=net.createConnection(net.TCP,0)
  conn:on("receive",   function(conn,payload)
    print(payload:find("Status: 200 OK") and "  Posted OK" or "  Recieved: "..payload)
  end)
  conn:on("connection",function(conn,payload)
    print("  Connected")
    print("  Read sensors")
    met.read(true) -- verbose
    print("  Send data")
    gpio.write(0,0)
    conn:send(("GET /update?key={key}&status={stat}&field1={t}&field2={h}&field3={p} HTTP/1.1\r\n"):gsub("{(.-)}",met))
    conn:send("Host: api.thingspeak.com\r\n")
    conn:send("Accept: */*\r\n")
    conn:send("User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n")
    conn:send("\r\n")
  end)
  conn:on("sent",function(conn,payload)
    print("  Data sent")
    conn:close()
    gpio.write(0,1)
  end)
  conn:on("disconnection",function(conn,payload)
    print("  Disconnected")
    print('Sleep mode: MODEM_SLEEP')
    wifi.sleeptype(wifi.MODEM_SLEEP)
    collectgarbage()
  end)
  print("Send sensor data to thingspeak.com")
  conn:connect(80,"api.thingspeak.com")
end)
