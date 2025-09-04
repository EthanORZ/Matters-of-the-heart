require "/scripts/mothutil.lua"

function init()
	mothConfig = getConfig()
	
	relationshipList = "scrollArea_relationships.itemList"
	dataList = "scrollArea_data.itemList"
	questFlags = player.getProperty("moth_questflags", {})
	playerRelationships = player.getProperty("moth_relationships", {})
	immigration = status.statusProperty("moth_immigrating", nil)
	breakingUp = status.statusProperty("moth_breakingup", nil)
	readyToDelete = false
	timeData = nil
	refreshLoveData()
	previousAdmin = mothConfig.clientConfigs.debug.value
end

function update()
	if timeData then 
		widget.setText(
			timeData.i .. ".description", 
			lastTime(
				mothConfig.language, 
				playerRelationships[timeData.k].lastDated.data
			)
		) 
	end
	if previousAdmin ~= mothConfig.clientConfigs.debug.value then previousAdmin = mothConfig.clientConfigs.debug.value scrollArea_relationships() end
end

function uninit()
	player.setProperty("moth_questflags", questFlags)
end

function scrollArea_relationships()
	local k = widget.getData(string.format("%s.%s",relationshipList,widget.getListSelected(relationshipList)))
	if k then setLoveData(k) end
end

function textBox_filter()
	refreshLoveData()
end

function check_teleportable()
	refreshLoveData()
end

function button_config()
	openSettings()
end

function button_quickTravel()
	local k = widget.getData(string.format("%s.%s",relationshipList,widget.getListSelected(relationshipList)))
	if k then 
		if player.consumeCurrency("moth_munie", mothConfig.quickTravelFee) or mothConfig.clientConfigs.debug.value then 
			player.warp(playerRelationships[k].location.data, "beam")
			questFlags["quickTravel"] = true
		else
			widget.playSound("/sfx/interface/clickon_error.ogg", 0, 0.5)
		end
	else
		widget.playSound("/sfx/interface/clickon_error.ogg", 0, 0.5)
	end
end

function button_removeContact()
	if not readyToDelete then
		widget.setText("button_removeContact", getTranslatedMiscellaneous(mothConfig.language, "confirmDelete"))
		readyToDelete = true
	else
		widget.setText("button_removeContact", getTranslatedMiscellaneous(mothConfig.language, "deleteContact"))
		readyToDelete = false
		local k = widget.getData(string.format("%s.%s",relationshipList,widget.getListSelected(relationshipList)))
		if k and (not(breakingUp)) then 
			local oldTp = playerRelationships[k].location.data
			local _, pos = string.find(oldTp, "=")
			oldTp = string.sub(oldTp, 1, (pos-1))
			status.setStatusProperty("moth_breakingup", {
				npcKey = k,
				oldLocation = oldTp,
				checkLocation = player.worldId(),
				newLocation = player.worldId() .. "=" .. round(world.entityPosition(player.id())[1]) .. "." .. round(world.entityPosition(player.id())[2])
			})
			status.addEphemeralEffect("moth_deletion", 60)
			
			player.warp(playerRelationships[k].location.data, "beam")
		else
			widget.playSound("/sfx/interface/clickon_error.ogg", 0, 0.5)
		end
	end
end

function button_immigrate()
	local k = widget.getData(string.format("%s.%s",relationshipList,widget.getListSelected(relationshipList)))
	if k and (not(immigration)) then 
		if player.consumeItem({name="moth_proofofcitizenship", count=1}) or mothConfig.clientConfigs.debug.value then
			local oldTp = playerRelationships[k].location.data
			local _, pos = string.find(oldTp, "=")
			oldTp = string.sub(oldTp, 1, (pos-1))
			status.setStatusProperty("moth_immigrating", {
				npcKey = k,
				oldLocation = oldTp,
				checkLocation = player.worldId(),
				newLocation = player.worldId() .. "=" .. round(world.entityPosition(player.id())[1]) .. "." .. round(world.entityPosition(player.id())[2])
			})
			status.addEphemeralEffect("moth_immigrating", 60)
			
			player.warp(playerRelationships[k].location.data, "beam")
		else
			widget.playSound("/sfx/interface/clickon_error.ogg", 0, 0.5)
		end
	else
		widget.playSound("/sfx/interface/clickon_error.ogg", 0, 0.5)
	end
end

function refreshLoveData()
	widget.clearListItems(relationshipList)
	playerRelationships = player.getProperty("moth_relationships", {})
	
	for key, value in pairs(playerRelationships) do
		if (not (string.find(string.lower(value.name.data), string.lower(widget.getText("textBox_filter"))) == nil)) then
			if ((playerRelationships[key].level.data >= mothConfig.flirtingValues.FriendCap) or (not widget.getChecked("check_teleportable"))) then
				newItem = widget.addListItem(relationshipList)
				local portraitNumber = 0
				widget.setData(string.format("%s.%s",relationshipList,newItem), key)
				widget.setText(string.format("%s.%s.name",relationshipList,newItem), value.name.data)
				widget.setText(string.format("%s.%s.relationship",relationshipList,newItem), getTranslatedMiscellaneous(mothConfig.language, getRelationshipStatus(playerRelationships, key), playerRelationships[key].gender.data))
				setHearts(string.format("%s.%s.heartsLayout.heart",relationshipList,newItem), value.level.data, "")
				for k, v in pairs(value.portrait.data) do
					portraitNumber = portraitNumber + 1
					widget.addChild(string.format("%s.%s",relationshipList,newItem), {
						type = "image",
						file = v.image,
						position = {-9, -18},
						zlevel = portraitNumber
					}, "portrait" .. portraitNumber)
				end
			end
		end
	end
end

function setLoveData(key)
	clearLoveData()
	widget.clearListItems(dataList)
	if (playerRelationships[key].level.data >= mothConfig.flirtingValues.FriendCap) or mothConfig.clientConfigs.debug.value then
		if (player.currency("moth_munie") >= mothConfig.quickTravelFee) then
			widget.setButtonEnabled("button_quickTravel", true)
			widget.setText("button_quickTravel", getTranslatedMiscellaneous(mothConfig.language, "quickTravel"))
		else
			widget.setButtonEnabled("button_quickTravel", false)
			widget.setText("button_quickTravel", getTranslatedMiscellaneous(mothConfig.language, "quickTravelRequirement"))
		end
	else
		widget.setButtonEnabled("button_quickTravel", false)
		widget.setText("button_quickTravel", getTranslatedMiscellaneous(mothConfig.language, "quickTravelRelationship"))
	end
	if (playerRelationships[key].level.data >= mothConfig.flirtingValues.LoverCap) or mothConfig.clientConfigs.debug.value then
		if (player.hasCountOfItem({name="moth_proofofcitizenship", count=1}) > 0) then
			widget.setButtonEnabled("button_immigrate", true)
			widget.setText("button_immigrate", getTranslatedMiscellaneous(mothConfig.language, "immigrate"))
		else
			widget.setButtonEnabled("button_immigrate", false)
			widget.setText("button_immigrate", getTranslatedMiscellaneous(mothConfig.language, "immigrateRequirement"))
		end
	else
		widget.setButtonEnabled("button_immigrate", false)
		widget.setText("button_immigrate", getTranslatedMiscellaneous(mothConfig.language, "immigrateRelationship"))
	end
	widget.setButtonEnabled("button_removeContact", true)
	widget.setText("profileLayout.name", playerRelationships[key].name.data)
	widget.setText("profileLayout.relationship", "^#b9b5b2;" ..  getTranslatedMiscellaneous(mothConfig.language, getRelationshipStatus(playerRelationships, key), playerRelationships[key].gender.data))
	widget.removeAllChildren("profileLayout.portraitLayout")
	local portraitNumber = 0
	for k, v in pairs(playerRelationships[key].portrait.data) do
		portraitNumber = portraitNumber + 1
		widget.addChild("profileLayout.portraitLayout", {
			type = "image",
			file = v.image,
			position = {-6, -19},
			zlevel = portraitNumber
		}, "portrait" .. portraitNumber)
	end
	local d = {}
	for k, v in pairs(playerRelationships[key]) do
		if not v.ignore then d[v.dataOrder] = v end
	end
	for i = 1, #d do
		local item = string.format("%s.%s",dataList,widget.addListItem(dataList))
		widget.setText(item .. ".title", getTranslatedMiscellaneous(mothConfig.language, d[i].dataTitle))
		if d[i].unlocked or mothConfig.clientConfigs.debug.value then
			if d[i].dataType == "hearts" then
				setHearts(item .. ".heartsLayout.heart", playerRelationships[key].level.data, "")
			elseif d[i].dataType == "item" then
				if keyExists(d[i].data, mothConfig.giftCategories) then
					widget.setItemSlotItem(item .. ".itemSlot", mothConfig.giftCategories[d[i].data].item)
				else
					widget.setItemSlotItem(item .. ".itemSlot", mothConfig.giftCategoriesUnique[d[i].data].item)
				end
			elseif d[i].dataType == "text" then
				widget.setText(item .. ".description", getTranslatedMiscellaneous(mothConfig.language, d[i].data, playerRelationships[key].gender.data))
			elseif d[i].dataType == "affinity" then
				widget.setText(item .. ".description", string.format(getTranslatedMiscellaneous(mothConfig.language, "affinityDisplay"), calculateGain(d[i].data), calculateLoss(d[i].data)))
			elseif d[i].dataType == "time" then
				widget.setText(item .. ".description", lastTime(mothConfig.language, d[i].data))
				timeData = {i = item, k = key}
			end
		else
			widget.setText(item .. ".description", getTranslatedMiscellaneous(mothConfig.language, "notLearned"))
		end
	end
end

function clearLoveData()
	timeData = nil
	widget.setButtonEnabled("button_quickTravel", false)
	widget.setButtonEnabled("button_removeContact", false)
	widget.setButtonEnabled("button_immigrate", false)
	widget.removeAllChildren("profileLayout.portraitLayout")
	widget.setText("profileLayout.name", "")
	widget.setText("profileLayout.relationship", "^#b9b5b2;" .. getTranslatedMiscellaneous(mothConfig.language, "selectContact"))
	widget.clearListItems(dataList)
end