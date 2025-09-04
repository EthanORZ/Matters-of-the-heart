local oldLoadConditions = loadConditions
loadConditions = function(input, output)
	if (concernedItem.config.orientations) and (not (concernedItem.config.category == "bug")) then
		table.insert(tags, "moth_furniture")
		local rarity = string.lower(concernedItem.config.rarity)
		if rarity then
			if rarity=="common" then quality = 18 end
			if rarity=="uncommon" then quality = 36 end
			if rarity=="rare" then quality = 54 end
			if rarity=="legendary" then quality = 72 end
			if rarity=="essential" then quality = 90 end
		else
			quality = 15
		end
		
		output:setInstanceValue("localisation", "")
		output:setInstanceValue("entryshortdescription", "giftFurnitureName")
		output:setInstanceValue("inventoryIcon", "/items/active/moth_giftwrap/categories/furniture.png")
	end

	if oldLoadConditions then output = oldLoadConditions(input, output) end
	return output
end