
local resynch

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

local new = UI.CreateFrame("RiftButton", "new", scw:GetContent())

local scrolly = sw_MakeScrolly("scroll", scw:GetContent())
scrolly:SetPoint("TOPLEFT", scw:GetContent(), "TOPLEFT", 10, 10)
scrolly:SetPoint("RIGHT", scw:GetContent(), "LEFT", 250, nil)

new:SetPoint("XCENTER", scrolly, "XCENTER")
new:SetPoint("BOTTOM", scw:GetContent(), "BOTTOM", nil, -10)

scrolly:SetPoint("BOTTOM", new, "TOP", nil, -10)

local ok = UI.CreateFrame("RiftButton", "OK", scw:GetContent())
ok:SetText("OK")
ok:SetPoint("BOTTOMRIGHT", scw:GetContent(), "BOTTOMRIGHT", -10, -10)

local setcontent = UI.CreateFrame("Frame", "element", scw:GetContent())
setcontent:SetPoint("TOPRIGHT", scw:GetContent(), "TOPRIGHT", -10, 10)
setcontent:SetPoint("LEFT", scrolly, "RIGHT", 10, nil)
setcontent:SetPoint("BOTTOM", ok, "TOP", nil, -10)

setcontent:SetVisible(false)


-- Now we lay out the content elements

local bigname = UI.CreateFrame("Text", "bigname", setcontent)
bigname:SetFontSize(24)
bigname:SetPoint("TOPCENTER", setcontent, "TOPCENTER")

bigname:SetText("ooga")
bigname:SetHeight(bigname:GetFullHeight())

local bottom = bigname
local function makeElement(name, checke)
  local iddescr = UI.CreateFrame("Text", "idd", setcontent)
  local idbox = UI.CreateFrame("Frame", "idb", setcontent)
  local idtex = UI.CreateFrame("RiftTextfield", "idt", idbox)
  local idtexi = UI.CreateFrame("Text", "idti", idbox)
  local check
  
  if checke then
    check = UI.CreateFrame("RiftCheckbox", "idc", setcontent)
  end

  iddescr:SetFontSize(14)

  idbox:SetPoint("TOP", bottom, "BOTTOM", nil, 10)
  idbox:SetPoint("LEFT", setcontent, "LEFT", 180, nil)
  idtex:SetPoint("TOPLEFT", idbox, "TOPLEFT", 2, 2)
  idtexi:SetAllPoints(idtex)
  idbox:SetPoint("BOTTOMRIGHT", idtex, "BOTTOMRIGHT", 2, 2)

  if checke then
    check:SetPoint("CENTERY", idtex, "CENTERY")
    check:SetPoint("LEFT", setcontent, "LEFT")
    iddescr:SetPoint("LEFT", check, "RIGHT", 10, nil)
  else
    iddescr:SetPoint("LEFT", setcontent, "LEFT")
  end
  
  iddescr:SetPoint("CENTERY", idtex, "CENTERY")
  iddescr:SetText(name)
  iddescr:ResizeToText()

  local function boxit(di)
    if di then
      idbox:SetBackgroundColor(1, 1, 1)
      idtex:SetBackgroundColor(0, 0, 0)
      idtexi:SetVisible(false)
      idtex:SetVisible(true)
    else
      idbox:SetBackgroundColor(0, 0, 0, 0)
      idtex:SetBackgroundColor(0, 0, 0, 0)
      idtexi:SetVisible(true)
      idtex:SetVisible(false)
    end
  end
  
  local function cht(text)
    idtex:SetText(text)
    idtexi:SetText(text)
  end
  
  boxit(true)
  
  function idtex.Event:KeyType(key)
    if key == "\r" then
      idtex:SetKeyFocus(false)
    end
  end
  
  bottom = idbox
  
  return idtex, check, boxit, cht
end


local descr, descrcheck, descrbox, descrcht = makeElement("Custom description", true)
local buffname = makeElement("Buff name")

-- lol radio buttons
local buff = UI.CreateFrame("RiftCheckbox", "buff", setcontent)
local debuff = UI.CreateFrame("RiftCheckbox", "debuff", setcontent)

local bufftext = UI.CreateFrame("Text", "buff", setcontent)
local debufftext = UI.CreateFrame("Text", "debuff", setcontent)

bufftext:SetText("Buff")
bufftext:ResizeToText()
debufftext:SetText("Debuff")
debufftext:ResizeToText()

buff:SetChecked(true)

bufftext:SetPoint("TOP", bottom, "BOTTOM", nil, 10)

buff:SetPoint("LEFT", setcontent, "LEFT", 100, nil)
buff:SetPoint("CENTERY", bufftext, "CENTERY")

bufftext:SetPoint("LEFT", buff, "RIGHT", 10, nil)

debuff:SetPoint("LEFTCENTER", buff, "RIGHTCENTER", 100, 0)
debufftext:SetPoint("LEFTCENTER", debuff, "RIGHTCENTER", 10, 0)

bottom = debufftext

local linked, linkedcheck, linkedbox, linkedcht = makeElement("Linked ability", true)

local delete = UI.CreateFrame("RiftButton", "delete", setcontent)
delete:SetPoint("BOTTOMRIGHT", setcontent, "BOTTOMRIGHT")
delete:SetText("DELETE")




local current_selected = nil
local loading = false
local function readFromConfig()
  loading = true
  
  buffname:SetText(current_selected.buffname or "(New item)")
  descrcht(current_selected.label or buffname:GetText())
  linkedcht(current_selected.linked or buffname:GetText())
  
  bigname:SetText(current_selected.label or buffname:GetText())
  bigname:ResizeToText()
  
  if current_selected.label then
    descrcheck:SetChecked(true)
    descrbox(true)
  else
    descrcheck:SetChecked(false)
    descrbox(false)
  end
  
  if current_selected.linked then
    linkedcheck:SetChecked(true)
    linkedbox(true)
  else
    linkedcheck:SetChecked(false)
    linkedbox(false)
  end
  
  buff:SetChecked(current_selected.scan_buff and true or false)
  debuff:SetChecked(current_selected.scan_debuff and true or false)
  
  setcontent:SetVisible(true)
  
  loading = false
end
local function writeToConfig()
  if loading then return end
  
  current_selected.label = descrcheck:GetChecked() and descr:GetText() or nil
  current_selected.buffname = buffname:GetText()
  current_selected.linked = linkedcheck:GetChecked() and linked:GetText() or nil
  current_selected.scan_buff = buff:GetChecked() and true or nil
  current_selected.scan_debuff = debuff:GetChecked() and true or nil
  
  resynch()
  readFromConfig()
  
  Schwarszchild_Core_Resynch()
end
function descr.Event:TextfieldChange()
  writeToConfig()
end
function buffname.Event:TextfieldChange()
  writeToConfig()
end
function linked.Event:TextfieldChange()
  writeToConfig()
end

function buff.Event:CheckboxChange()
  writeToConfig()
end
function debuff.Event:CheckboxChange()
  writeToConfig()
end
function descrcheck.Event:CheckboxChange()
  writeToConfig()
end
function linkedcheck.Event:CheckboxChange()
  writeToConfig()
end


-- Identifier:
-- Buff name:
-- Buff/Debuff:
-- Rule active on ability:
-- More configuration stuff ~~later~~

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






local csi = nil

new:SetText("NEW")
function new.Event:LeftPress()
  table.insert(Schwarzschild_Config.bars, {buffname = "(New item)"})
  resynch()
  scrolly:Select(#Schwarzschild_Config.bars)
end

function delete.Event:LeftPress()
  table.remove(Schwarzschild_Config.bars, csi)
  csi = nil
  scrolldata = nil
  resynch()
  scrolly:Select(-1000)
  setcontent:SetVisible(false)
end

function resynch()
  local scrolldata = {}
  for k, v in ipairs(Schwarzschild_Config.bars) do
    table.insert(scrolldata, {id = k, label = v.label or v.buffname or "(New item)"})
  end
  table.sort(scrolldata, function (a, b) return a.label < b.label end)
  scrolly:Set(scrolldata)
end

function scrolly:SelectEvent(item)
  current_selected = Schwarzschild_Config.bars[item]
  csi = item
  readFromConfig()
end


function ok.Event:LeftPress()
  scw:SetVisible(false)
  descr:SetKeyFocus(true)
  descr:SetKeyFocus(false)  -- just to get rid of the key focus
end

local function openConfig()
  scw:SetVisible(not scw:GetVisible())
  resynch()
end

table.insert(Command.Slash.Register("sc"), {openConfig, "Schwarzschild", "config"})
table.insert(Command.Slash.Register("schwarszchild"), {openConfig, "Schwarzschild", "config"})

print("Welcome to Schwarszchild! Type \"/sc\" to open the config.")