local Schwarzchild_Config_Version = 1

Schwarzschild_Config = {v = Schwarzchild_Config_Version, bars = {}}

local function UpdateConfig()
  -- update stuff here
  
  assert(Schwarzschild_Config.v == Schwarzchild_Config_Version)
end

table.insert(Event.Addon.SavedVariables.Load.End, {
  function (addon)
    if addon ~= "Schwarzchild" then return end
    
    UpdateConfig()
    
    Schwarszchild_Core_Resynch()
  end, "Schwarzschild", "savedvariables"})
