--local moduleName = ...
local M = {}
--_G[moduleName] = M

-- list of modules
local mods={'bmp180','dht22','test_met','wifi_init','wifi_ssid'}
local _,m,f

--release memory
function M.unload(...)
  for _,m in pairs(...) do
    if _G[m] then
      print('Unload global: '..m)
      _G[m]=nil
    end
    if package.loaded[m] then
      print('Unload package: '..m)
      package.loaded[m]=nil
    end
  end
end

-- compile modules
function M.compile(...)
  for _,m in pairs(...) do
    f=m..'.lua'
    if file.open(f) then
      print('Compile module: '..f)
      node.compile(f)
      file.remove(f)
    end
  end
end

-- cleanup
function M.clean(restart)
  M.unload(mods)
  M.compile(mods)
  if restart then
    node.restart()
  end
end

return M