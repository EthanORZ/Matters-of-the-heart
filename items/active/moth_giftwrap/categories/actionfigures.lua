local oldLoadConditions = loadConditions
loadConditions = function(input, output)
	if concernedItem.config.category == "actionFigure" then
		table.insert(tags, "moth_actionfigures")
		quality = 100
		
		output:setInstanceValue("localisation", "")
		output:setInstanceValue("entryshortdescription", "giftActionfiguresName")
		output:setInstanceValue("inventoryIcon", "/items/active/moth_giftwrap/categories/actionfigures.png")
	end

	if oldLoadConditions then output = oldLoadConditions(input, output) end
	return output
end