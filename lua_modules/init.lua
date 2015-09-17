--[[
init.lua for nodemcu-devkit (ESP8266) with nodemcu-firmware
  Exit infinite reboot caused by a PANIC error.

Written by Álvaro Valdebenito,
based on ideas from:
  https://bigdanzblog.wordpress.com/2015/04/24/esp8266-nodemcu-interrupting-init-lua-during-boot/

MIT license, http://opensource.org/licenses/MIT
]]


-- disable serial/uart (console)
print('Press ENTER to enhable console')
uart.on('data','\r',function(data)
  uart.on('data')
end,0)

print('Press KEY_FLASH for console/upload mode')
ledD0,console=0,nil
gpio.mode(0,gpio.OUTPUT)

-- blink D0 (gpio16) LED until setup or D3 (gpio0) KEY is presed
gpio.write(0,ledD0)
tmr.alarm(1,100,1,function()
  ledD0=1-ledD0   -- blink D0
  gpio.write(0,ledD0)
end)
gpio.mode(3,gpio.INT)
gpio.trig(3,"down",function(state)
  tmr.stop(1)     -- stop blink
  gpio.write(0,0) -- D0 LED on
  console=true
end)

-- console mode or application
tmr.alarm(0,2e3,0,function() -- 2s from boot
  tmr.stop(1)     -- stop blink
  gpio.write(0,1) -- D0 LED off
  gpio.mode(3,gpio.INPUT) -- release D3 interrupt
  if console then
    ledD0,console=nil,nil
    print('Console/Upload mode')
    uart.on('data')
  else
    ledD0,console=nil,nil
    print('Run/App mode')
    require('app')
  end
end)
