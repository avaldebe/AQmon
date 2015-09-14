--[[
rgbLED.lua for ESP8266 with nodemcu-firmware
  controls one RGB led with PWM

Written by Álvaro Valdebenito.

MIT license, http://opensource.org/licenses/MIT
]]

local M = {}

function M.dimmer(pinR,pinG,pinB,commonAnode)
--[[
Returns a function to dimm the RGB led, eg
  dimmer=requere('rgbLED').dimmer(pinR,pinG,pinB)
  dimmer(r,g,b) with r|g|b the intensity in [%] of Red|Green|Blue
]]
  package.loaded.rgbLED=nil -- reload package each requere('rgbLED')
  local k,v
  for k,v in pairs({R=pinR,G=pinG,B=pinB}) do
    assert(type(v)=='number' and v>=1 and v<=12,
    ('rgbLED.dimmer(pinR,pinG,pinB): Invalid pin%s'):format(k))
    pwm.setup(v,500,0) -- 500 Hz
    pwm.start(v)
  end
  assert(type(commonAnode)=='boolean' or commonAnode==nil,
    ('rgbLED.dimmer(pinR,pinG,pinB,commonAnode): Invalid commonAnode'))
  package.loaded.rgbLED=nil,nil -- release module from memory
  return function(r,g,b)
    assert(type(r)=='number' and r>=0 and r<=100,'dimmer(r,g,b): Invalid r[%]')
    assert(type(g)=='number' and g>=0 and g<=100,'dimmer(r,g,b): Invalid g[%]')
    assert(type(b)=='number' and b>=0 and b<=100,'dimmer(r,g,b): Invalid b[%]')
    if commonAnode then r,g,b=100-r,100-g,100-b end
    local r,g,b=r*1023/100,g*1023/100,b*1023/100
    pwm.setduty(pinR,r)
    pwm.setduty(pinG,g)
    pwm.setduty(pinB,b)
    return r,g,b
  end
end

function M.blinker(pinR,pinG,pinB,commonAnode)
--[[
Returns a function to blink the RGB led, eg
  status=requere('rgbLED').blinker(pinR,pinG,pinB)
  status(code) with
    code='alert'     long  blink Red
    code='lowbat'    short blink Red
    code='normal'    short blink Green
    code='iddle'     short blink Blue
    code='R'|'G'|'B' long  blink Red|Green|Blue
    code='r'|'g'|'b' short blink Red|Green|Blue
]]
  package.loaded.rgbLED=nil -- reload package each requere('rgbLED')
  assert(type(commonAnode)=='boolean' or commonAnode==nil,
    ('rgbLED.dimmer(pinR,pinG,pinB,commonAnode): Invalid commonAnode'))
  local k,v
  for k,v in pairs({R=pinR,G=pinG,B=pinB}) do
    assert(type(v)=='number' and v>=1 and v<=12,
    ('rgbLED.blinker(pinR,pinG,pinB): Invalid pin%s'):format(k))
    pwm.setup(v,1,0) -- 1Hz or 1 blink/second
    pwm.start(v)
  end
  return function(code)
    assert(type(code)=='string','blink(code): Invalid code')
    if code:lower()=='alert' then
      code='R'                  -- long  blink Red
    elseif code:lower()=='lowbat' then
      code='r'                  -- short blink Red
    elseif code:lower()=='normal' then
      code='g'                  -- short blink Green
    elseif code:lower()=='iddle' then
      code='b'                  -- short blink Blue
    end
    local rgb={R=0,G=0,B=0}
    if rgb[code]~=nil then              -- 'R'|'G'|'B'
      rgb[code]=50              -- ON ~50ms Red|Green|Blue
    elseif rgb[code:upper()]~=nil then  -- 'r'|'g'|'b'
      rgb[code:upper()]=1       -- ON  ~1ms Red|Green|Blue
    else
      assert(code:lower()=='clear','blink(code): Invalid code')
      rgb={R=0,G=0,B=0}         -- OFF
    end
    if commonAnode then
      rgb={R=1023-rgb.R,G=1023-rgb.G,B=1023-rgb.B}
    end
    pwm.setduty(pinR,rgb.R)
    pwm.setduty(pinG,rgb.G)
    pwm.setduty(pinB,rgb.B)
    return rgb.R,rgb.G,rgb.B
  end
end

return M
