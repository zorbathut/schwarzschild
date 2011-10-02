
local LAYER_BG = -1
local LAYER_NORMAL = 0
local LAYER_FG = 1
local LAYER_DIVIDER = 2

local baked_config = {}
local buff_list = {
  -- Chloro/Archon
  "Radiant Spores", "Withering Vine", "Searing Vitality", "Pillaging Stone",
  
  -- nld
  "Life Leech", "Looming Demise", "Necrosis", "Plague Bolt>Deathly Calling", "Searing Vitality", "Pillaging Stone", "Neddra's Torture",
  
  -- Archon
  "Arcane Aegis", "Burning Purpose", "Shared Vigor", "Tempered Armor", "Vitality of Stone",
  "Ashen Defense", "Crumbling Resistance", "Earthen Barrage", "Lingering Dust", "Pillaging Stone", "Searing Vitality", 
  
  -- wogue
  "Combat Pose", "Virulent Poison", "Planebound Resilience",
}

local buffs = {}
for k, v in ipairs(buff_list) do
  local src, dest = v:match("(.*)>(.*)")
  if src then
    buffs[dest] = src
  else
    buffs[v] = v
  end
end

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
local width = 250
local offset = 1
local totalwidth = 10 + offset

local context = UI.CreateContext("context")
local anchor = UI.CreateFrame("Frame", "Anchor", context)
anchor:SetPoint("CENTER", UIParent, "BOTTOMCENTER", -(width + height) / 2 + height, -400)
anchor:SetWidth(0)
anchor:SetHeight(0)

local function translateTime(time)
  local cpos = (time + offset - Inspect.Time.Frame()) / totalwidth
  if cpos < 0 then return 0 end
  if cpos > 1 then return width end
  return width * cpos
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
    self.existing[#self.existing].b = math.min(self.existing[#self.existing].b, Inspect.Time.Frame())
    self.existing[#self.existing].c = math.min(self.existing[#self.existing].c, Inspect.Time.Frame())
    self.mutated = true
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
    while #self.existing > 0 and self.existing[1].c < Inspect.Time.Frame() - offset do table.remove(self.existing, 1) end
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

local function revisualize()
  table.sort(arrangement, function (a, b)
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
  
  for i = 0, totalwidth - offset, gcd do
    local whitebar = UI.CreateFrame("Frame", "divider", context)
    whitebar:SetLayer(LAYER_DIVIDER)
    whitebar:SetPoint("TOPCENTER", anchor, "CENTER", translateTime(i + Inspect.Time.Frame()), -barpassthrough)
    whitebar:SetHeight(barpassthrough * 2)
    whitebar:SetWidth(1)
    if i == 0 then
      whitebar:SetBackgroundColor(1, 1, 1, 0.5)
    else
      whitebar:SetBackgroundColor(1, 1, 1, 0.2)
    end
    table.insert(dividers, whitebar)
  end
end

local mutated = false
local function buffNotify(entity, newbuffs)
  if not (entity == Inspect.Unit.Lookup("player") or entity == Inspect.Unit.Lookup("player.target")) then return end
  
  local playerId = Inspect.Unit.Lookup("player")
  
  local buffdetails = Inspect.Buff.Detail(entity, newbuffs)
  for k, v in pairs(buffdetails) do
    if buffs[v.name] and (not v.caster or v.caster == playerId) then
      mutated = true
      register(k, v)
    end
  end
end
local function buffStrip(entity, removedbuffs)
  if not (entity == Inspect.Unit.Lookup("player") or entity == Inspect.Unit.Lookup("player.target")) then return end
  
  for k, v in pairs(bars) do
    if removedbuffs[v.lastid] then
      v:Canceled()
      mutated = true
    end
  end
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
--[[table.insert(Library.LibUnitChange.Register("player"), {
  function (id)
    playerId = id
    if playerId then playerinit() end
  end,
"Schwarzschild", "update.player"})
table.insert(Library.LibUnitChange.Register("target"), {
  function (id)
    print("targchange")
    targetId = id
  end,
"Schwarzschild", "update.target"})]]

table.insert(Event.Buff.Add, {buffNotify, "Schwarzschild", "buff+"})
table.insert(Event.Buff.Remove, {buffStrip, "Schwarzschild", "buff-"})


local function abilityAdd(abilities)
  local ad = Inspect.Ability.Detail(abilities)
  for k, v in pairs(ad) do
    local name = v.name
    for tk, tv in pairs(buffs) do
      if tv == name then
        abilityname[k] = v.name
        
        if not bars[tk] then
          bars[tk] = MakeBar({name = tk, abilityicon = v.icon})
        end
        
        local found
        for ttk, ttv in ipairs(arrangement) do
          if ttv == bars[tk] then
            found = true
          end
        end
        
        if not found then
          bars[tk]:SetVisible(true)
          table.insert(arrangement, bars[tk])
          mutated = true
        end
      end
    end
  end
end
local function abilityRemove(abilities)
  for k, _ in pairs(abilities) do
    local name = abilityname[k]
    if name then
      for tk, tv in pairs(buffs) do
        if tv == name then
          if bars[tk] then
            for ttk, ttv in ipairs(arrangement) do
              if ttv == bars[tk] then
                assert(ttv.name == tk)
                table.remove(arrangement, ttk)
                ttv:SetVisible(false)
                mutated = true
                break
              end
            end
          end
        end
      end
    end
  end
end
table.insert(Event.Ability.Add, {abilityAdd, "Schwarzschild", "ability+"})
table.insert(Event.Ability.Remove, {abilityRemove, "Schwarzschild", "ability-"})
