--[[
rgbLED.lua for ESP8266 with nodemcu-firmware
  Returns a status function for a RGB LED.

Written by Álvaro Valdebenito.

MIT license, http://opensource.org/licenses/MIT

Ussge:
  dimmer=dofile('rgbLED.lc')(500,pinR,pinG,pinB,
   {alert='320000',alert='010000',normal='000100',iddle='000001'})
  returns function dimmer(status) that
    status=='alert'  ==> bright-ish Red
    status=='lowbat' ==> very dimm Red
    status=='normal' ==> very dimm Green
    status=='iddle'  ==> very dimm Blue

  blink=dofile('rgbLED.lc')(1,pinR,pinG,pinB,
   {r='010000',R='FF0000',g='000100',g='00FF00',b='000001',B='0000FF''})
  returns function blink(code) that
    code=='r'|'g'|'b' ==> short Red|Green|Blue blink
    code=='R'|'G'|'B' ==> long  Red|Green|Blue blink

Options:
  dofile('rgbLED.lc')(frecuency,pinR,pinG,pinB,
    {mode1='rrggbb',mode2='rrggbb',...})
  frequency:
    PWM frequency (see clock in pwm.setup() API). A low frequency will
    make the LED blink, and a large frequency will dimm the LED.
  pinR|pinG|pinB:
    Digital pin for Red|Green|Blue LED leg.
  modeX='rrggbb':
    key=value for a particular RGB mode. The key (modex) is used to recall
    the RGB mode and the value 'rrggbb' correspond to the GRB hex code.
    The spceific code depends of the RGB LED type: common cathode or common anode.
    For example, 'FF0000'|'00FF00'|'0000FF' reprecent the maximum intentity
    or the longest blink (~25% duty cycle) for a common cathode RGB LED.
    On a common anode those same states are repsresnted by
    '00FFFF'|'FF00FF'|'FFFF00'.
]]

return function(freq,pinR,pinG,pinB,mode)
  package.loaded.rgbLED=nil -- reload package each dofile('rgbLED.lc')
  pwm.setup(pinR,freq,0) pwm.start(pinR)
  pwm.setup(pinG,freq,0) pwm.start(pinG)
  pwm.setup(pinB,freq,0) pwm.start(pinB)
  return function(code)
    assert(mode[code]~=nil,'mode[code]: Invalid code')
    pwm.setduty(pinR,tonumber(mode[code]:sub(1,2),16))
    pwm.setduty(pinG,tonumber(mode[code]:sub(3,4),16))
    pwm.setduty(pinB,tonumber(mode[code]:sub(5,6),16))
  end
end
