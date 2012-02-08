
local LAYER_BG = -1
local LAYER_NORMAL = 0
local LAYER_FG = 1
local LAYER_DIVIDER = 2

local baked_config = {}

local buffs = {}

local arrangement = {}
local bars = {}
local abilityname = {}
local gcd = 1.5
local transition = 0.3

local dividers = {}
local barpassthrough = 2
local lastbarheight = -1

local height = 24
local border = 2
local width = 400

local seg1start = -1
local seg1end = 10
local seg1width = 250

local playerId
local targetId
local targetTargetId

local context = UI.CreateContext("context")

local m_anchor = UI.CreateFrame("Frame", "MAnchor", context)
m_anchor:SetWidth(0)
m_anchor:SetHeight(0)
m_anchor:SetPoint("CENTER", UIParent, "BOTTOMCENTER", 0, -400)

-- center based on the m_anchor
local anchor = UI.CreateFrame("Frame", "Anchor", context)
anchor:SetPoint("CENTER", m_anchor, "BOTTOMCENTER", -(width + height) / 2 + height, 0)
anchor:SetWidth(0)
anchor:SetHeight(0)

local function translateTime(time)
  local tofs = time - Inspect.Time.Frame()
  local cpos = (tofs - seg1start) / (seg1end - seg1start)
  if cpos < 0 then return 0 end
  if cpos < 1 then return seg1width * cpos end
  
  tofs = tofs - seg1end
  
  return math.min(math.log(tofs + 1) * (seg1width / seg1end --[[needed to match slopes]] ) + seg1width, width)
end

local function MakeBar(buffdetails)
  local bar = UI.CreateFrame("Frame", "Bar", context)
  bar:SetBackgroundColor(0, 0, 0)
  bar:SetHeight(height)
  bar:SetWidth(width)
  
  local icon = UI.CreateFrame("Texture", "Icon", bar)
  icon:SetPoint("TOPRIGHT", bar, "TOPLEFT")
  icon:SetHeight(height)
  icon:SetWidth(height)
  icon:SetTexture("Rift", buffdetails.icon or buffdetails.abilityicon)
  
  local cover = UI.CreateFrame("Frame", "Bar", bar)
  cover:SetPoint("TOPLEFT", icon, "TOPLEFT")
  cover:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT")
  cover:SetBackgroundColor(0, 0, 0, 0.5)
  cover:SetVisible(false)
  cover:SetLayer(10)
  
  bar.x = 0
  bar.y = 0
  bar.ex = 0
  bar.ey = 0
  bar.t = 0
  
  bar.name = buffdetails.name
  
  bar.yellow = {}
  bar.green = {}
  local function MakeMiniBar(r, g, b)
    local mbar = UI.CreateFrame("Frame", "Minibar", bar)
    mbar:SetPoint("TOP", bar, "TOP", nil, border)
    mbar:SetPoint("BOTTOM", bar, "BOTTOM", nil, -border)
    mbar:SetBackgroundColor(r, g, b)
    return mbar
  end
  
  bar.existing = {}
  function bar:Update(id, detail)
    if not detail then return end -- probably shouldn't happen
    if self.lastid ~= id then
      self.lastid = id
      self.lastbegin = detail.begin
      self.lastend = detail.begin + detail.duration
      for _, v in ipairs(self.existing) do
        v.b = math.min(v.b, detail.begin)
        v.c = math.min(v.c, detail.begin)
      end
      table.insert(self.existing, {a = detail.begin, b = detail.begin + detail.duration - gcd, c = detail.begin + detail.duration})
      self.mutated = true
    end
  end
  function bar:Canceled()
    if #self.existing == 0 then
      return
    end
    self.existing[#self.existing].b = math.min(self.existing[#self.existing].b, Inspect.Time.Frame())
    self.existing[#self.existing].c = math.min(self.existing[#self.existing].c, Inspect.Time.Frame())
    self.mutated = true
    self.lastid = nil
    self.lastbegin = nil
    self.lastend = Inspect.Time.Frame()
  end
  function bar:MoveTo(tx, ty)
    if self.ex ~= tx or self.ey ~= ty then
      self.sx, self.sy = self.x, self.y
      self.ex, self.ey = tx, ty
      self.t = Inspect.Time.Frame() + transition
      if self.mutated then
        self.tm = 1
        if self.ey > self.sy then
          bar:SetLayer(LAYER_BG)
          cover:SetVisible(true)
        else
          bar:SetLayer(LAYER_FG)
          bar:SetAlpha(0.5)
        end
      else
        -- keep our previous sfx settings
        self.tm = 0
      end
    end
    self.mutated = false
  end
  function bar:Tick()
    while #self.existing > 0 and self.existing[1].c < Inspect.Time.Frame() + seg1start do table.remove(self.existing, 1) end
    while #self.yellow < #self.existing do
      table.insert(self.yellow, MakeMiniBar(0, 0.5, 0.5))
      table.insert(self.green, MakeMiniBar(0, 0.8, 0))
    end
      
    for k, v in ipairs(self.existing) do
      self.yellow[k]:SetVisible(true)
      self.green[k]:SetVisible(true)
      self.yellow[k]:SetPoint("LEFT", bar, "LEFT", translateTime(v.a), nil)
      self.yellow[k]:SetPoint("RIGHT", bar, "LEFT", translateTime(v.b), nil)
      self.green[k]:SetPoint("LEFT", bar, "LEFT", translateTime(v.b), nil)
      self.green[k]:SetPoint("RIGHT", bar, "LEFT", translateTime(v.c), nil)
    end
    for i = #self.existing + 1, #self.yellow do
      self.yellow[i]:SetVisible(false)
      self.green[i]:SetVisible(false)
    end
    
    if self.t > Inspect.Time.Frame() then
      local it = (self.t - Inspect.Time.Frame()) / transition
      local t = 1 - it
      local sp = math.sqrt(it - it*it)
      if t < 0 then t, sp = 0, 0 end
      self.x, self.y = self.sx*it+self.ex*t+(self.sy-self.ey)*sp*self.tm, self.sy*it+self.ey*t+(self.ex-self.sx)*sp*self.tm
    else
      self.x, self.y = self.ex, self.ey
      bar:SetLayer(LAYER_FG)
      bar:SetAlpha(1)
      cover:SetVisible(false)
    end
    
    self:SetPoint("TOPLEFT", anchor, "CENTER", self.x, self.y)
  end
  function bar:Finalize(details)
    icon:SetTexture("Rift", details.icon)
    self.finalized = true
  end
  
  return bar
end

local function register(id, detail)
  if not bars[detail.name] then
    bars[detail.name] = MakeBar(detail)
    table.insert(arrangement, bars[detail.name])
  end
  
  local bar = bars[detail.name]
  if not bar.finalized then
    bar:Finalize(detail)
  end
  
  bar:Update(id, detail)
end

local function stablesort(tab, predicate)
  local n = #tab
  while n > 1 do
    local newn = 0
    for i = 2, n do
      if predicate(tab[i], tab[i - 1]) then
        tab[i], tab[i - 1] = tab[i - 1], tab[i]
        newn = i
      end
    end
    n = newn
  end
end

local function revisualize()
  stablesort(arrangement, function (a, b)
    if a.lastend and b.lastend then return a.lastend < b.lastend end
    if not a.lastend and not b.lastend then return a.name < b.name end
    return b.lastend
  end)
    
  for k, v in ipairs(arrangement) do
    v:MoveTo(0, (k - 1) * height)
  end
  
  local theight = barpassthrough * 2 + #arrangement * height
  if theight ~= lastbarheight then
    lastbarheight = theight
    for k, v in ipairs(dividers) do
      v:SetHeight(theight)
    end
  end
end

local initted = false
local function playerinit()
  if initted then return end
  
  local detail = Inspect.Unit.Detail("player")
  
  if not detail or not detail.calling then return end
  
  initted = true
  
  if detail.calling == "rogue" then
    gcd = 1
  end
  
  local function makebar(coord, tex)
    local whitebar = UI.CreateFrame("Frame", "divider", context)
    whitebar:SetLayer(LAYER_DIVIDER)
    whitebar:SetPoint("TOPCENTER", anchor, "CENTER", translateTime(coord + Inspect.Time.Frame()), -barpassthrough)
    whitebar:SetHeight(barpassthrough * 2)
    whitebar:SetWidth(1)
    if coord == 0 then
      whitebar:SetBackgroundColor(1, 1, 1, 0.5)
    else
      whitebar:SetBackgroundColor(1, 1, 1, 0.2)
    end
    table.insert(dividers, whitebar)
    
    if tex then
      local text = UI.CreateFrame("Text", "dividertext", context)
      text:SetText(tex)
      text:SetFontSize(8)
      text:SetBackgroundColor(0, 0, 0)
      text:ResizeToText()
      text:SetPoint("BOTTOMCENTER", whitebar, "TOPCENTER", 0, -1)
    end
  end
  
  for i = 0, seg1end, gcd do
    makebar(i)
  end
  makebar(15, "15")
  makebar(30, "30")
  makebar(60, "1m")
  makebar(60*2, "2m")
  makebar(60*5, "5m")
end

local function active(entity)
  if entity == playerId then return true end
  if entity == targetId then return true end
  if not targetId and entity == targetTargetId then return true end
end

local buffEntityMap = {}

local mutated = false
local function buffNotify(entity, newbuffs)
  if not newbuffs then return end
  if not active(entity) then return end
  
  local buffdetails = Inspect.Buff.Detail(entity, newbuffs)
  for k, v in pairs(buffdetails) do
    if buffs[v.name] and (not v.caster or v.caster == playerId or buffs[v.name].include_others) then
      if (buffs[v.name].scan_buff and entity == playerId) or (buffs[v.name].scan_debuff and entity ~= playerId) then
        mutated = true
        register(k, v)
        if not buffEntityMap[entity] then
          buffEntityMap[entity] = {}
        end
        buffEntityMap[entity][k] = true
      end
    end
  end
end
local function buffStrip(entity, removedbuffs)
  if entity ~= playerId and entity ~= targetId and entity ~= targetTargetId then return end
  
  for k, v in pairs(bars) do
    if buffs[v.name] then
      if (buffs[v.name].scan_buff and entity == playerId) or (buffs[v.name].scan_debuff and entity ~= playerId) then
        if removedbuffs[v.lastid] then
          v:Canceled()
          mutated = true
          if buffEntityMap[entity] then
            buffEntityMap[entity][k] = nil
          end
        end
      end
    end
  end
end
local function buffStripEntity(entity)
  if not entity then return end
  if buffEntityMap[entity] then
    buffStrip(entity, buffEntityMap[entity])
  end
  buffEntityMap[entity] = nil
end

local function tick()
  playerinit()
  
  if mutated then
    mutated = false
    revisualize()
  end
  
  for k, v in ipairs(arrangement) do
    v:Tick()
  end
end

table.insert(Event.System.Update.Begin, {tick, "Schwarzschild", "update.loop"})

table.insert(Event.Buff.Add, {buffNotify, "Schwarzschild", "buff+"})
table.insert(Event.Buff.Remove, {buffStrip, "Schwarzschild", "buff-"})




function Schwarzschild_Core_Resynch()
  if not Inspect.Ability.List() then return end
  
  local abi = Inspect.Ability.Detail(Inspect.Ability.List())
  local abis = {}
  for _, v in pairs(abi) do
    abis[v.name] = v.icon
  end
  
  local bufficon = {}
  buffs = {}
  for _, v in ipairs(Schwarzschild_Config.bars) do
    local item = v.linked or v.buffname
    if abis[item] then
      buffs[v.buffname] = v
      if not bars[v.buffname] then
        bars[v.buffname] = MakeBar({name = v.buffname, abilityicon = abis[v.buffname] or abis[item]})
      end
    end
  end
  
  -- Now we have all the right bars. First, go through arrangement and strip out dead things, then pass through buffs and add live things
  local narrangement = {}
  local donerrangement = {}
  for ttk, ttv in ipairs(arrangement) do
    if buffs[ttv.name] then
      table.insert(narrangement, ttv)
      donerrangement[ttv.name] = true
    else
      ttv:SetVisible(false)
      mutated = true
    end
  end
  
  for ttk, ttv in pairs(buffs) do
    if not donerrangement[ttk] then
      table.insert(narrangement, bars[ttk])
      bars[ttk]:SetVisible(true)
      mutated = true
    end
  end
  
  arrangement = narrangement
end

table.insert(Event.Ability.Add, {Schwarzschild_Core_Resynch, "Schwarzschild", "ability+"})
table.insert(Event.Ability.Remove, {Schwarzschild_Core_Resynch, "Schwarzschild", "ability-"})


table.insert(Library.LibUnitChange.Register("player"), {
  function (id)
    playerId = id
  end,
"Schwarzschild", "update.player"})
playerId = Inspect.Unit.Lookup("player")

local function fullRefresh()
  if targetId then
    buffNotify(targetId, Inspect.Buff.List(targetId))
  elseif targetTargetId then
    buffNotify(targetTargetId, Inspect.Buff.List(targetTargetId))
  end
end

table.insert(Library.LibUnitChange.Register("player.target"), {
  function (id)
    if id then
      local iud = Inspect.Unit.Detail(id)
      if iud and iud.relation == "friendly" then
        id = false
      end
    end
    
    buffStripEntity(targetId)
    
    targetId = id
    
    fullRefresh()
  end,
"Schwarzschild", "update.target"})
targetId = Inspect.Unit.Lookup("player.target")

table.insert(Library.LibUnitChange.Register("player.target.target"), {
  function (id)
    if id then
      local iud = Inspect.Unit.Detail(id)
      if iud and iud.relation == "friendly" then
        id = false
      end
    end
    
    buffStripEntity(targetTargetId)
    
    targetTargetId = id
    
    fullRefresh()
  end,
"Schwarzschild", "update.target"})
targetTargetId = Inspect.Unit.Lookup("player.target.target")




-- Movability
local movables = UI.CreateFrame("Frame", "movables", context)
movables:SetVisible(false)
do
  local movehandle = UI.CreateFrame("Text", "movehandle", movables)
  movehandle:SetFontSize(10)
  movehandle:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, -2)
  movehandle:SetText("Move: 0, 0")
  movehandle:SetHeight(movehandle:GetFullHeight())
  movehandle:SetWidth(100)
  movehandle:SetBackgroundColor(0, 0, 0)
  
  function movehandle.Event:LeftDown()
    self.moving = true
    local mouseData = Inspect.Mouse()
    self.sx = Schwarzschild_Config.location.x - mouseData.x
    self.sy = Schwarzschild_Config.location.y - mouseData.y
  end

  function movehandle.Event:MouseMove(x, y)
    if self.moving then
      Schwarzschild_Config.location.x = x + self.sx
      Schwarzschild_Config.location.y = y + self.sy
      
      Schwarzschild_Relocate()
    end
  end

  function movehandle.Event:LeftUp()
    self.moving = false
  end
  function movehandle.Event:LeftUpoutside()
    self.moving = false
  end
  
  local anchorhandle = UI.CreateFrame("Text", "anchorhandle", movables)
  anchorhandle:SetFontSize(10)
  anchorhandle:SetPoint("BOTTOMLEFT", movehandle, "BOTTOMRIGHT", 2, 0)
  anchorhandle:SetText("Alignment: BOTTOMCENTER")
  anchorhandle:SetPoint("TOP", movehandle, "TOP")
  anchorhandle:SetHeight(movehandle:GetFullHeight())
  anchorhandle:SetWidth(150)
  anchorhandle:SetBackgroundColor(0, 0, 0)
  
  local points = {
    {"TOPLEFT", 0, 0},
    {"TOPCENTER", 0.5, 0},
    {"TOPRIGHT", 1, 0},
    {"CENTERLEFT", 0, 0.5},
    {"CENTER", 0.5, 0.5},
    {"CENTERRIGHT", 1, 0.5},
    {"BOTTOMLEFT", 0, 1},
    {"BOTTOMCENTER", 0.5, 1},
    {"BOTTOMRIGHT", 1, 1}
  }
    
  function anchorhandle.Event:LeftClick()
    local cidx
    for i = 1, #points do
      if points[i][1] == Schwarzschild_Config.location.alignment then
        cidx = i
      end
    end
    if not cidx then cidx = #points end
    cidx = cidx + 1
    if cidx > #points then cidx = 1 end
    Schwarzschild_Config.location.alignment = points[cidx][1]
    
    Schwarzschild_Config.location.x = (points[cidx][2] * 2 - 1) * -300
    Schwarzschild_Config.location.y = (points[cidx][3] * 2 - 1) * -300
    
    dump(Schwarzschild_Config.location)
    
    Schwarzschild_Relocate()
  end

  
  function Schwarzschild_Relocate()
    m_anchor:SetPoint("CENTER", UIParent, Schwarzschild_Config.location.alignment, Schwarzschild_Config.location.x, Schwarzschild_Config.location.y)
    movehandle:SetText(string.format("Move: %d, %d", Schwarzschild_Config.location.x, Schwarzschild_Config.location.y))
    anchorhandle:SetText(string.format("Alignment: %s", Schwarzschild_Config.location.alignment))
  end
  
  function Schwarzschild_Changemove(visible)
    movables:SetVisible(visible)
  end
end

