local Schwarzchild_Config_Version = 1

local default = {v = Schwarzchild_Config_Version, bars = {}, location = {alignment = "BOTTOMCENTER", x = 0, y = -400}}

Schwarzschild_Config = default

local function UpdateConfig()
  -- update stuff here  
  
  assert(Schwarzschild_Config.v == Schwarzchild_Config_Version)
  
  for k, v in pairs(default) do
    if not Schwarzschild_Config[k] then
      Schwarzschild_Config[k] = v
    end
  end
end

table.insert(Event.Addon.SavedVariables.Load.End, {
  function (addon)
    if addon ~= "Schwarzschild" then return end
    UpdateConfig()    
    Schwarzschild_Core_Resynch()
    Schwarzschild_Relocate()
  end, "Schwarzschild", "savedvariables"})
