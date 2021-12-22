local this = {}
hotKey = 54 -- Right Shift
d = require("AlchHelp.data")
g = require("AlchHelp.global")
u = require("AlchHelp.util")

function this.init()
  hlog("this.init()")
  this.active_fx = {}
  this.active_fx_items = {}
  this.player_ingreds = {}
  this.type = {ingr = 1380404809}
  this.attributes = d.attrib
  this.effects = d.effects
  this.id = {}
  
  this.id.mw = {alchMenu = tes3ui.registerID("MenuAlchemy")}

  this.id.current = {back = tes3ui.registerID("AHelp:active.back"),
                     menu = tes3ui.registerID("AHelp:active.menu"),
                     pane = tes3ui.registerID("AHelp:active.pane")}

  this.id.full = {back = tes3ui.registerID("AHelp:full.back"),
                  menu = tes3ui.registerID("AHelp:full.menu"),
                  pane = tes3ui.registerID("AHelp:full.pane")}

  this.id.ingr = {back = tes3ui.registerID("AHelp:ingr.back"),
                  menu =  tes3ui.registerID("AHelp:ingr.menu"),
                  pane = tes3ui.registerID("AHelp:ingr.pane")}
  
  this.id.main = {available = tes3ui.registerID("AHelp:main.available"),
                  exit = tes3ui.registerID("AHelp:main.exit"),
                  filter = tes3ui.registerID("AHelp:main.filter"),
                  ingredients = tes3ui.registerID("AHelp:main.ingredients"),
                  menu = tes3ui.registerID("AHelp:main.menu")}

  -- make ids for each effects selectable text
  for index, vals in ipairs(this.effects) do
      local tmp_str = ts(vals.name) .. "FX." .. ts(vals.id)
      if (vals.atr ~= nil) then 
        tmp_str = tmp_str .. "ATR." .. ts(vals.atr) 
      end
      
      if (vals.skl ~= nil) then 
        tmp_str = tmp_str .. "SKL." .. ts(vals.skl) 
      end
      
      tmp_str = string.gsub(tmp_str, "%s+", "")
      vals.txtId = tes3ui.registerID(d.pfx .. "FM_txt" .. tmp_str)
  end

  -- misc
  dnl = "\n"
  mc = "mouseClick"
  nl = "\n"

  -- color
  c = {}
  c.default = rgbFloat(202,165,96) -- default morrowind menu text color
  c.red = rgbFloat(171, 0, 0)

  f = {}
  f.allSame = 'a'

  -- mode of color change & intensity
  m = {}
  m.L1 = "L1"
  m.L2 = "L2"
  m.L3 = "L3"
  m.L4 = "L4"
  m.D1 = "D1"
  m.D2 = "D2"
  m.D3 = "D3"
  m.D4 = "D4"

  -- strings
  s = {}
  s.allFx = "All Effects"
  s.avFx = "Available Effects"
  s.back = "Back"
  s.can = "Cancel"
  s.curIngr = "Current Ingredients"
  s.ex = "Exit"
  s.header = "Alchemy Helper"

  -- types
  t = {}
  t.btn = 'b'
  t.txt = 't'
end

---------------------
-- Main Menu stuff --
---------------------
-- start main menu
function this.create_window()
  if (tes3ui.findMenu(this.id.main.menu) ~= nil) then return end
  this.init_ingr_list()

  local menu = make_menu(this.id.main.menu)
  local mainLbl = menu:createLabel{text = s.header}
  mainLbl.borderBottom = 5

  local avail_block = new_block(menu)
  make_clickable{parent = avail_block, id = this.id.main.available, 
                 text = s.avFx, pad = 4, fun = this.open_available_fx}
  
  local ingr_block = new_block(menu)
  make_clickable{parent = ingr_block, id = this.id.main.ingredients, 
                 text = s.curIngr, pad = 4, fun = this.ingredients_menu}
  
  local full_block = new_block(menu)
  make_clickable{parent = full_block, id = this.id.main.filter, 
                 text = s.allFx, pad = 4, fun = this.open_full_fx}
  
  local cancel_block = new_block(menu)
  make_clickable{parent = cancel_block, id = this.id.main.exit, 
                 text = s.ex, pad = 4, fun = this.main_cancel, 
                 color = c.red}

  menu:updateLayout()
  tes3ui.enterMenuMode(this.id.main.menu)
end

-- handler for pressing the exit/cancel button in the main menu
function this.main_cancel(e)
    local menu = tes3ui.findMenu(this.id.main.menu)
    if (menu) then
        tes3ui.leaveMenuMode()
        menu:destroyChildren()
        menu:destroy()
    end
end

------------------------
-- Full Fx Menu stuff --
------------------------
-- shows a list of all magical effects
function this.open_full_fx(e)
  if (tes3ui.findMenu(this.id.full.menu) ~= nil) then return end

  local ffx_menu = make_menu(this.id.full.menu)
  local scroll_block = ffx_menu:createBlock{}
  scroll_block.autoWidth = true
  scroll_block.autoHeight = true
  scroll_block.paddingAllSides = 8

  local pane = newPane(scroll_block, this.id.full.pane)
  this.make_full_fx_list(pane, g.CLICK, this.full_select_fx)

  local btn_block = new_block(ffx_menu)
  make_clickable{parent = btn_block, id = this.id.full.back, text = s.back, 
                 pad = 8, fun = this.full_back_press, color = c.red}

  ffx_menu:updateLayout()
  tes3ui.enterMenuMode(this.id.full.menu)
end

-- handler for pressing the back button in the full list of magical effects
function this.full_back_press(e)
  local ffx_menu = tes3ui.findMenu(this.id.full.menu)
  if (ffx_menu) then
      tes3ui.leaveMenuMode()
      ffx_menu:destroyChildren()
      ffx_menu:destroy()
  end
end

-- for debug purposes
function this.full_select_fx(e)
  local ffx_menu = tes3ui.findMenu(this.id.full.menu) --log("data: " .. ts(e.source))
end

-- creates text ui elements for the magical effects menu
function this.make_full_fx_list(p, action, fun)
    for index, val in ipairs(this.effects) do
        local tmpId = val.txtId
        local tmpTxt = val.name
        local tmpBtn = make_clickable{parent = p, id = tmpId, text = tmpTxt, same = true, pad = 2}
        tmpBtn.autoWidth = true
        tmpBtn.widthProportional = 1.0
        tmpBtn:register(action, fun)
    end
end

-----------------------------
-- Available FX Menu stuff --
-----------------------------
-- open available fx menu
function this.open_available_fx(e)
  if (tes3ui.findMenu(this.id.current.menu) ~= nil) then return end

  local avail_menu = make_menu(this.id.current.menu)
  local scroll_block = avail_menu:createBlock{}
  scroll_block.autoWidth = true
  scroll_block.autoHeight = true
  scroll_block.paddingAllSides = 8

  local pane = newPane(scroll_block, this.id.current.pane)
  u.make_avail_list(pane,this.active_fx_items)

  local btn_block = new_block(avail_menu)
  make_clickable{parent = btn_block, id = this.id.current.back, text = s.back, 
                 pad = 8, fun = this.avail_back_press, color = c.red}

  avail_menu:updateLayout()
  pane.widget:contentsChanged()
  tes3ui.enterMenuMode(this.id.current.menu)
end





-- handler for pressing the back button in the available effects menu
function this.avail_back_press(e)
  local avail_menu = tes3ui.findMenu(this.id.current.menu)
  if (avail_menu) then
      tes3ui.leaveMenuMode()
      avail_menu:destroyChildren()
      avail_menu:destroy()
  end
end



----------------------------
-- Ingredients Menu stuff --
----------------------------
-- open ingredient menu
function this.ingredients_menu(e)
  if (tes3ui.findMenu(this.id.ingr.menu) ~= nil) then return end

  for _,v in pairs(this.player_ingreds) do
    local fx = debug_fx_list(v.object.effects,v.object.effectAttributeIds, v.effectsSkillIds)
  end

  local ingrMenu = make_menu(this.id.ingr.menu)
  local scroll_block = ingrMenu:createBlock{}
  scroll_block.autoWidth = true
  scroll_block.autoHeight = true
  scroll_block.paddingAllSides = 8

  local pane = newPane(scroll_block, this.id.ingr.pane)
  mk_ingr_list(pane)

  local btn_block = new_block(ingrMenu)
  local btnBack = make_clickable{parent = btn_block, id = this.id.ingr.back, text = s.back, pad = 8, fun = this.ingrBackBtnPress, color = c.red}

  ingrMenu:updateLayout()
  pane.widget:contentsChanged()
  tes3ui.enterMenuMode(this.id.ingr.menu)
end

-- handler for back button press in ingredient menu
function this.ingrBackBtnPress(e)
  --hlog("this.ingrBackBtnPress(e)")
  local ingrMenu = tes3ui.findMenu(this.id.ingr.menu)
  if (ingrMenu) then
    tes3ui.leaveMenuMode()
    ingrMenu:destroyChildren()
    ingrMenu:destroy()
  end
end

-- make the text ui elements for the ingredient menu
function mk_ingr_list(p)
  for _,v in pairs(this.player_ingreds) do
    local tmpId = tes3ui.registerID(d.pfx .. "txt" .. ts(v.object.id))
    local txt = v.object.name
    local tmpTxt = make_clickable{parent = p, id = tmpId, text = txt, same = true, pad = 2}
    tmpTxt.autoWidth = true
    tmpTxt.widthProportional = 1.0
  end
end

-- used for debug/testing purposes
function debug_fx_list(fxId, attribId, skillId)
  local namelist = ""
  for index,data in ipairs(fxId) do
    local skill = nil
    if (skillId ~= nil) then skill = skillId[index] end
    local attrib = nil
    if (attribId ~= nil) then attrib = attribId[index] end
    namelist = namelist .. " | " .. u.find_fx_name(data, attrib , skill)
  end
  namelist = namelist .. " |"
  return namelist
end

-------------------------
-- General/misc. stuff --
-------------------------
-- wrapper for making new menu with set values
function make_menu(mid)
  local menu = tes3ui.createMenu {id = mid, fixedFrame = true}
  menu.alpha = 1.0
  menu.paddingAllSides = 8
  menu.autoWidth = true
  menu.autoHeight = true
  return menu
end

-- wrapper for making new block with set values
function new_block(m)
    local b = m:createBlock{}
    b.widthProportional = 1.0 -- width is 100% parent width
    b.autoHeight = true
    b.autoWidth = true
    b.childAlignX = 0.0
    b.paddingAllSides = 2
    return b
end

-- wrapper to create new button or selectable text, allows function registers
function make_clickable(data)
  clk = makeClickableHelper(data)
  local dc = data.color
  if (data.fun ~= nil) then clk:register(g.CLICK, data.fun) end
  if (dc ~= nil) then
    clk.color = dc; clk.widget.idle = dc
    clk.widget.idleActive = dc
    clk.widget.idleDisabled = c.dis
    clk.widget.over = shift(dc, m.L2)
    clk.widget.overActive = shift(dc, m.L3)
    clk.widget.overDisabled = c.dis
    clk.widget.pressed = shift(dc, m.L4)
    clk.widget.pressedActive = shift(dc, m.L4)
  end
  if(data.same == true) then
    clk.color = c.default
    clk.widget.idle = c.default
    clk.widget.idleActive = c.default
    clk.widget.idleDisabled = c.default
    clk.widget.over = c.default
    clk.widget.overActive = c.default
    clk.widget.overDisabled = c.default
    clk.widget.pressed = c.default
    clk.widget.pressedActive = c.default
  end

  clk.paddingAllSides = data.pad or 0
  clk.paddingTop = data.pt or 0
  clk.paddingBottom = data.pb or 0
  clk.paddingLeft = data.pl or 0
  clk.paddingRight = data.pr or 0
  clk.borderAllSides = data.brd or 0
  clk.borderTop = data.bt or 0
  clk.borderBottom = data.bb or 0
  clk.borderLeft = data.bl or 0
  clk.borderRight = data.br or 0
  clk.widthProportional = data.wp or 1.0

  return clk
end

-- creates either a new button or selectable text for make_clickable
function makeClickableHelper(data)
  if (data.type == t.btn) then return data.parent:createButton{id = data.id,  text = data.text}
  else return data.parent:createTextSelect{id = data.id,  text = data.text} end
end

-- makes a color lighter or darker
function shift(color, mode)
  local r,g,b = color[1], color[2], color[3]
  local l1, l2, l3, l4 = 0.08, 0.12, 0.2, 0.3 -- adding to RGB = lighter
  local d1, d2, d3, d4 = -l1, -l2, -l3, -l4   -- subtracting from RGB = darker
  local diff = nil

  if (mode == m.L1) then diff = l1 end
  if (mode == m.L2) then diff = l2 end
  if (mode == m.L3) then diff = l3 end
  if (mode == m.L4) then diff = l4 end
  if (mode == m.D1) then diff = d1 end
  if (mode == m.D2) then diff = d2 end
  if (mode == m.D3) then diff = d3 end
  if (mode == m.D4) then diff = d4 end

  if ((r + diff) > 1.0) then r = 1.0 elseif ((r + diff) < 0.0) then r = 0.0 else r = r + diff end
  if ((g + diff) > 1.0) then g = 1.0 elseif ((g + diff) < 0.0) then g = 0.0 else g = g + diff end
  if ((b + diff) > 1.0) then b = 1.0 elseif ((b + diff) < 0.0) then b = 0.0 else b = b + diff end

  return {r,g,b}

end

-- converts regular RGB values to values between 0.0 & 1.0
function rgbFloat(r,g,b) return {(r/255),(g/255),(b/255)} end

-- wrapper for making new vertical scroll panes with set values
function newPane(parent, pid)
  local pane = parent:createVerticalScrollPane{id = pid or nil}
  pane.positionY = 8
  pane.minWidth = 250
  pane.minHeight = 300
  pane.autoWidth = true
  pane.autoHeight = true
  return pane
end

-- regular log for mod
function log(msg) mwse.log("[AF]          " .. msg) end

-- header log
function hlog(msg) mwse.log("[AF] " ..  msg) end

-- tostring wrapper
function ts(val) return tostring(val) end

-------------------------------
-- List Initialization stuff --
-------------------------------
function this.init_ingr_list()
  local inven = tes3.player.object.inventory
  for _, v in pairs(inven) do
      if (v.object.objectType == this.type.ingr) then
        table.insert(this.player_ingreds, v)
      end
  end
  this.initAvailList()
end

-- take available effects & ingredients and make into strings to put into menu
function this.makeAvailStrings()
  local tkeys = {}
  for k in pairs(this.active_fx) do table.insert(tkeys, k) end
  table.sort(tkeys)
  for _, k in ipairs(tkeys) do
    local tmpStr = "[" .. ts(k) .. "]"
    for _, v in ipairs(this.active_fx[k]) do
      tmpStr = tmpStr .. "\n\t    - " .. ts(v)
    end
    table.insert(this.active_fx_items, tmpStr)
  end
end

-- make list/table of each available effect and cooresponding ingredients based on player inventory
function this.initAvailList()
  for index, val in ipairs(this.player_ingreds) do
    local tmpFx = u.mk_ingr_fx_list(val.object.effects, val.object.effectAttributeIds, val.effectsSkillIds)
    iname = val.object.name
    for index2, val2 in ipairs(tmpFx) do
      if (val2 ~= "xx") then
        local fxp = fx_is_present(this.active_fx, (ts(val2)))
        fxid = ts(val2)
        if (not fxp) then this.active_fx[fxid] = {iname} -- make new fx entry
        else table.insert(this.active_fx[fxid], iname) end -- update fx entry by adding ingredient name
      end
    end
  end
  this.makeAvailStrings()
end



-- checks if an effect is already present in table
function fx_is_present(list, name)
  for i, v in pairs(list) do
    if (name == (ts(i))) then return true end
  end
  return false
end

-----------------------------
-- Start, keydown callback --
-----------------------------
function this.on_cmd(e)
    log("menumode: " .. (ts(tes3ui.menuMode())))
    if (tes3ui.menuMode()) then
      local top = tes3ui.getMenuOnTop()
      log("top menu: " .. ts(top.id))
      if (top.id == this.id.mw.alchMenu) then
        this.init()
        this.create_window()
      end
    end
end

event.register("initialized", this.init)
event.register("keyDown", this.on_cmd, {filter = hotKey})
