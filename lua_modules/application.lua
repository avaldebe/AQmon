print('Tidy up')
require('upkeep').clean()

print('Start WiFi')
require('wifi_init').connect()
if wifi.sta.status()~=5 then
  node.restart() -- connection failed
end
-- verbose
require('test_met').read(true)
