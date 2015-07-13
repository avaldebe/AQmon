local moduleName = ...
local M = {}
_G[moduleName] = M

local id = 0
local ADDR,SDA,SCL -- buffer device address and pinout

-- 2 bits to signed/unsigned int
function M.b2i(MSB,LSB,signed)
  local w=MSB*256+LSB
  return signed and (w>32767) and (w-65536) or w
end

-- 3 bits to unsigned long
function M.b3i(MSB,LSB,XLSB)
  return MSB*65536+LSB*256+XLSB
end

-- initialize i2c
function M.init(addr,sda,scl)
  if (addr and addr~=ADDR) then
    ADDR=addr
  end
  if (sda and sda~=SDA) or (scl and scl~=SCL) then
    SDA,SCL=sda,scl
    i2c.setup(id,SDA,SCL,i2c.SLOW)
  end
end

-- wakeup device
function M.wake()
  i2c.start(id)
  i2c.address(id,ADDR,i2c.TRANSMITTER)
  i2c.stop(id)
end

-- write data register
-- ...: register,values to write to the register
function M.write(...)
  i2c.start(id)
  i2c.address(id,ADDR,i2c.TRANSMITTER)
  i2c.write(id,...)
  i2c.stop(id)
end

-- read data register
-- len: bytes to read
function M.read(len)
  i2c.start(id)
  i2c.address(id,ADDR,i2c.RECEIVER)
  local c = i2c.read(id,len)
  i2c.stop(id)
  return c
end

return M
