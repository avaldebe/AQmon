print('Tidy up')
require('upkeep').clean()

print('Start WiFi')
require('wifi_init').connect()

met=require('met')
key=require('keys').api.put
dt=60000*5  -- send data every 5 min
gpio.mode(0,gpio.OUTPUT)
tmr.alarm(0,dt,1,function()
  if wifi.sta.status()~=5 then
    print('No WiFi, resart!')
    node.restart() -- connection failed
  end
  gpio.write(0,0)
  print('Met sensors')
  met.read(true) -- verbose
-- conection to thingspeak.com
  print("Sending met data")
  local update=("GET /update?key=%s&field1=%s&field2=%s&field3=%s HTTP/1.1\r\n"):format(key,met.t,met.h,met.p)
  local conn
  conn=net.createConnection(net.TCP,0) 
-- api.thingspeak.com 184.106.153.149
  conn:connect(80,'184.106.153.149') 
  conn:on("receive",function(conn,payload) print(payload) end)
  conn:send(update) 
  conn:send("Host: api.thingspeak.com\r\n") 
  conn:send("Accept: */*\r\n") 
  conn:send("User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n")
  conn:send("\r\n")
  conn:on("sent",function(conn) print("  Closing connection");conn:close();gpio.write(0,1) end)
  conn:on("disconnection",function(conn) print("  Got disconnection");gpio.write(0,1) end)
end)
