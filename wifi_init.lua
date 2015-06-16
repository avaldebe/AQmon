local M = {}
local pass=require('wifi_ssid') -- {ssid1=pass1,...}
local function listap(t)
  for ssid,v in pairs(t) do
    if pass[ssid] and wifi.sta.status()~=5 then
      print("Loggin to: "..ssid)
      wifi.sta.config(ssid,pass[ssid])
      local n=10
      tmr.alarm(0,300,0,function()
        if (n>0) and (wifi.sta.status()~=5) then
          print("Connecting...")
          n=n-1
        else
          tmr.stop(0)
        end
      end)
    end
    if pass[ssid] and wifi.sta.status()==5 then
      print("Logged to: "..ssid)
      print(""..wifi.sta.getip())
      pass={} -- free memory and stop search
    end
  end
end
function M.connect()
  wifi.setmode(wifi.STATION)
  wifi.sta.getap(listap)
end
return M