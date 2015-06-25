--[[
wifi_init.lua for nodemcu-devkit (ESP8266) with nodemcu-firmware
   Initialize wifi in STATION mode from SSID/PASS keys stored is a separate file

Written by Álvaro Valdebenito,
  a similar implementation can be found at
  https://github.com/geekscape/nodemcu_esp8266/tree/master/skeleton

MIT license, http://opensource.org/licenses/MIT
]]

local M = {}
local pass={}
local function listap(t)
  local stat={[0]='STATION_IDLE',
              [1]='STATION_CONNECTING',
              [2]='STATION_WRONG_PASSWORD',
              [3]='STATION_NO_AP_FOUND',
              [4]='STATION_CONNECT_FAIL',
              [5]='STATION_GOT_IP'}
  for ssid,v in pairs(t) do
    if pass[ssid] and wifi.sta.status()==5 then
      print(('  STA Logged to: %s'):format(ssid))
      print(('    %s %s'):format(stat[5],wifi.sta.getip()))
      return -- stop search
    elseif pass[ssid] then
      print(('  STA Loggin to: %s'):format(ssid))
      wifi.sta.config(ssid,pass[ssid])
      local n=20
      tmr.alarm(0,10000,1,function()
        local s=wifi.sta.status()
        if n>0 and s<=1 then
          print(stat[s])
          n=n-1
        elseif s==5 then
          tmr.stop(0)
          print(('    %s %s'):format(stat[5],wifi.sta.getip()))
          return -- stop search
        elseif n>0 then
          tmr.stop(0)
          print(('    %s'):format(stat[s]))
        else
          tmr.stop(0)
          print('  STA: Timed out')
        end
      end)
    end
  end
end
function M.connect(mode) -- mode: wifi.STATION|wifi.SOFTAP|wifi.STATIONAP
  if mode==wifi.SOFTAP or mode==wifi.STATIONAP then
    local cfg=require('keys').ap -- {ssid=ssid,pwd=pass}
    wifi.setmode(mode)
    wifi.ap.config(cfg)
    print(('  AP  %s %s'):format(cfg.ssid,wifi.ap.getip()))
  end
  if mode==wifi.STATION or mode==wifi.STATIONAP then
    if wifi.sta.status()==5 then
      print(('  STA %s %s'):format('Connected',wifi.sta.getip()))
    else
      pass=require('keys').sta -- {ssid1=pass1,...}
      wifi.setmode(mode)
      wifi.sta.getap(listap)
    end
  end
end
return M
