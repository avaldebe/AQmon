--[[
wifi_init.lua for nodemcu-devkit (ESP8266) with nodemcu-firmware
   Initialize wifi in STATION mode from SSID/PASS keys stored is a separate file

Written by Álvaro Valdebenito,
  a similar implementation can be found at
  https://github.com/geekscape/nodemcu_esp8266/tree/master/skeleton

MIT license, http://opensource.org/licenses/MIT
]]

local moduleName = ...
local M = {}
_G[moduleName] = M

local pass,cfg={},{}
local function listap(t) -- (SSID:'Authmode, RSSI, BSSID, Channel')
  local stat={[0]='STATION_IDLE',
              [1]='STATION_CONNECTING',
              [2]='STATION_WRONG_PASSWORD',
              [3]='STATION_NO_AP_FOUND',
              [4]='STATION_CONNECT_FAIL',
              [5]='STATION_GOT_IP'}
  local ssid,v,rssi
  for ssid,v in pairs(t) do
    rssi=v:match("[^,]+,([^,]+),[^,]+,[^,]+")
    if pass[ssid] and wifi.sta.status()==5 then
      print(('  STA Logged to: %s (%s dBm)'):format(ssid,rssi))
      print(('    %s %s'):format(stat[5],wifi.sta.getip()))
      return -- stop search
    elseif pass[ssid] then
      print(('  STA Loggin to: %s (%s dBm)'):format(ssid,rssi))
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
function M.connect(mode,sleep)
-- mode: wifi.STATION|wifi.SOFTAP|wifi.STATIONAP
-- sleep: nil|false(wifi.NONE_SLEEP)|true(wifi.MODEM_SLEEP)

  if wifi.getmode()~=mode then
    wifi.setmode(mode)
  end

  if mode==wifi.SOFTAP or mode==wifi.STATIONAP then
    cfg=require('keys').ap -- {ssid=ssid,pwd=pass}
    wifi.setmode(mode)
    wifi.ap.config(cfg)
    print(('  AP  %s %s'):format(cfg.ssid,wifi.ap.getip()))
  end

  if mode==wifi.STATION or mode==wifi.STATIONAP then
    local ssid,v
    pass=require('keys').sta -- {ssid1=pass1,...}
    if wifi.sta.status()==5 then
    -- test current SSID
      ssid=wifi.sta.getconfig()
      cfg={ssid=ssid,bssid=nil,channel=0,show_hidden=1}
      wifi.sta.getap(cfg,0,listap)
    else
    -- loop over knowk SSIDs
      for ssid,v in pairs(pass) do
        cfg={ssid=ssid,bssid=nil,channel=0,show_hidden=1}
        wifi.sta.getap(cfg,0,listap)
      end
    end
    -- put WiFi tranciver to sleep
    if wifi.sta.status()==5 and sleep==true then
      print('WiFi sleep')
      wifi.sta.disconnect()
      wifi.sleeptype(wifi.MODEM_SLEEP)
    elseif sleep==false then
      print('WiFi wakeup')
      wifi.sta.connect()
      wifi.sleeptype(wifi.NONE_SLEEP)
    end
  end
end
return M
