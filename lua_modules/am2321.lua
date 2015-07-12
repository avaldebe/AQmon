local moduleName = ...
local M = {}
_G[moduleName] = M

local ADDR = bit.rshift(0xB8,1) -- use 7bit address
local id = 0 -- i2c interface ID
local t,h    -- temperature and humidity

local function crc_check(str)
  local len=str:len()
  local crc=0xFFFF
  local l,i,crc16
  for l=1,len-2 do
    crc=bit.bxor(crc,str:byte(l))
    for i=1,8 do
      if bit.band(crc,1) ~= 0 then
        crc=bit.rshift(crc,1)
        crc=bit.bxor(crc,0xA001)
      else
        crc=bit.rshift(crc,1)
      end
    end
  end
  crc16=str:byte(len-1)+str:byte(len)*256
  return (crc==crc16)
end

function M.init(sda, scl)
  i2c.setup(id, sda, scl, i2c.SLOW)
end

function M.read()
  local str
-- wakeup
  i2c.start(id)
  i2c.address(id, ADDR, i2c.RECEIVER)
  i2c.stop(id)
-- request HUMIDITY_MSB 0x00 .. TEMPERATURE_LSB 0x03
  i2c.start(id)
  i2c.address(id, ADDR, i2c.TRANSMITTER)
  i2c.write(id,0x03,0x00,0x04)
  i2c.stop(id)
  tmr.delay(1600)     -- wait at least 1.5ms
-- read HUMIDITY_MSB 0x00 .. TEMPERATURE_LSB 0x03
  i2c.start(id)
  i2c.address(id, ADDR, i2c.RECEIVER)
  str=i2c.read(id,8)  -- cmd(2)+data(4)+crc(2)
  i2c.stop(id)

  if crc_check(str) then
    h=str:byte(3)*256+str:byte(4)
    t=str:byte(5)*256+str:byte(6)
  else
    h,t=nil,nil
  end
  --return h,t
end

function M.getTemperature()
  return t
end

function M.getHumidity()
  return h
end

return M
