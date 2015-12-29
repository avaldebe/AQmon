--[[
i2cd.lua for ESP8266 with nodemcu-firmware
  i2c helper functions with pedantic debug checks.
  Meant for development and debug of new modules, not performance.
  For better performance inline i2c calls on target module.
  More info at  https://github.com/avaldebe/AQmon

Written by Álvaro Valdebenito,
  - i2cd.autoscan is based on work by gareth@l0l.org.uk, sancho and zeroday among
    many other open source authors
      http://www.esp8266.com/viewtopic.php?f=19&t=1049#p6198
  - Unsigned to signed conversion, eg uint16_t (unsigned short) to int16_t (short)
      http://stackoverflow.com/questions/17152300/unsigned-to-signed-without-comparison
  - Reserved i2c 7bit addresses
      http://www.totalphase.com/support/articles/200349176#7bit
  - Map internal IO references to GPIO numbers
      https://github.com/nodemcu/nodemcu-firmware/wiki/nodemcu_api_en#new_gpio_map

MIT license, http://opensource.org/licenses/MIT
]]

local M={
  name=...,     -- module name, upvalue from require('module-name')
  pedantic=nil, -- additional (debug) checks, set false to skip checks
}
_G[M.name]=M

local gpio_pin={5,4,0,2,14,12,13}--,15,3,1,9,10}
function M.init(SDA,SCL,volatile,scan)
-- Usage: require('i2cd').init(sda,scl,true,true)
--   Scan add addresses on sda,scl and free module from memory after completetion
-- volatile module
  if volatile==true then
    _G[M.name],package.loaded[M.name]=nil,nil
  end
-- init i2c bus
  i2c.setup(0,SDA,SCL,i2c.SLOW)
-- scan i2c bus
  if scan==true then
    local addr,try
    for addr=0x08,0x77 do   -- 7bit addresses; skip invalid: 0x00..0x07,0x78..0x7F
      for try=1,3 do        -- try each address 3 times
        if M.io(addr) then  -- device responds with ACK?
          print(('%s: Device found at address 0x%02X,')
            ..' SDA %d (GPIO%02d), SCL %d (GPIO%02d) on try %d.')
            :format(M.name,addr,SDA,gpio_pin[SDA],SCL,gpio_pin[SCL],try))
          break
        end
      end
    end
  end
end
function M.autoscan(volatile)
-- Usage: require('i2cd').io(true)
--  Scan all pins and addresses and free module from memory after completetion
  print(('%s: Scanning all pins for I2C devices'):format(M.name))
  local sda,scl
  for scl=1,#gpio_pin do
    for sda=1,#gpio_pin do
      tmr.wdclr()       -- pat the (watch)dog!
      if sda~=scl then  -- if the pins are the same then skip this round
        M.init(sda,scl,volatile,true)
      end
    end
  end
  print(('%s: Scanning completed'):format(M.name))
end

function M.io(addr,...)
-- Usage:
--   wake-up device:           i2cd.io(addr)
--   write adjacent registers: i2cd.io(addr,{1st_reg,reg_val1,...})
--   read adjacent registers:  i2cd.io(addr,{1st_reg},nregs)
  local act=({'wake','write','read'})[arg.n+1]
  assert(pedantic==false or type(addr)=='number' and addr>=0x08 and addr<=0x77,
    ('%s.io(%s,...): Wrong address.')
      :format(M.name,addr and ('0x%02X'):format(addr) or 'nil'))
  assert(pedantic==false or act~=nil and (act=='wake' or type(arg[1])=='table'),
    ('%s.io(0x%02X,...): Wrong call format.'):format(M.name,addr))
-- action: wake-up/write
  i2c.start(0)
  c = i2c.address(0,addr,i2c.TRANSMITTER)
  if act~='wake' then
    assert(pedantic==false or c==true,
      ('%s.io(0x%02X,...): %s address not found.'):format(M.name,addr,act))
    i2c.write(0,unpack(arg[1]))
  end
  i2c.stop(0)
  if act~='read' then return c and addr end -- device found?
-- action: read
  i2c.start(0)
  i2c.address(0,addr,i2c.RECEIVER)
  c = i2c.read(0,arg[2])
  i2c.stop(0)
  assert(pedantic==false or c and #c==arg[2],
    ('%s.io(0x%02X,{0x%02X,...},%d): %s only got %d bytes.')
      :format(M.name,addr,arg[1][1],arg[2],act,c and #c or 0))
  return c
end

function M.int(c,t)
-- Usage:
--  string to integer:
--    uint=i2cd.io(c,'uintLE') --  c (little endian char array) to unsigned int
--    sint=i2cd.io(c,'sintLE') --  c (little endian char array) to (signed) int
--    uint=i2cd.io(c,'uintBE') --  c (big endian char array)    to unsigned int
--    sint=i2cd.io(c,'sintBE') --  c (big endian char array)    to (signed) int
-- unsingned int to (signed) int
--    sint=i2cd.io(uint,1)     --  unit (1 byte,  8 bit) unsigned int to (signed) int
--    sint=i2cd.io(uint,2)     --  unit (2 byte, 16 bit) unsigned int to (signed) int
--    sint=i2cd.io(uint,3)     --  do nothing
-- string to integer
  if type(c)=='string' then
    local s=({uintLE=false,sintLE=true ,uintBE=false,sintBE=true})[t] -- signed
    local b=({uintLE=false,sintLE=false,uintBE=true ,sintBE=true})[t] -- bigendian
             and 1 or -1
    assert(pedantic==false or s~=nil,
      ("%s.int: Wrong int type %q"):format(M.name,t or 'nil'))
    local r,n=0,0
    for n=1,#c do r=r*0x100+c:byte(n*b) end
    if not s then return r end
    t,c=#c,r
  end
-- unsingned to signed
  if type(c)=='number' then
  -- first negative number
    -- 1 byte: uint8_t (unsigned char ): 2^7
    -- 2 byte: uint16_t(unsigned short): 2^15
    -- 4 byte: uint32_t(unsigned long ): 2^31
    t=({0x80,0x8000,nil,0,char=0x80,short=0x8000,long=0})[t]
    assert(pedantic==false or t~=nil,
      ("%s.int: Wrong int #bytes %q"):format(M.name,t or 'nil'))
    return c-bit.band(c,t)*2
  end
-- Catch other/unsuported types
  assert(pedantic==false,
    ("%s.int: Wrong type(c) %q"):format(M.name,type(c)))
  return nil
end

return M
