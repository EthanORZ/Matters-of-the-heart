local oldLoadConditions = loadConditions
loadConditions = function(input, output)
	if (
		(concernedItem.config.category == "headwear") or 
		(concernedItem.config.category == "chestwear") or 
		(concernedItem.config.category == "legwear") or 
		(concernedItem.config.category == "backwear") or 
		(concernedItem.config.category == "headarmour") or 
		(concernedItem.config.category == "chestarmour") or 
		(concernedItem.config.category == "legarmour") or 
		(concernedItem.config.category == "enviroProtectionPack")) 
	then
		table.insert(tags, "moth_outfits")
		if (concernedItem.config.category == "headwear") or (concernedItem.config.category == "headarmour") then quality = 30 end
		if (concernedItem.config.category == "chestwear") or (concernedItem.config.category == "chestarmour") then quality = 50 end
		if (concernedItem.config.category == "legwear") or (concernedItem.config.category == "legarmour") then quality = 20 end
		if (concernedItem.config.category == "backwear") or (concernedItem.config.category == "enviroProtectionPack") then quality = 40 end
		
		output:setInstanceValue("localisation", "")
		output:setInstanceValue("entryshortdescription", "giftOutfitsName")
		output:setInstanceValue("inventoryIcon", "/items/active/moth_giftwrap/categories/outfits.png")
	end

	if oldLoadConditions then output = oldLoadConditions(input, output) end
	return output
end