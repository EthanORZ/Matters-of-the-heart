require "/scripts/util.lua"
require "/scripts/augments/item.lua"
require "/scripts/mothutil.lua"

function apply(input)
	if input then
		local output = Item.new({
			name = "moth_gift",
			count = 1,
			parameters = {}
		})
		
		config = getConfig()
		for k,v in pairs(config.giftCategories) do
			require(v.script)
		end
		for k,v in pairs(config.giftCategoriesUnique) do
			if (not (k == "miscellaneous")) then require(v.script) end
		end
		
		tags = { "moth_present" }
		quality = nil
		concernedItem = root.itemConfig(input)
		loadConditions(input, output)
		if #tags < 2 then table.insert(tags, "moth_miscellaneous") end
		return output:descriptor(), 1
	else
		return nil
	end
end

function loadConditions(input, output)
	local rarity = "Common"
	if concernedItem.config.price then
		if concernedItem.config.price >= 5000 then rarity = "Legendary"
		elseif concernedItem.config.price >= 2500 then rarity = "Rare"
		elseif concernedItem.config.price >= 1000 then rarity = "Uncommon"
		end
	end
	if not quality then quality = (20 + math.random(0,40)) end
	output:setInstanceValue("rarity", rarity)
	if quality > 100 then quality = 100 end
	output:setInstanceValue("durabilityHit", quality)
	output:setInstanceValue("durability", 100)
	output:setInstanceValue("item", input)
	output:setInstanceValue("itemTags", tags)
	return output
end