--print('Tidy up')
--require('upkeep').clean()

print('Start WiFi')
require('wifi_init').connect(wifi.STATION)

met=require('met')
met.key=require('keys').api.put
dt=60000*5  -- send data every 5 min
gpio.mode(0,gpio.OUTPUT)
tmr.alarm(0,dt,1,function()
  if wifi.sta.status()~=5 then
    print('No WiFi, restart!')
    node.restart() -- connection failed
  end
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
    conn:send(("GET /update?key={key}&field1={t}&field2={h}&field3={p} HTTP/1.1\r\n"):gsub("{(.-)}",met))
    conn:send("Host: api.thingspeak.com\r\n")
    conn:send("Accept: */*\r\n")
    conn:send("User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n")
    conn:send("\r\n")
  end)
  conn:on("sent",      function(conn,payload)
    print("  Data sent")
    conn:close()
    gpio.write(0,1)
  end)
  conn:on("disconnection",function(conn,payload)
    print("  Disconnected")
    collectgarbage()
  end)
  print("Send sensor data to thingspeak.com")
  conn:connect(80,"api.thingspeak.com")
end)
