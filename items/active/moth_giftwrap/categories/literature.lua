local oldLoadConditions = loadConditions
loadConditions = function(input, output)
	if concernedItem.config.codexId then 
		table.insert(tags, "moth_literature")
		local location = concernedItem.directory .. concernedItem.config.codexId .. ".codex"
		js = root.assetJson(location)
		local totalLength = 0
		for key, value in pairs(js.contentPages) do
			totalLength = totalLength + string.len(value)
		end
		
		quality = math.floor(totalLength/20)
		if not quality then quality = 5 end
		output:setInstanceValue("localisation", "")
		output:setInstanceValue("entryshortdescription", "giftLiteratureName")
		output:setInstanceValue("inventoryIcon", "/items/active/moth_giftwrap/categories/literature.png")
	end

	if oldLoadConditions then output = oldLoadConditions(input, output) end
	return output
end
