--[[
pms3003.lua for ESP8266 with nodemcu-firmware
  Read Particulated Matter (PM) concentrations on air from a
  PMS3003 (aka G3) sensor from http://www.plantower.com/.
  It can also read from PMS1003 (aka G1), PMS2003 (aka G2),
  PMS5003 (aka G5) and PMS7003 (aka G7) sensors (untested).
  More info at  https://github.com/avaldebe/AQmon

Written by Álvaro Valdebenito.

MIT license, http://opensource.org/licenses/MIT

Sampling:
- 1 shot/on demand.
- ~650 ms sample & decoding.
- pin3 (SET) of the PMS3003 controles operation mode.
  SET=H(>2.7V; hardware default) continious sampling, SET=L(<0.8V) standby.

Module output;
- Particulate Mater (PM):
  - All PMSx003 sensors.
  - pm01: PM ug/m3 from particles with diameter <= 1.0 um.
  - pm25: PM ug/m3 from particles with diameter <= 2.5 um.
  - pm10: PM ug/m3 from particles with diameter <= 10. um.
- Particle (number) Size Distribution (PSD):
  - Only from PMS1003, PMS5003 and PMS7003 sensors.
  - psd[1]: #particles/100cm3 with 0.3 um < diam <= 0.5 um.
  - psd[2]: #particles/100cm3 with 0.5 um < diam <= 1.0 um.
  - psd[3]: #particles/100cm3 with 1.0 um < diam <= 2.5 um.
  - psd[4]: #particles/100cm3 with 2.5 um < diam <= 5.0 um.
  - psd[5]: #particles/100cm3 with 5.0 um < diam <= 10. um.
]]

local M={
  name=...,   -- module name, upvalue from require('module-name')
  model=3,    -- sensor model: PMSx003 (aka Gx)
  mlen=nil,   -- lenght of PMSx003 message
  stdATM=nil, -- use standatd atm correction instead of TSI standard
  verbose=nil,-- verbose output
  debug=nil,  -- additional ckecks
  pm01=nil,   -- integer value of PM 1.0 [ug/m3]
  pm25=nil,   -- integer value of PM 2.5 [ug/m3]
  pm10=nil,   -- integer value of PM 10. [ug/m3]
  psd=nil     -- particle (number) size distribution [#/100cm3]
}
_G[M.name]=M

--[[ Sensor data format
PMS2003, PMS3003:
  24 byte long messages via UART 9600 8N1 (3.3V TTL).
DATA(MSB,LSB): Message header (4 bytes), 2 pairs of bytes (MSB,LSB)
  -1(  1,  2): Begin message       (hex:424D, ASCII 'BM')
   0(  3,  4): Message body length (hex:0014, decimal 20)
DATA(MSB,LSB): Message body (28 bytes), 10 pairs of bytes (MSB,LSB)
   1(  5,  6): PM 1.0 [ug/m3] (TSI standard)
   2(  7,  8): PM 2.5 [ug/m3] (TSI standard)
   3(  9, 10): PM 10. [ug/m3] (TSI standard)
   4( 11, 12): PM 1.0 [ug/m3] (std. atmosphere)
   5( 13, 14): PM 2.5 [ug/m3] (std. atmosphere)
   6( 15, 16): PM 10. [ug/m3] (std. atmosphere)
   7( 17, 18): no idea.
   8( 19, 19): no idea.
   9( 21, 22): no idea.
  10( 23, 24): cksum=byte01+..+byte22

PMS1003, PMS5003, PMS7003:
  32 byte long messages via UART 9600 8N1 (3.3V TTL).
DATA(MSB,LSB): Message header (4 bytes), 2 pairs of bytes (MSB,LSB)
  -1(  1,  2): Begin message       (hex:424D, ASCII 'BM')
   0(  3,  4): Message body length (hex:001C, decimal 28)
DATA(MSB,LSB): Message body (28 bytes), 14 pairs of bytes (MSB,LSB)
   1(  5,  6): PM 1.0 [ug/m3] (TSI standard)
   2(  7,  8): PM 2.5 [ug/m3] (TSI standard)
   3(  9, 10): PM 10. [ug/m3] (TSI standard)
   4( 11, 12): PM 1.0 [ug/m3] (std. atmosphere)
   5( 13, 14): PM 2.5 [ug/m3] (std. atmosphere)
   6( 15, 16): PM 10. [ug/m3] (std. atmosphere)
   7( 17, 18): num. particles with diameter > 0.3 um in 100 cm3 of air
   8( 19, 19): num. particles with diameter > 0.5 um in 100 cm3 of air
   9( 21, 22): num. particles with diameter > 1.0 um in 100 cm3 of air
  10( 23, 24): num. particles with diameter > 2.5 um in 100 cm3 of air
  11( 25, 26): num. particles with diameter > 5.0 um in 100 cm3 of air
  12( 27, 28): num. particles with diameter > 10. um in 100 cm3 of air
  13( 29, 30): Reserved
  14( 31, 32): cksum=byte01+..+byte30
]]
local function decode(data)
-- check message lenght
  assert(M.debug~=true or #data==M.mlen,('%s: Incomplete message.'):format(M.name))
-- unpack message
  local pms,cksum,blen={},0,#data/2-2
  local n,msb,lsb
  for n=-1,blen do
    msb,lsb=data:byte(2*n+3,2*n+4)  -- 2*char-->2*byte
    pms[n]=msb*0x100+lsb            -- 2*byte-->dec
    cksum=cksum+(n<mlen and msb+lsb or 0)
    if M.debug==true then
      print(('  data#%2d: 0x%02X%02X=%6d cksum:%6d'):
        format(n,msb,lsb,pms[n],cksum))
    end
  end
  msb,lsb,blen,n=nil,nil,nil,nil     -- release memory
  assert(M.debug~=true or (pms[-1]==0x424D and pms[0]==#data-4),
    ('%s: Wrongly phrased message.'):format(M.name))
-- particulate mater (PM)
  if cksum==pms[#pms] and M.stdATM~=true then -- TSI standard
    M.pm01,M.pm25,M.pm10=pms[1],pms[2],pms[3]
  elseif cksum==pms[#pms] then                -- stdATM
    M.pm01,M.pm25,M.pm10=pms[4],pms[5],pms[6]
  else                                        -- failed cksum
    M.pm01,M.pm25,M.pm10=nil,nil,nil
  end
  if M.verbose==true then
    print(('%s: %4s,%4s,%4s [ug/m3]')
      :format(M.name,M.pm01 or 'null',M.pm25 or 'null',M.pm10 or 'null'))
  end
-- particle (number) size distribution (PSD)
  if cksum==pms[#pms] and pms[0]==28 then     -- G1||G5||G7
    psd={}
    for n=1,5 do psd[n]=pms[n+7]-pms[n+6] end
  else                                        -- failed cksum
    psd=nil
  end
  if M.verbose==true and M.psd then
    print(('%s: %4s,%4s,%4s,%4s,%4s [#/100cm3]')
      :format(M.name,unpack(psd)))
  end
end

local pinSET=nil
local init=false
function M.init(pin_set,volatile,status)
-- volatile module
  if volatile==true then
    _G[M.name],package.loaded[M.name]=nil,nil
  end

-- buffer pin set-up
  if type(pin_set)=='number' then
    pinSET=pin_set
    gpio.mode(pinSET,gpio.OUTPUT)
  end

-- initialization
  if type(pinSET)=='number' then
    uart.on('data',0,function(data) end,0)  -- flush the uart buffer
    gpio.write(pinSET,gpio.LOW)             -- low-power standby mode
    if M.verbose==true then
      print(('%s: data acquisition %s.\n  Console %s.')
        :format(M.name,type(status)=='string' and status or 'paused','enhabled'))
    end
    uart.on('data')                         -- release uart
  end
  if not init then
    --sensor G1,G2,G3,n/a,G5,n/a,G7
    M.mlen=({32,24,24,nil,32,nil,32})[M.model]
    M.model=M.mlen and ('PMSx003'):gsub('x',M.model) or nil
  end

-- M.init suceeded if sensor model and message lenght are set
  init=(M.model~=nil)and(M.len~=nil)
  return init
end

function M.read(callBack)
-- ensure module is initialized
  assert(init,('Need %s.init(...) before %s.read(...)'):format(M.name,M.name))
-- check input varables
  assert(type(callBack)=='function' or callBack==nil,
    ('%s.init %s argument should be %s'):format(M.name,'1st','function'))

-- capture and decode message
  uart.on('data',M.mlen*2,function(data)
    local bm=data:find("BM")
    if bm then
  -- stop sampling time-out timer
      tmr.stop(4)
  -- decode message
      decode(data:sub(bm,M.mlen+bm-1))
  -- restore UART & callBack
      M.init(nil,nil,'finished')
      if type(callBack)=='function' then callBack() end
    end
  end,0)

-- start sampling: continuous sampling mode
  if M.verbose==true then
    print(('%s: data acquisition %s.\n  Console %s.')
      :format(M.name,'started','dishabled'))
  end
  gpio.write(pinSET,gpio.HIGH)

-- sampling time-out: 2s after sampling started
  tmr.alarm(4,2000,0,function()
    M.pm01,M.pm25,M.pm10,M.psd=nil,nil,nil,nil
  -- restore UART & callBack
    M.init(nil,nil,'failed')
    if type(callBack)=='function' then callBack() end
  end)
end

return M
