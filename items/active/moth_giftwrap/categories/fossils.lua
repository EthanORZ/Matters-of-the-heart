local oldLoadConditions = loadConditions
loadConditions = function(input, output)
	if ((concernedItem.config.category == "smallFossil") or (concernedItem.config.category == "mediumFossil") or (concernedItem.config.category == "largeFossil")) then
		table.insert(tags, "moth_fossils")
		if concernedItem.config.category == "smallFossil" then quality = 50 end
		if concernedItem.config.category == "mediumFossil" then quality = 75 end
		if concernedItem.config.category == "largeFossil" then quality = 100 end
		
		output:setInstanceValue("localisation", "")
		output:setInstanceValue("entryshortdescription", "giftFossilsName")
		output:setInstanceValue("inventoryIcon", "/items/active/moth_giftwrap/categories/fossils.png")
	end

	if oldLoadConditions then output = oldLoadConditions(input, output) end
	return output
end