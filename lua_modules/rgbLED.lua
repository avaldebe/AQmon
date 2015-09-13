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
  dimmer(r[%],g[%],b[%])
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

function M.blink(pinR,pinG,pinB,commonAnode)
--[[
Returns a function to blink the RGB led, eg
  blink=requere('rgbLED').blink(pinR,pinG,pinB)
  blink(code) with
    code='r'|'g'|'b' blinks Red|Green|Glue
  blink() blinks Blue
  blink() blinks Green
]]
  package.loaded.rgbLED=nil -- reload package each requere('rgbLED')
  assert(type(commonAnode)=='boolean' or commonAnode==nil,
    ('rgbLED.dimmer(pinR,pinG,pinB,commonAnode): Invalid commonAnode'))
  local k,v
  for k,v in pairs({R=pinR,G=pinG,B=pinB}) do
    assert(type(v)=='number' and v>=1 and v<=12,
    ('rgbLED.blink(pinR,pinG,pinB): Invalid pin%s'):format(k))
    pwm.setup(v,2,0) -- 2Hz or 2 blinks/second
    pwm.start(v)
  end
  return function(...)
    local rgb={R=pwm.getduty(pinR),
               G=pwm.getduty(pinG),
               B=pwm.getduty(pinB)}
    if commonAnode then
      rgb={R=1023-rgb.R,G=1023-rgb.G,B=1023-rgb.B}
    end
    local i,code
    for i,code in ipairs(arg) do
      assert(type(code)=='string','blink(code): Invalid code')
      if rgb[code]~=nil             then  -- 'R'|'G'|'B'
        rgb[code]=128                     -- ON ~125ms Red|Green|Blue
      elseif rgb[code:upper()]~=nil then  -- 'r'|'g'|'b'
        rgb[code:upper()]=1               -- ON ~449us Red|Green|Blue
      elseif code:lower()=='alert'  then
        rgb={R=128,G=0,B=0}               -- ON ~125ms Red
      elseif code:lower()=='normal'  then
        rgb={R=0,G=1,B=0}                 -- ON ~449us Green
      elseif code:lower()=='iddle' then
        rgb={R=0,G=0,B=1}                 -- ON ~449us Blue
      else
        assert(code:lower()=='stop','blink(code): Invalid code')
        rgb={R=0,G=0,B=0}                 -- OFF
      end
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
