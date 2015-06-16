-- https://bigdanzblog.wordpress.com/2015/04/24/esp8266-nodemcu-interrupting-init-lua-during-boot/
tmr.alarm(0,1000,0,function()   -- after 1s
  print('Press ENTER console mode')
  local console=false
  uart.on("data","\r",function(data)
    console=true 
    uart.on("data") 
    end,0)
  tmr.alarm(0,5000,0,function() -- after 5s
    uart.on("data") 
    if console==true then
      print('Console mode')
      return
      end
    -- otherwise, start up
    print('Start WiFi')
    dofile('wifi_init.lua')
    end)
  end)


