-- https://bigdanzblog.wordpress.com/2015/04/24/esp8266-nodemcu-interrupting-init-lua-during-boot/
-- modified for KEY press
-- blink D0 (gpio16) LED until setup or D3 (gpio0) key is presed
ledD0,console=0,nil
gpio.mode(0,gpio.OUTPUT)
gpio.write(0,ledD0)
tmr.alarm(1,100,1,function()
  ledD0=1-ledD0   -- blink D0
  gpio.write(0,ledD0)
end)
gpio.mode(3,gpio.INT)
gpio.trig(3,"low",function(state)
  tmr.stop(1)     -- stop blink
  gpio.write(0,0) -- D0 LED on
  console=true
end)
tmr.alarm(0,1000,0,function()   -- after 1s
  print('Press KEY_FLASH for console mode')
  tmr.alarm(0,1000,0,function() -- after 1s
    tmr.stop(1)     -- stop blink
    gpio.write(0,1) -- D0 LED off
    ledD0=nil
    if console then
      console=nil
      print('Console mode')
    else
    -- otherwise, start up
      console=nil
      print('Start WiFi')
      require('wifi_init').connect()
    end
  end)
end)
