-- put PMS3003 on stand-by mode before enhabling UART
local pinSET=require('keys').pin.PMset
if type(pinSET)=='number' then
  gpio.mode(pinSET,gpio.OUTPUT)
  gpio.write(pinSET,gpio.LOW)
end
uart.on('data')

print('Start WiFi')
require('wifi_connect')(wifi.STATION,nil) -- mode,sleep

tmr.alarm(0,10000,0,function() -- 10s after start
  print('Start telnet server')
  s=net.createServer(net.TCP,180)
  s:listen(2323,function(c)
    function s_output(str) if(c~=nil) then c:send(str) end end
    node.output(s_output, 0)   -- re-direct output to function s_ouput.
    -- works like pcall(loadstring(l)) but support multiple separate line
    c:on("receive",function(c,l) node.input(l) end)
    -- un-regist the redirect output function, output goes to serial
    c:on("disconnection",function(c) node.output(nil) end)
    print("Welcome to NodeMcu world.")
  end)
end)



