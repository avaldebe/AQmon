--[[
sendData.lua for ESP8266 with nodemcu-firmware
  Publish sensor data (self.path) to thingspeak.com (self.url)
  More info at  https://github.com/avaldebe/AQmon

Written by Álvaro Valdebenito.

MIT license, http://opensource.org/licenses/MIT
]]

local M={name=...}

return function(self,status)
  package.loaded[M.name]=nil -- volatile module 

  status('normal')
  if self.sent~=nil then -- already sending data
    status('warning')
    print('  Warning: last message not yet sent')
  --return
  end
  self.sent=false

  require('wifi_connect')(wifi.STATION,false) -- wifi wake-up
  local sk=net.createConnection(net.TCP,0)
--[[Expected sequence of events:
    sk:connect(...)
    sk:on('connection')
      sk:send(...)
    sk:on('sent')
    sk:on('receive')
    sk:on('disconnection')]]
  sk:on('connection',function(conn)
    status('alert')
    assert(conn~=nil,'socket:on(connection) stale socket')
    status('normal')
    print('  Connected')
    print('  Send data')
    local payload=('GET /{path} HTTP/1.1\r\n'
              ..'Host: {url}\r\nConnection: close\r\nAccept: */*\r\n'
            --..'User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n'
              ..'\r\n'):gsub('{(.-)}',self)
  --print(payload)
    conn:send(payload)
    status('iddle')
  end)
  sk:on('sent',function(conn)
    status('alert')
    assert(conn~=nil,'socket:on(sent) stale socket')
    status('normal')
    print('  Data sent')
    self.sent=true
  --conn:close()
    status('iddle')
  end)
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
  sk:on('disconnection',function(conn)
    status('alert')
    assert(conn~=nil,'socket:on(disconnection) stale socket')
    status('normal')
    conn:close()
    print('  Disconnected')
    require('wifi_connect')(wifi.STATION,true) -- wifi sleep
    self.sent=nil
    self.last=tmr.time()
    status('iddle')
  end)
  print(('Send data to %s.'):format(self.url))
  sk:connect(80,self.url)
end
