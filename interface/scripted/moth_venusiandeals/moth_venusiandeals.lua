require "/scripts/mothutil.lua"

function init()
	mothConfig = getConfig()
	
	sourceId = widget.getData("npcId")
	productList = "scrollArea.itemList"
	widget.setText("munieOwned", player.currency("moth_munie"))
	if player.getProperty("moth_lastrotation", 0) ~= rotationSeed() then
		player.setProperty("moth_purchased", {})
		player.setProperty("moth_lastrotation", rotationSeed())
	end
	loadItems()
	lastSeed = rotationSeed()
	lastAdmin = mothConfig.clientConfigs.debug.value
	if not widget.getData("btnBuy") then
		local preorders = player.getProperty("moth_preorders", {})
		for key, value in pairs(preorders) do
			player.giveItem(value)
		end
		player.setProperty("moth_preorders", {})
	end
end

function update()
	widget.setText("timeLeft", string.format(
		getTranslatedMiscellaneous(mothConfig.language, "rotationLabel"),
		parseCooldown(math.floor(mothConfig.shopConfig.shopRotationTime-(os.time()%mothConfig.shopConfig.shopRotationTime)))
	))
	if player.getProperty("moth_lastrotation", 0) ~= rotationSeed() then
		player.setProperty("moth_purchased", {})
		player.setProperty("moth_lastrotation", rotationSeed())
	end
	if lastSeed ~= rotationSeed() then
		loadItems()
		lastSeed = rotationSeed()
	end
	if lastAdmin ~= mothConfig.clientConfigs.debug.value then
		loadItems()
		lastAdmin = mothConfig.clientConfigs.debug.value
	end
	if not widget.getData("btnBuy") then
		if not world.isNpc(sourceId) then
			pane.dismiss()
		end
	end
end

function uninit()
end

function button_config()
	openSettings()
end

spinCount = {}
function spinCount.up()
	local w = widget.getListSelected(productList)
	if w then
		w = string.format("%s.%s",productList,w)
		local inv = widget.getData(w .. ".inventoryLabel")
		local newCount = tonumber(widget.getText("tbCount")) + 1
		if newCount > inv then newCount = 1 end
		widget.setText("tbCount", newCount)
		updateTotal()
	end
end
function spinCount.down()
	local w = widget.getListSelected(productList)
	if w then
		w = string.format("%s.%s",productList,w)
		local inv = widget.getData(w .. ".inventoryLabel")
		local newCount = tonumber(widget.getText("tbCount")) - 1
		if newCount < 1 then newCount = inv end
		widget.setText("tbCount", newCount)
		updateTotal()
	end
end

function buy()
	local w = widget.getListSelected(productList)
	if w then
		w = string.format("%s.%s",productList,w)
		local c = tonumber(widget.getText("tbCount"))
		if ((c > 0) and (not(c == nil))) then
			if tryPurchase(c, w) then 
				for i = 1, c do
					player.giveItem(widget.itemSlotItem(w .. ".itemIcon"))
				end 
				loadItems()
			else
				widget.playSound("/sfx/interface/clickon_error.ogg", 0, 1.0) 
			end
		end
	end
end

function preOrder()
	local w = widget.getListSelected(productList)
	if w then
		w = string.format("%s.%s",productList,w)
		local c = tonumber(widget.getText("tbCount"))
		if ((c > 0) and (not(c == nil))) then
			if tryPurchase(c, w) then 
				for i = 1, c do
					local preorders = player.getProperty("moth_preorders", {})
					preorders[tLength(preorders)+1] = widget.itemSlotItem(w .. ".itemIcon")
					player.setProperty("moth_preorders", preorders)
					
					local flags = player.getProperty("moth_questflags", {})
					if not keyExists("firstPreorder", flags) then
						flags["firstPreorder"] = true
						player.setProperty("moth_questflags", flags)
						world.sendEntityMessage(
							player.id(),
							"queueRadioMessage",
							{ 
								important = true,
								unique = false,
								type = "generic",
								textSpeed = 30,
								portraitFrames = 2,
								persistTime = 3,
								messageId = sb.makeUuid(),		
								chatterSound = "/sfx/interface/aichatter1_loop.ogg",
								portraitImage = "/ai/portraits/lovenetportrait.png:talk.<frame>",
								senderName = getTranslatedMiscellaneous(mothConfig.language, "kyuAi"),
								text = getTranslatedMiscellaneous(mothConfig.language, "tutorialMessage")
							}
						)
					end
				end 
				loadItems() 
				widget.playSound("/sfx/objects/checkpoint_activate2.ogg", 0, 1.0)
			else
				widget.playSound("/sfx/interface/clickon_error.ogg", 0, 1.0) 
			end
		end
	end
end

function tryPurchase(c, w)
	local price = widget.getData(w .. ".priceLabel")
	if (player.consumeCurrency(widget.getData(w .. ".moneyIcon"), (c * widget.getData(w .. ".priceLabel"))) or mothConfig.clientConfigs.debug.value) then
		local k = widget.getData(w .. ".itemName")
		local p = player.getProperty("moth_purchased", {})
		if keyExists(k, p) then
			p[k] = p[k] + c
		else
			p[k] = c
		end
		player.setProperty("moth_purchased", p)
		return true
	else
		return false
	end
	widget.setText("munieOwned", player.currency("moth_munie"))
end

function parseCountText()
	local w = widget.getListSelected(productList)
	if w then
		w = string.format("%s.%s",productList,w)
		local inv = widget.getData(w .. ".inventoryLabel")
		local newCount = tonumber(widget.getText("tbCount"))
		if newCount > inv then newCount = 0 end
		if newCount < 0 then newCount = inv end
		widget.setText("tbCount", newCount)
		updateTotal()
	else
		widget.setText("tbCount", "")
	end
end

function updateTotal()
	widget.setText("munieOwned", player.currency("moth_munie"))
	local w = widget.getListSelected(productList)
	if w then
		w = string.format("%s.%s",productList,w)
		if widget.getData(w .. ".moneyIcon") == "moth_munie" then
			widget.setImage("imgBuyMoneyIcon", "/interface/munie.png") 
		else
			widget.setImage("imgBuyMoneyIcon", "/interface/money.png")
		end
		widget.setText("lblBuyTotal", tonumber(widget.getText("tbCount")) * widget.getData(w .. ".priceLabel"))
	else
		widget.setText("lblBuyTotal", 0)
	end
end

function scrollArea()
	widget.setButtonEnabled("btnBuy", true)
	widget.setText("tbCount", 1)
	updateTotal()
end

function loadItems()
	widget.clearListItems(productList)
	widget.setButtonEnabled("btnBuy", false)
	widget.setText("tbCount", "")
	for i = 1, #mothConfig.shopConfig.permanentSelection do	
		local v = mothConfig.shopConfig.permanentSelection[i]
		if player.hasCompletedQuest(v.quest) or mothConfig.clientConfigs.debug.value then
			local w = string.format("%s.%s",productList,widget.addListItem(productList))
			addShopItem(w, v)
		end
	end
	if player.hasCompletedQuest("moth_muniecap") or mothConfig.clientConfigs.debug.value then
		local config1 = copy(mothConfig)
		local config2 = copy(mothConfig)
		local config3 = copy(mothConfig)
		getItemsFromSelection(config1.shopConfig.rotatingGifts.selection, mothConfig.shopConfig.rotatingGifts.size)
		getItemsFromSelection(config2.shopConfig.rotatingConsumables.selection, mothConfig.shopConfig.rotatingConsumables.size)
		getItemsFromSelection(config3.shopConfig.rotatingUpgrades.selection, mothConfig.shopConfig.rotatingUpgrades.size)
	end
end

function getItemsFromSelection(items, amount)
	local s = items
	for i = 1, amount do
		if #s > 0 then
			local result = weightedRandom(s, rotationSeed())
			table.remove(s, result.key)
			local w = string.format("%s.%s",productList,widget.addListItem(productList))
			addShopItem(w, result.value)
		end
	end
end

function addShopItem(w, i)
	widget.setItemSlotItem(w .. ".itemIcon", i.item)
	local itemConfig = root.itemConfig(i.item).config
	for k, v in pairs(i.item.parameters) do
		itemConfig[k] = v
	end
	widget.setText(w .. ".itemName", getTranslatedMiscellaneous(mothConfig.language, itemConfig.entryshortdescription))
	widget.setData(w .. ".itemName", i.key)
	widget.setText(w .. ".priceLabel", i.price)
	widget.setData(w .. ".priceLabel", i.price)
	if i.currency == "moth_munie" then 
		widget.setData(w .. ".moneyIcon", "moth_munie")
		widget.setImage(w .. ".moneyIcon", "/interface/munie.png") 
	end
	local history = player.getProperty("moth_purchased", {})

	local inv = i.inventory
	if keyExists(i.key, history) then
		inv = inv - history[i.key]
	end
	widget.setText(w .. ".inventoryLabel", string.format(getTranslatedMiscellaneous(mothConfig.language, "inventoryLabel"), inv))
	widget.setData(w .. ".inventoryLabel", inv)
	if inv > 0 then
		widget.setImage(w .. ".unavailableoverlay", "") 
	elseif inv < 0 then
		widget.setText(w .. ".inventoryLabel", getTranslatedMiscellaneous(mothConfig.language, "inf"))
		widget.setImage(w .. ".unavailableoverlay", "")
	end
end