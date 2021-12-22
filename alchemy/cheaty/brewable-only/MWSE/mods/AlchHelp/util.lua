local util = {}
d = require("AlchHelp.data")
-- make list of available effects for an ingredient
function util.mk_ingr_fx_list(fxId, attribId, skillId)
    local namelist = {}
    for index, data in ipairs(fxId) do
      local skill = nil
      if (skillId ~= nil) then skill = skillId[index] end
      local attrib = nil
      if (attribId ~= nil) then attrib = attribId[index] end
      table.insert(namelist, (util.find_fx_name(data, attrib , skill)))
    end
    return namelist
end

-- finds number of ingredients per effect's string based on - being used as a bullet point 
function util.get_ingr_count(str)
    local _, count = string.gsub(str, " %- ", "")
    return count
end
  
-- creates text ui elements for the available effects menu
function util.make_avail_list(p, items)
    for i, v in pairs(items) do
      local ingrNum = u.get_ingr_count(v)
      if (ingrNum > 1) then
        local tmpId = tes3ui.registerID(d.pfx .. "AM_txt" .. ts(i))
        local txt = v
        local tmpTxt = make_clickable{parent = p, id = tmpId, text = txt, same = true, pad = 4, brd = 2}
        tmpTxt.autoWidth = true
        tmpTxt.widthProportional = 1.0
      end
    end
end



-- find proper effect name.
-- effects that modify a skill or attribute have the same effect id but different skill or attribute ids
-- ex: damage luck & damage personality have the same exact effect id which is atually damage attribute
function util.find_fx_name(id, attrib, skill)
    for index, data in ipairs(d.effects) do
        if (data.id == id) then
            if (data.atr ~= nil) then
                if (data.atr == attrib) then
                    return data.name
        end
        elseif (data.skill ~= nil) then
            if (data.skill == skill) then
                return data.name
        end
        else
          return data.name
        end
      end
    end
    return "xx"
end

return util



