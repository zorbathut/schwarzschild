
local function openConfig()
  print("yoop!")
end

table.insert(Command.Slash.Register("sc"), {openConfig, "Schwarzschild", "config"})
table.insert(Command.Slash.Register("schwarszchild"), {openConfig, "Schwarzschild", "config"})

print("Welcome to Schwarszchild! Type \"/sc\" to open the config.")