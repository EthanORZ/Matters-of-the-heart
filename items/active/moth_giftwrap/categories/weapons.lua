local oldLoadConditions = loadConditions
loadConditions = function(input, output)
	if concernedItem.config.itemTags then
		for key, value in pairs(concernedItem.config.itemTags) do
			if ((value == "weapon") and (not (concernedItem.config.itemName == "filledcapturepod"))) then
				table.insert(tags, "moth_weapons")
				quality = 4
				local multiplier = 1
				local lvl = 1
				if concernedItem.config.level then lvl = lvl + concernedItem.config.level end
				if concernedItem.config.rarity == "Uncommon" then multiplier = 2 end
				if concernedItem.config.rarity == "Rare" then multiplier = 3 end
				if concernedItem.config.rarity == "Legendary" then multiplier = 4 end
				if concernedItem.config.rarity == "Essential" then multiplier = 5 end
				quality = quality * lvl * multiplier
			
				output:setInstanceValue("localisation", "")
				output:setInstanceValue("entryshortdescription", "giftWeaponsName")
				output:setInstanceValue("inventoryIcon", "/items/active/moth_giftwrap/categories/weapons.png")
			end
		end
	end

	if oldLoadConditions then output = oldLoadConditions(input, output) end
	return output
end