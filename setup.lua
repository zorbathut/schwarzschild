
local context = UI.CreateContext("config")
local scw = UI.CreateFrame("RiftWindow", "window", context)
scw:SetVisible(false)
scw:SetTitle("Schwarszchild Configuration")

scw:SetPoint("CENTER", UIParent, "CENTER")
scw.x = 0
scw.y = 0
scw:SetWidth(700)
scw:SetHeight(700)


local draghandle = UI.CreateFrame("Frame", "draghandle", scw:GetBorder())
draghandle:SetPoint("TOPLEFT", scw:GetBorder(), "TOPLEFT")
draghandle:SetPoint("BOTTOM", scw:GetContent(), "TOP")
draghandle:SetPoint("RIGHT", scw:GetBorder(), "RIGHT")

function draghandle.Event:LeftDown()
  self.dragging = true
  local mpos = Inspect.Mouse()
  self.sx, self.sy = mpos.x, mpos.y
  self.ox, self.oy = scw.x, scw.y
end
function draghandle.Event:LeftUp()
  self.dragging = false
end
function draghandle.Event:MouseMove(x, y)
  if self.dragging then
    scw.x, scw.y = self.ox + x - self.sx, self.oy + y - self.sy
    scw:SetPoint("CENTER", UIParent, "CENTER", scw.x, scw.y)
  end
end




local new = UI.CreateFrame("RiftButton", "new", scw:GetContent())
new:SetText("NEW")

local scrolly = sw_MakeScrolly("scroll", scw:GetContent())
scrolly:SetPoint("TOPLEFT", scw:GetContent(), "TOPLEFT", 10, 10)
scrolly:SetPoint("RIGHT", scw:GetContent(), "LEFT", 250, nil)

new:SetPoint("XCENTER", scrolly, "XCENTER")
new:SetPoint("BOTTOM", scw:GetContent(), "BOTTOM", nil, -10)

scrolly:SetPoint("BOTTOM", new, "TOP", nil, -10)

local tabs = {}
for k = 1, 50 do
  table.insert(tabs, {label = string.format("Label %d", k), id = k})
end
scrolly:Set(tabs)


local ok = UI.CreateFrame("RiftButton", "OK", scw:GetContent())
ok:SetText("OK")
ok:SetPoint("BOTTOMRIGHT", scw:GetContent(), "BOTTOMRIGHT", -10, -10)
function ok.Event:LeftPress()
  scw:SetVisible(false)
end

local function openConfig()
  scw:SetVisible(not scw:GetVisible())
end

table.insert(Command.Slash.Register("sc"), {openConfig, "Schwarzschild", "config"})
table.insert(Command.Slash.Register("schwarszchild"), {openConfig, "Schwarzschild", "config"})

print("Welcome to Schwarszchild! Type \"/sc\" to open the config.")