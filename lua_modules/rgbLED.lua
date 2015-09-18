--[[
rgbLED.lua for ESP8266 with nodemcu-firmware
  Returns a status function for a RGB LED.
  More info at  https://github.com/avaldebe/AQmon

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
    {mode1='rrggbb',mode2='rrggbb',...},commonAnode)

  frequency:
    PWM frequency (see clock in pwm.setup() API). A low frequency will
    make the LED blink, and a large frequency will dimm the LED.

  pinR|pinG|pinB:
    Digital pin for Red|Green|Blue LED leg.

  modeX='rrggbb':
    key=value for a particular RGB mode. The key (modeX) is used to recall
    the RGB mode and the value 'rrggbb' correspond to the GRB hex code.
    For example, 'FF0000'|'00FF00'|'0000FF' reprecent the maximum intentity
    or the longest blink (~25% duty cycle).


Common cathode/anode RGB LED types:

  Common Cathode (CC for short)
    Red    anode ———D|—.
    Green  anode ———D|—+— Common cathode
    Blue   anode ———D|—'

  Common Anode (CA for short)
                  .—D|——— Red    cathode
    Common anode —+—D|——— Green  cathode
                  '—D|——— Blue   cathode

  Controll logic:
    The implementation of the RGB hex codes depends of the RGB LED type.
    On a CC LED type, each section will is ON when their respective color
    leg is connected to a High value and OFF when connected to a Low.
    The control logic should be inverted for a CA LED type, as
    a High will turn each color OFF and a Low will turn it OFF.
]]

local commonCathode=true

if commonCathode then
  commonCathode=nil
  return function(freq,pinR,pinG,pinB,mode)
    pwm.setup(pinR,freq,0) pwm.start(pinR)
    pwm.setup(pinG,freq,0) pwm.start(pinG)
    pwm.setup(pinB,freq,0) pwm.start(pinB)
    return function(code)
      assert(mode[code]~=nil,'rgbLED: Invalid mode[code]')
      pwm.setduty(pinR,tonumber(mode[code]:sub(1,2),16))
      pwm.setduty(pinG,tonumber(mode[code]:sub(3,4),16))
      pwm.setduty(pinB,tonumber(mode[code]:sub(5,6),16))
    end
  end
else -- common anode: inverted controll logic
  commonCathode=nil
  return function(freq,pinR,pinG,pinB,mode)
    pwm.setup(pinR,freq,1023) pwm.start(pinR)
    pwm.setup(pinG,freq,1023) pwm.start(pinG)
    pwm.setup(pinB,freq,1023) pwm.start(pinB)
    return function(code)
      assert(mode[code]~=nil,'rgbLED: Invalid mode[code]')
      pwm.setduty(pinR,1023-tonumber(mode[code]:sub(1,2),16))
      pwm.setduty(pinG,1023-tonumber(mode[code]:sub(3,4),16))
      pwm.setduty(pinB,1023-tonumber(mode[code]:sub(5,6),16))
    end
  end
end
