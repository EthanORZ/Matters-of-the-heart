local oldLoadConditions = loadConditions
loadConditions = function(input, output)
	if concernedItem.config.category == "musicalInstrument" then
		table.insert(tags, "moth_instruments")
		quality = 75
		
		output:setInstanceValue("localisation", "")
		output:setInstanceValue("entryshortdescription", "giftInstrumentsName")
		output:setInstanceValue("inventoryIcon", "/items/active/moth_giftwrap/categories/instruments.png")
	end

	if oldLoadConditions then output = oldLoadConditions(input, output) end
	return output
end