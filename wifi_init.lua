wifi.setmode(wifi.STATION)
local function listap(t)
  local pass = require('wifi_ssid')  -- pass[ssid]  
  for ssid,v in pairs(t) do
    if pass[ssid] and wifi.sta.status()~=5 then
      print("Loggin to: "..ssid)
      wifi.sta.config(ssid,pass[ssid])
      local n=5
      repeat
        tmr.delay(3000) -- 3 ms
        n=n-1
      until n<1 or wifi.sta.status()~=1
    end
    if pass[ssid] and wifi.sta.status()==5 then
      print("Logged to: "..ssid)
      print(""..wifi.sta.getip())
    end
  end
end
wifi.sta.getap(listap)

wifi.setmode(wifi.STATION)
local stat
stat=function(n)
if (n>0) and (wifi.sta.status()~=5) then
  print("Connecting...")
  tmr.alarm(0,300,0,function() stat(n-1) end)
  end
end
local function listap(t)
  local pass = require('wifi_ssid')  -- pass[ssid]  
  for ssid,v in pairs(t) do
    if pass[ssid] and wifi.sta.status()~=5 then
      print("Loggin to: "..ssid)
      wifi.sta.config(ssid,pass[ssid])
      status(10)
    end
    if pass[ssid] and wifi.sta.status()==5 then
      print("Logged to: "..ssid)
      print(""..wifi.sta.getip())
    end
  end
end
wifi.sta.getap(listap)
