--[[
init.lua for nodemcu-devkit (ESP8266) with nodemcu-firmware
  Exit infinite reboot caused by a PANIC error.

Written by Álvaro Valdebenito,
based on ideas from: 
  https://bigdanzblog.wordpress.com/2015/04/24/esp8266-nodemcu-interrupting-init-lua-during-boot/

MIT license, http://opensource.org/licenses/MIT
]]

tmr.alarm(0,1000,0,function() -- 1s from boot
-- blink D0 (gpio16) LED until setup or D3 (gpio0) KEY is presed
  print('Press KEY_FLASH for console mode')
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
-- console mode or application
  tmr.alarm(0,1000,0,function() -- 2s from boot
    tmr.stop(1)     -- stop blink
    gpio.write(0,1) -- D0 LED off
    gpio.mode(3,gpio.INPUT) -- release D3 interrupt
    if console then
      ledD0,console=nil,nil
      print('Console mode')
    else
      ledD0,console=nil,nil
      print('Run mode')
      require('application')
      print('Press KEY_FLASH to restart')
      gpio.mode(3,gpio.INT)
      gpio.trig(3,"low",function(state) node.restart() end)
    end
  end)
end)
