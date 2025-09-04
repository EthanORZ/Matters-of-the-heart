local oldLoadConditions = loadConditions
loadConditions = function(input, output)
	if (concernedItem.config.category == "foodJunk") or (concernedItem.config.category == "junk") or (concernedItem.config.objectName == "poop") then
		table.insert(tags, "moth_junk")
		quality = 1
		
		output:setInstanceValue("localisation", "")
		output:setInstanceValue("entryshortdescription", "giftJunkName")
		output:setInstanceValue("inventoryIcon", "/items/active/moth_giftwrap/categories/junk.png")
	end

	if oldLoadConditions then output = oldLoadConditions(input, output) end
	return output
end