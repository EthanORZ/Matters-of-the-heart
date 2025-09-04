local oldLoadConditions = loadConditions
loadConditions = function(input, output)
	if concernedItem.config.category == "bug" then
		table.insert(tags, "moth_bugs")
		quality = 15
		
		output:setInstanceValue("localisation", "")
		output:setInstanceValue("entryshortdescription", "giftBugsName")
		output:setInstanceValue("inventoryIcon", "/items/active/moth_giftwrap/categories/bugs.png")
	end

	if oldLoadConditions then output = oldLoadConditions(input, output) end
	return output
end