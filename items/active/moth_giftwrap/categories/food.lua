local oldLoadConditions = loadConditions
loadConditions = function(input, output)
	if ((concernedItem.config.category == "food") or (concernedItem.config.category == "preparedFood") or (concernedItem.config.category == "drink")) then
		table.insert(tags, "moth_food")
		
		quality = concernedItem.config.foodValue
		if not quality then quality = 5 end
		output:setInstanceValue("localisation", "")
		output:setInstanceValue("entryshortdescription", "giftFoodName")
		output:setInstanceValue("inventoryIcon", "/items/active/moth_giftwrap/categories/food.png")
	end

	if oldLoadConditions then output = oldLoadConditions(input, output) end
	return output
end