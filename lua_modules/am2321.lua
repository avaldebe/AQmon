local moduleName = ...
local M = {}
_G[moduleName] = M

local ADDR=bit.rshift(0xB8,1) -- use 7bit address
local id=0  -- i2c interface ID
local t,h   -- temperature and humidity

local function short(MSB,LSB,signed)
  local w=MSB*256+LSB
  return signed and (w>32767) and (w-65536) or w
end

local function crc_check(c)
  local len=c:len()
  local crc=0xFFFF
  local l,i
  for l=1,len-2 do
    crc=bit.bxor(crc,c:byte(l))
    for i=1,8 do
      if bit.band(crc,1) ~= 0 then
        crc=bit.rshift(crc,1)
        crc=bit.bxor(crc,0xA001)
      else
        crc=bit.rshift(crc,1)
      end
    end
  end
  return (crc==short(c:byte(len),c:byte(len-1)))
end

function M.init(da,cl)
  local sda,scl=da,cl
  i2c.setup(id, sda, scl, i2c.SLOW)
end

function M.read()
-- wakeup
  i2c.start(id)
  i2c.address(id,ADDR,i2c.RECEIVER)
  i2c.stop(id)
-- request HUMIDITY_MSB 0x00 .. TEMPERATURE_LSB 0x03
  i2c.start(id)
  i2c.address(id,ADDR,i2c.TRANSMITTER)
  i2c.write(id,0x03,0x00,0x04)
  i2c.stop(id)
  tmr.delay(1600)         -- wait at least 1.5ms
-- read HUMIDITY_MSB 0x00 .. TEMPERATURE_LSB 0x03
  i2c.start(id)
  i2c.address(id,ADDR,i2c.RECEIVER)
  local c=i2c.read(id,8)  -- cmd(2)+data(4)+crc(2)
  i2c.stop(id)

  if crc_check(c) then
    h=short(c:byte(3,4))
    t=short(c:byte(5,6))
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
