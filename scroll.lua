
function sw_MakeScrolly(name, parent)
  local barwidth = 10
  
  local main = UI.CreateFrame("Frame", name, parent)
  
  local textzone = UI.CreateFrame("Mask", name .. "Textzone", main)
  local barzone = UI.CreateFrame("Frame", name .. "Barzone", main)
  barzone:SetPoint("TOPRIGHT", main, "TOPRIGHT")
  barzone:SetPoint("BOTTOM", main, "BOTTOM")
  barzone:SetWidth(barwidth)
  
  textzone:SetPoint("TOPLEFT", main, "TOPLEFT")
  textzone:SetPoint("BOTTOMRIGHT", barzone, "BOTTOMLEFT", -barwidth, 0)
  
  barzone:SetBackgroundColor(0, 0, 0, 0.5)
  textzone:SetBackgroundColor(0, 0, 0, 0.5)
  
  main:SetBackgroundColor(0, 0, 0, 0.5)
  
  local text_anchor = UI.CreateFrame("Frame", name .. "Anchor", textzone)
  text_anchor:SetPoint("BOTTOMLEFT", textzone, "TOPLEFT")
  
  local words = {}
  local items = {}
  
  words[0] = text_anchor

  function main:Set(newitems)
    
    items = {}
    while #words < #newitems do
      local newword = UI.CreateFrame("Text", name .. "Text", textzone)
      newword:SetPoint("LEFT", textzone, "LEFT")
      newword:SetPoint("RIGHT", textzone, "RIGHT")
      newword:SetText("test")
      newword:SetFontSize(14)
      newword:SetHeight(newword:GetFullHeight())
      
      newword:SetPoint("TOPLEFT", words[#words], "BOTTOMLEFT")
      
      table.insert(words, newword)
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
  end
    
  return main
end
