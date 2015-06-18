--[[
upkeep.lua for nodemcu-devkit (ESP8266) with nodemcu-firmware
  Utilities to compile *.lua files and release loaded packages. 

Written by Álvaro Valdebenito

MIT license, http://opensource.org/licenses/MIT
]]


--local moduleName = ...
local M = {}
--_G[moduleName] = M

-- list of modules
local mods,f,m={}

--release memory
function M.unload(...)
  for f,m in pairs(...) do
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
  for f,m in pairs(...) do
    if f:match('(%a+).lua$') then
      print('Compile module: '..f)
      node.compile(f)
      file.remove(f)
    end
  end
end

-- cleanup
function M.clean(restart)
  for f,m in pairs(file.list()) do
    m=f~='init.lua' and f:match('(%a+).lua$') or f:match('(%a+).lc$')
    if m then
    --print(('%s: %s'):format(m,f))
      mods[f]=m
    end 
  end
  M.unload(mods)
  M.compile(mods)
  if restart then
    node.restart()
  end
end

return M
