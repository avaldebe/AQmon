local M = {}
local function listap(t)
  local pass=require('wifi_ssid') -- {ssid1=pass1,...}
  local stat={[0]='STATION_IDLE',
              [1]='STATION_CONNECTING',
              [2]='STATION_WRONG_PASSWORD',
              [3]='STATION_NO_AP_FOUND',
              [4]='STATION_CONNECT_FAIL',
              [5]='STATION_GOT_IP'}
  for ssid,v in pairs(t) do
    if pass[ssid] and wifi.sta.status()==5 then
      print(('Logged to: %s'):format(ssid))
      print(('%s %s'):format(stat[5],wifi.sta.getip()))
      return -- stop search
    elseif pass[ssid] then
      print(('Loggin to: %s'):format(ssid))
      wifi.sta.config(ssid,pass[ssid])
      local n=20
      tmr.alarm(0,10000,1,function()
        local s=wifi.sta.status()
        if n>0 and s<=1 then
          print(stat[s])
          n=n-1
        elseif s==5 then
          tmr.stop(0)
          print(('%s %s'):format(stat[5],wifi.sta.getip()))
          return -- stop search
        elseif n>0 then
          tmr.stop(0)
          print(stat[s])
        else
          tmr.stop(0)
          print('Timed out')
        end
      end)
    end
  end
end
function M.connect()
  if wifi.sta.status()==5 then
    print(('%s %s'):format('Connected',wifi.sta.getip()))
  else
    wifi.setmode(wifi.STATION)
    wifi.sta.getap(listap)
  end
end
return M