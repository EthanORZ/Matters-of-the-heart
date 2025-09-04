local oldLoadConditions = loadConditions
loadConditions = function(input, output)
	if concernedItem.config.itemName == "filledcapturepod" then
		table.insert(tags, "moth_pets")
		quality = 
			input.parameters.pets[1].status.stats.maxHealth + 
			input.parameters.pets[1].status.stats.attack + 
			input.parameters.pets[1].status.stats.protection + 
			input.parameters.pets[1].status.stats.defense
		
		output:setInstanceValue("localisation", "")
		output:setInstanceValue("entryshortdescription", "giftPetsName")
		output:setInstanceValue("inventoryIcon", "/items/active/moth_giftwrap/categories/pets.png")
	end

	if oldLoadConditions then output = oldLoadConditions(input, output) end
	return output
end