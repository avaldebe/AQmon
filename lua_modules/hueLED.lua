--[[
hueLED.lua for ESP8266 with nodemcu-firmware
  Returns a function that control a RGB LED with Hue,
  at full Saturation and Brightness (HSV)
  More info at  https://github.com/avaldebe/AQmon

Written by Álvaro Valdebenito,
  based on HSB_to_RGB.pde by Kasper Kamperman
  http://www.kasperkamperman.com/blog/arduino/arduino-programming-hsb-to-rgb/


MIT license, http://opensource.org/licenses/MIT

Ussge:

  hue=dofile('hueLED.lc')(rangeMin,rangeMax,pinR,pinG,pinB)
  returns function hue(val) that adjust the Hue linearly
  between rangeMin and rangeMax.

Options:

  dofile('hueLED.lc')(rangeMin,rangeMax,pinR,pinG,pinB),commonAnode)

  rangeMin|rangeMax:
    minimun|maximum values for the hue scale.

  pinR|pinG|pinB:
    Digital pin for Red|Green|Blue LED leg.


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
    The implementation of the PWM duty cycle depends of the RGB LED type.
    On a CC LED type, each section will is ON when their respective color
    leg is connected to a High value and OFF when connected to a Low.
    The control logic should be inverted for a CA LED type, as
    a High will turn each color OFF and a Low will turn it OFF.
]]

local commonCathode=true

if commonCathode then
  commonCathode=nil
  return function(valMin,valMax,pinR,pinG,pinB)
    assert(type(valMin)=='number' and type(valMax)=='number','hueLED: Invalid rangeMin/Max')
    pwm.setup(pinR,500,0) pwm.start(pinR)
    pwm.setup(pinG,500,0) pwm.start(pinG)
    pwm.setup(pinB,500,0) pwm.start(pinB)
    return function(val)
      assert(type(val)=='number','hueLED: Invalid value')
      local hue=360*(val-valMin)/(valMax-valMin)%360
      local h60=hue%60/60
      local rgbWheel=({         -- range[deg]: Red  Gren  Blue
        [0]={1    ,  h60,0    },--   0 to  59: full up    none
        [1]={1-h60,1    ,0    },--  60 to 119: down full  none
        [2]={0    ,1    ,  h60},-- 120 to 179: none full  up
        [3]={0    ,1-h60,1    },-- 180 to 239: none down  full
        [4]={  h60,0    ,1    },-- 240 to 299: up   none  full
        [5]={1    ,0    ,1-h60} -- 300 to 359: full none  down
        })[hue/60-hue/60%1]     -- math.floor(hue/60)
      pwm.setduty(pinR,255*rgbWheel[1])
      pwm.setduty(pinG,255*rgbWheel[2])
      pwm.setduty(pinB,255*rgbWheel[3])
    end
  end
else -- common anode: inverted controll logic
  commonCathode=nil
  return function(valMin,valMax,pinR,pinG,pinB)
    assert(type(valMin)=='number' and type(valMax)=='number','hueLED: Invalid rangeMin/Max')
    pwm.setup(pinR,500,1023) pwm.start(pinR)
    pwm.setup(pinG,500,1023) pwm.start(pinG)
    pwm.setup(pinB,500,1023) pwm.start(pinB)
    return function(val)
      assert(type(val)=='number','hueLED: Invalid value')
      local hue=(val-valMin)/(valMax-valMin)*360%360
      local h60=hue%60/60
      local rgbWheel=({         -- range[deg]: Red  Gren  Blue
        [0]={1    ,  h60,0    },--   0 to  59: full up    none
        [1]={1-h60,1    ,0    },--  60 to 119: down full  none
        [2]={0    ,1    ,  h60},-- 120 to 179: none full  up
        [3]={0    ,1-h60,1    },-- 180 to 239: none down  full
        [4]={  h60,0    ,1    },-- 240 to 299: up   none  full
        [5]={1    ,0    ,1-h60} -- 300 to 359: full none  down
        })[math.floor(hue/60)]  -- or hue/60-hue/60%1
      pwm.setduty(pinR,1023-255*rgbWheel[1])
      pwm.setduty(pinG,1023-255*rgbWheel[2])
      pwm.setduty(pinB,1023-255*rgbWheel[3])
    end
  end
  end
end
