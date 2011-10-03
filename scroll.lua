
function sw_MakeScrolly(name, parent)
  local barwidth = 10
  
  local main = UI.CreateFrame("Frame", name, parent)
  
  local textzone = UI.CreateFrame("Mask", name .. "Textzone", main)
  local barzone = UI.CreateFrame("Frame", name .. "Barzone", main)
  barzone:SetPoint("TOPRIGHT", main, "TOPRIGHT")
  barzone:SetPoint("BOTTOM", main, "BOTTOM")
  barzone:SetWidth(barwidth)
  
  local litbar = UI.CreateFrame("Frame", name .. "Litbar", barzone)
  litbar:SetPoint("TOPLEFT", barzone, "TOPLEFT")
  litbar:SetPoint("RIGHT", barzone, "RIGHT")
  litbar:SetBackgroundColor(1, 1, 1)
  
  textzone:SetPoint("TOPLEFT", main, "TOPLEFT")
  textzone:SetPoint("BOTTOMRIGHT", barzone, "BOTTOMLEFT", -barwidth, 0)
  
  barzone:SetBackgroundColor(0, 0, 0, 0.5)
  textzone:SetBackgroundColor(0, 0, 0, 0.5)
  
  main:SetBackgroundColor(0, 0, 0, 0.5)
  
  local text_anchor = UI.CreateFrame("Frame", name .. "Anchor", textzone)
  text_anchor:SetPoint("BOTTOMLEFT", textzone, "TOPLEFT")
  
  local words = {}
  local items = {}
  
  local item_height = 0
  
  words[0] = text_anchor
  
  local anchor = 0
  local anchor_max = 0
  local litbar_play = 0
  local function moveAnchorTo(newpos)
    anchor = math.min(math.max(newpos, 0), anchor_max)
    text_anchor:SetPoint("BOTTOMLEFT", textzone, "TOPLEFT", 0, -anchor)
    litbar:SetPoint("TOP", main, "TOP", nil, (anchor / anchor_max) * litbar_play)
  end
  local function moveAnchor(delta)
    moveAnchorTo(anchor + delta)
  end
  
  local function recalculateAnchorMax()
    local contents = item_height * #items
    anchor_max = math.max(0, contents - main:GetHeight())
    if anchor_max == 0 then
      litbar:SetVisible(false)
      litbar_play = 0
    else
      litbar:SetVisible(true)
      litbar:SetHeight(main:GetHeight() * (main:GetHeight() / contents))
      litbar_play = main:GetHeight() - litbar:GetHeight()
    end
  end
  
  local inclick = false
  local function AdjustToMouse()
    -- figure out the pos
    local ypos = (Inspect.Mouse().y - barzone:GetTop() - (barzone:GetHeight() - litbar_play) / 2) / litbar_play
    moveAnchorTo(anchor_max * ypos)
  end
  function barzone.Event:LeftDown()
    inclick = true
    AdjustToMouse()
  end
  function barzone.Event:MouseMove()
    if inclick then
      AdjustToMouse()
    end
  end
  function barzone.Event:LeftUp()
    inclick = true
  end
  function barzone.Event:LeftUpoutside()
    inclick = true
  end
  
  function main.Event:Size()
    recalculateAnchorMax()
    moveAnchorTo(anchor)
  end

  local selected = nil
  local selected_index = nil
  
  function main:Set(newitems)
    
    items = {}
    while #words < #newitems do
      local newword = UI.CreateFrame("Text", name .. "Text", textzone)
      newword:SetPoint("LEFT", textzone, "LEFT", 2, nil)
      newword:SetPoint("RIGHT", textzone, "RIGHT", -2, nil)
      newword:SetText("test")
      newword:SetFontSize(14)
      item_height = newword:GetFullHeight()
      newword:SetHeight(item_height)
      
      newword:SetPoint("TOP", words[#words], "BOTTOM")
      
      table.insert(words, newword)
      
      local wordid = #words
      function newword.Event:LeftClick()
        main:Select(items[wordid].id)
      end
    end
    
    local anchor
    for k = 1, #newitems do
      table.insert(items, newitems[k])
      words[k]:SetVisible(true)
      words[k]:SetText(newitems[k].label)
    end
    
    for k = #newitems + 1, #words do
      words[k]:SetVisible(false)
    end
    
    recalculateAnchorMax()
    
    self:Select(selected)
  end
  function main:Select(id)
    if selected_index then
      words[selected_index]:SetBackgroundColor(0, 0, 0, 0)
    end
    
    local index
    for k, v in ipairs(items) do
      if v.id == id then
        index = k
      end
    end
    
    if not index then
      selected = nil
      return
    end
    
    selected = id
    selected_index = index
    
    words[selected_index]:SetBackgroundColor(0.4, 0.4, 0.6)
  end
  
  function main.Event:WheelBack()
    moveAnchor(50)
  end
  function main.Event:WheelForward()
    moveAnchor(-50)
  end
  
  return main
end
