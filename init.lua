local blinkD0,keyD0 -- blink D0 (gpio16) until setup
blinkD0=function(start)
  local D0=0
  gpio.mode(D0,gpio.OUTPUT)
  gpio.write(D0,0)
  tmr.alarm(1,100,0,function()
    gpio.write(D0,1)
    gpio.mode(D0,gpio.INPUT)
    keyD0=gpio.read(D0) -- stop on KEY_USER press
    if keyD0==0 then
      gpio.write(D0,1)
      return
      end
    if start then
      tmr.alarm(1,400,0,function() blinkD0(start) end)
      end
    end)
  end
-- https://bigdanzblog.wordpress.com/2015/04/24/esp8266-nodemcu-interrupting-init-lua-during-boot/
-- modified for KEY_USER press
blinkD0(true)
tmr.alarm(0,1000,0,function()   -- after 1s
  print('Press KEY_USER for console mode')
  tmr.alarm(0,1000,0,function() -- after 1s
    if keyD0==0 then
      print('Console mode')
      return
      end
    -- otherwise, start up
    blinkD0(false)
    print('Start WiFi')
    dofile('init_wifi.lua')
    end)
  end)
