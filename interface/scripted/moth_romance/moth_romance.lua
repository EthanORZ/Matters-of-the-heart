require "/scripts/mothutil.lua"

function init()
	mothConfig = getConfig()
	
	sourceId = widget.getData("npcId")
	if not world.isNpc(sourceId) then
		pane.dismiss()
	end
	npcData = widget.getData("npcData")
	species = world.entitySpecies(sourceId)
	gender = world.entityGender(sourceId)
	
	questFlags = player.getProperty("moth_questflags", {})
	playerRelationships = player.getProperty("moth_relationships", {})
	if not playerRelationships[npcData.fullSeed] then
		playerRelationships[npcData.fullSeed] = {
			level = { data = 0, dataType = "hearts", dataTitle = "relationshipLevel", dataOrder = 1, unlocked = true },
			lastDated = { data = math.floor(player.playTime()), dataType = "time", dataTitle = "lastInteractedWith", dataOrder = 2, unlocked = true },
			giftLoved = { data = npcData.giftPreferences.loved, dataType = "item", dataOrder = 3, dataTitle = "lovedGiftType", unlocked = false },
			giftLiked = { data = npcData.giftPreferences.liked, dataType = "item", dataOrder = 4, dataTitle = "likedGiftType", unlocked = false },
			giftDisliked = { data = npcData.giftPreferences.disliked, dataType = "item", dataOrder = 5, dataTitle = "dislikedGiftType",  unlocked = false },
			giftHated = { data = npcData.giftPreferences.hated, dataType = "item", dataOrder = 6, dataTitle = "hatedGiftType",  unlocked = false },
			genderPreference = { data = npcData.genderPreference, dataType = "text", dataOrder = 7, dataTitle = "sexuality",  unlocked = false },
			romanticAffinity = { data = npcData.romanticAffinity, dataType = "affinity", dataOrder = 8, dataTitle = "romanticAffinity", unlocked = false },
			portrait = { data = npcData.portrait, ignore = true },
			name = { data = world.entityName(sourceId), ignore = true },
			gender = { data = world.entityGender(sourceId), ignore = true },
			relations = { data = npcData.relations, ignore = true },
			location = { data = player.worldId() .. "=" .. round(world.entityPosition(sourceId)[1]) .. "." .. round(world.entityPosition(sourceId)[2]), ignore = true },
			cooldowns = { data = {}, ignore = true },
			upgrades = { data = {}, ignore = true }
		}
	end
	
	if player.getProperty("moth_resetCooldowns", false) then
		for k, v in pairs(playerRelationships) do
			playerRelationships[k].cooldowns.data = {}
		end
		player.setProperty("moth_resetCooldowns", false)
	end
	
	if mothConfig.enableRelationshipDecay then
		local ignoredTime = (math.floor(player.playTime()) - playerRelationships[npcData.fullSeed].lastDated.data) - mothConfig.flirtingValues.decayStart
		if ignoredTime >= mothConfig.flirtingValues.decayInterval then
			local penalty = math.floor(ignoredTime / mothConfig.flirtingValues.decayInterval) * mothConfig.flirtingValues.decayValue
			playerRelationships = stackRelationshipLevel(playerRelationships, npcData.fullSeed, sourceId, penalty)
		end
	end
	
	playerRelationships[npcData.fullSeed].lastDated.data = math.floor(player.playTime())
	playerRelationships[npcData.fullSeed].location.data = player.worldId() .. "=" .. round(world.entityPosition(sourceId)[1]) .. "." .. round(world.entityPosition(sourceId)[2])
	playerRelationships[npcData.fullSeed].relations.data = npcData.relations

	giftList = "buttonBox.giftSelect"
	dateList = "buttonBox.dateSelect.itemList"
	
	bubbleCanvas = widget.bindCanvas("chatbubble")
	-- "idle", "opening", "chatting", "persist", "closing" are the existing states.
	messageState = "idle"
	isTalking = false
	emoteData = nil
	emoteTimer = 0
	emoteState = "idle.1"
	emoteImage = ""
	emoteDirectives = ""
	queuedMessages = {}
	currentMessage = nil
	persistTimer = 0
	transitionTimer = 0
	speechTimer = 0
	lastCount = 0
	question = false
	waitingForAnswer = false
	throttleUpdates = 0
	loading = false
	wasChatting = false
	loadTimer = 0
	loadFrame = 1
	loadDots = 0
	babyConfig = nil
	payload = nil
	
	updatePortrait()
	updateReloads()
	queuedMessages[#queuedMessages+1] = getTranslatedDialogue(mothConfig.language, "greeting" .. getRelationshipStatus(playerRelationships, npcData.fullSeed), species, npcData.personality)
	
	widget.setText("relationshipStatus", getTranslatedMiscellaneous(mothConfig.language, getRelationshipStatus(playerRelationships, npcData.fullSeed), gender))
	widget.setImage("badge", "/interface/scripted/moth_romance/badges/" .. npcData.personality .. ".png")
	widget.setImage("portraitLayout.portraitEmote", emoteImage .. ":" .. emoteState .. emoteDirectives)
	
	local pers = "normal"
	if keyExists(npcData.personality, mothConfig.personalityConfig) then pers = npcData.personality end
	world.sendEntityMessage(player.id(), "playAltMusic", mothConfig.personalityConfig[pers].music, 1.0)
end

function update(dt)
	if not world.isNpc(sourceId) then
		pane.dismiss()
	end
	if payload then
		if not widget.active("busy") then busy() end
		if payload.promise:finished() then
			if widget.active("busy") then unbusy() end
			if payload.promise:succeeded() then
				if payload.promise:result() then
					payload.funct(payload.promise:result())
				else
					payload.funct()
				end
			else
				sb.logError("[MotH] Payload met unexpected failure; terminating.")
			end
			payload = nil
		end
	end
	if loading then
		loadTimer = loadTimer + dt
		if loadTimer >= 0.125 then 
			loadTimer = 0
			loadFrame = loadFrame + 1
			if loadFrame > 8 then 
				loadFrame = 1 
				loadDots = loadDots + 1
				if loadDots > 3 then loadDots = 0 end
			end
		end
		widget.setImage("busy", "/interface/scripted/moth_romance/busy.png:" .. loadFrame)
		local s = "^shadow;" .. getTranslatedMiscellaneous(mothConfig.language, "loading")
		for i=1,loadDots do s = s .. "." end
		widget.setText("busyHint", s)
	else
		if #queuedMessages > 1 then
			widget.setText("buttonBox.queueSize", string.format(getTranslatedMiscellaneous(mothConfig.language, "romanceQueueLeftMulti"), #queuedMessages))
		elseif #queuedMessages > 0 then
			widget.setText("buttonBox.queueSize", string.format(getTranslatedMiscellaneous(mothConfig.language, "romanceQueueLeft"), #queuedMessages))
		else
			widget.setText("buttonBox.queueSize", "")
		end
		manageChatBubble(dt)
		manageEmotes(dt)
	end
	if throttleUpdates >= 0.333 then
		throttleUpdates = 0
		updateReloads()
		if widget.active("buttonBox.giftSelect") then
			local newCount = 0
			local items = player.itemsWithTag("moth_present")
			for key, value in pairs(items) do
				newCount = newCount + 1
			end
			if lastCount~=newCount then refreshOwnedGifts() end
			lastCount = newCount
		end
	else
		throttleUpdates = throttleUpdates + dt
	end
end

function uninit()
	local points = playerRelationships[npcData.fullSeed].level.data
	if points <= mothConfig.flirtingValues.AnnoyanceCap then
		questFlags["firstAnnoyance"] = true
	end
	if points >= mothConfig.flirtingValues.FriendCap then
		questFlags["firstFriend"] = true
	end
	if player.currency("moth_munie") >= 5000 then
		questFlags["munieCap"] = true
	end
	if points >= mothConfig.flirtingValues.heartsCap and everythingUnlocked(playerRelationships, npcData.fullSeed) then
		questFlags["maxOutNPC"] = true			
	end
	if points < mothConfig.flirtingValues.LoverCap and playerRelationships[npcData.fullSeed].relations.data.isSpouse then
		questFlags["angerSpouse"] = true			
	end
	if question then
		playerRelationships = stackRelationshipLevel(playerRelationships, npcData.fullSeed, sourceId, mothConfig.flirtingValues.questionWrongValue)
	end
	player.setProperty("moth_questflags", questFlags)
	player.setProperty("moth_relationships", playerRelationships)
	world.sendEntityMessage(player.id(), "stopAltMusic")
end

function updateReloads()
	manageHearts()
	manageCooldowns()
	manageMarriage()
end

function button_talk()
	hideSub()
	if (randomNumber(1,3) == 1) then
		queuedMessages[#queuedMessages+1] = getTranslatedQuestion(mothConfig.language, species, npcData.personality)
	else
		queuedMessages[#queuedMessages+1] = getTranslatedDialogue(mothConfig.language, "interaction" .. getRelationshipStatus(playerRelationships, npcData.fullSeed), species, npcData.personality)
		
		maybeUnlock()
		playerRelationships = stackRelationshipLevel(playerRelationships, npcData.fullSeed, sourceId, mothConfig.flirtingValues.interactionChatValue)
	end
	useCooldown("btnTalk", mothConfig.flirtingValues.interactionCount, mothConfig.flirtingValues.interactionCooldown)
end

function maybeUnlock()
	local unlock = weightedRandom({
		{mothConfig.flirtingValues.interactionUnlockChance, true},
		{1-mothConfig.flirtingValues.interactionUnlockChance, false}
	})
	if unlock.value then
		local notUnlockedTable = {}
		for k, v in pairs(playerRelationships[npcData.fullSeed]) do
			if not v.ignore then
				if not v.unlocked then
					notUnlockedTable[#notUnlockedTable+1] = k
				end
			end
		end
		if #notUnlockedTable > 0 then
			playerRelationships = unlocksRelationshipValue(playerRelationships, npcData.fullSeed, notUnlockedTable[randomNumber(1,#notUnlockedTable)])
		end
	end
end

function button_gift()
	if not widget.active("buttonBox.giftSelect") then
		hideSub()
		hideMain()
		showSub({"buttonBox.giftSelect"}, "gifting", {252,31})
		refreshOwnedGifts()
	else
		hideSub()
		showMain()
	end
end

function button_date()
	if not widget.active("buttonBox.dateSelect") then
		hideSub()
		hideMain()
		showSub({"buttonBox.dateSelect"}, "dating", {131, 0})
		loadDateSpots()
	else
		hideSub()
		showMain()
	end
end

function button_procreate()
	hideSub()
	if (randomNumber(1, 100) <= calculateBirthChance(playerRelationships[npcData.fullSeed].romanticAffinity.data)) or mothConfig.clientConfigs.debug.value then
		widget.playSound("/sfx/cinematics/license_acquired_event.ogg", 0, 1.0)
		playerRelationships = setRelationshipLevel(
			playerRelationships, 
			npcData.fullSeed, 
			sourceId, 
			((mothConfig.flirtingValues.heartsCap+mothConfig.flirtingValues.overHeartsCap)-(mothConfig.flirtingValues.procreateCost*mothConfig.flirtingValues.overHeartsCap))
		)
		useCooldown("btnProcreate", mothConfig.flirtingValues.procreateCount, mothConfig.flirtingValues.procreateCooldown)
		payload = {
			promise = world.sendEntityMessage(sourceId, "moth_getIdentity", player.id()),
			funct = function(result)
				if result then
					hideSub()
					hideMain()
					showSub({"buttonBox.babyInput","buttonBox.babyInputBg","buttonBox.babyLabel","buttonBox.babyLabelGender","buttonBox.babyLabelGenderShadow","buttonBox.babyButton"}, "procreating", {160,19})
					babyConfig = {}
					local identity_npc = result
					local identity_player = getPlayerIdentity()
					babyConfig.identity = {}
					if randomNumber(1,2) == 1 then babyConfig.species = player.species() else babyConfig.species = species end
					if randomNumber(1,2) == 1 then 
						babyConfig.identity.gender = "male" 
						widget.setText("buttonBox.babyLabelGender", "^blue;" .. getTranslatedMiscellaneous(mothConfig.language, "babyGender", "male") .. "^reset;")
						widget.setText("buttonBox.babyLabelGenderShadow", "^black;" .. getTranslatedMiscellaneous(mothConfig.language, "babyGender", "male") .. "^reset;")
						world.spawnProjectile("fireworkblue2", world.entityPosition(player.id()), player.id(), {0,1}, false, {timeToLive=0.6})
					else 
						babyConfig.identity.gender = "female"
						widget.setText("buttonBox.babyLabelGender", "^pink;" .. getTranslatedMiscellaneous(mothConfig.language, "babyGender", "female") .. "^reset;")
						widget.setText("buttonBox.babyLabelGenderShadow", "^black;" .. getTranslatedMiscellaneous(mothConfig.language, "babyGender", "female") .. "^reset;")
						world.spawnProjectile("moth_fireworkpink2", world.entityPosition(player.id()), player.id(), {0,1}, false, {timeToLive=0.6})
					end
					babyConfig.seed = randomNumber(0, 2147483647)
					if species == player.species() then
						for k, v in pairs(identity_player) do
							if (k == "bodyDirectives") or (k == "emoteDirectives") or (k == "facialHairDirectives") or (k == "facialMaskDirectives") or (k == "hairDirectives")
							then
								local n = randomNumber(1,2)
								if n==1 then
									if identity_npc[k] ~= "" then
										babyConfig.identity[k] = identity_npc[k]
									else
										babyConfig.identity[k] = identity_player[k]
									end
								else
									if identity_player[k] ~= "" then
										babyConfig.identity[k] = identity_player[k]
									else
										babyConfig.identity[k] = identity_npc[k]
									end
								end
							end
						end
					else
						if babyConfig.species==species then
							for k, v in pairs(identity_npc) do
								if (k == "bodyDirectives") or (k == "emoteDirectives") or (k == "facialHairDirectives") or (k == "facialMaskDirectives") or (k == "hairDirectives")
								then
									babyConfig.identity[k] = identity_npc[k]
								end
							end
						else
							for k, v in pairs(identity_player) do
								if (k == "bodyDirectives") or (k == "emoteDirectives") or (k == "facialHairDirectives") or (k == "facialMaskDirectives") or (k == "hairDirectives") 
								then
									babyConfig.identity[k] = identity_player[k]
								end
							end
						end
					end
					button_randomName()
					newEmote("persist", "happy", 2, 0.2, 2.0)
				else
					hideSub()
					showMain()
				end
			end
		}
	else
		widget.playSound("/sfx/cinematics/pixels_lost.ogg", 0, 1.0)
		newEmote("looping", "sad", 5, 0.2, 3.0)
		playerRelationships = setRelationshipLevel(
			playerRelationships, 
			npcData.fullSeed, 
			sourceId, 
			((mothConfig.flirtingValues.heartsCap+mothConfig.flirtingValues.overHeartsCap)-(mothConfig.flirtingValues.procreateFailCost*mothConfig.flirtingValues.overHeartsCap))
		)
		useCooldown("btnProcreate", mothConfig.flirtingValues.procreateCount, mothConfig.flirtingValues.procreateFailCooldown)
	end
end

function button_randomName()
	if babyConfig then
		local nameGenerator = root.assetJson("/species/" .. babyConfig.species .. ".species").nameGen
		local newName = ""
		if babyConfig.identity.gender == "male" then
			newName = root.generateName(nameGenerator[1])
		else
			newName = root.generateName(nameGenerator[2])
		end
		widget.setText("buttonBox.babyInput", newName)
	end
end

function button_answer(widgetName, widgetData)
	local rightOrWrong = "questionWrong"
	if (valueExists(npcData.personality, question.answers["" .. widgetData].pleases)) then 
		rightOrWrong = "questionRight"
		maybeUnlock()
		maybeUnlock()
		newEmote("persist", "happy", 2, 0.2, 2.0)
		playerRelationships = stackRelationshipLevel(playerRelationships, npcData.fullSeed, sourceId, mothConfig.flirtingValues.questionRightValue)
	else
		newEmote("persist", "annoyed", 2, 0.2, 2.0)
		playerRelationships = stackRelationshipLevel(playerRelationships, npcData.fullSeed, sourceId, mothConfig.flirtingValues.questionWrongValue)
	end
	queuedMessages = growArray(queuedMessages, getTranslatedDialogue(mothConfig.language, rightOrWrong, species, npcData.personality))
	for i = 1, 3 do
		widget.setVisible("buttonBox.answerButton" .. i, false)
		widget.setVisible("buttonBox.answerText" .. i, false)
		showMain()
	end
	question = false
	waitingForAnswer = false
end

function button_config()
	openSettings()
end

function skipText(position, button, isButtonDown)
	if isButtonDown then
		if messageState ~= "idle" then
			messageState = "idle"
			if question then 
				waitingForAnswer = true
				for i = 1, 3 do
					widget.setText("buttonBox.answerText" .. i, question.answers["" .. i].answer)
					widget.setVisible("buttonBox.answerButton" .. i, true)
					widget.setVisible("buttonBox.answerText" .. i, true)
				end
				randomiseAnswerPosition()
			end
			widget.setText("chatbubbleText", "")
			widget.setVisible("chatbubble", false)
			isTalking = false
			
			widget.playSound("/sfx/interface/clickon_success.ogg", 0, 1.0)
			bubbleCanvas:clear()
		end
	end
end

function button_back()
	hideSub()
	showMain()
end

function button_confirm(widgetName, widgetData)
	if widgetData=="gifting" then
		if widget.getListSelected(giftList .. ".itemList") then
			local w = string.format("%s.%s",giftList .. ".itemList",widget.getListSelected(giftList .. ".itemList"))
			local item = player.consumeItem(widget.itemSlotItem(w .. ".present"), false, true)
			if item then
				if not item.parameters then item.parameters = {} end
				if not item.parameters.itemTags then
					item.parameters.itemTags = root.itemConfig(item).config.itemTags
				end
				local sourceItem = item
				if sourceItem.parameters.item then sourceItem = sourceItem.parameters.item end
				if not sourceItem.parameters.category then
					sourceItem.parameters.category = root.itemConfig(sourceItem).config.category
				end
				if not valueExists("moth_specialinteraction", item.parameters.itemTags) then
					local giftEnjoyement = "onGiftNeutral"
					local localEmote = {
						style = "persist",
						name = "neutral",
						size = 2,
						speed = 0.2,
						time = 2.0
					}
					local gain = mothConfig.flirtingValues.giftNeutralValue * (item.parameters.durabilityHit/100)
					if valueExists("moth_outfits", item.parameters.itemTags) then
						if sourceItem.parameters.category=="headarmour" then world.sendEntityMessage(sourceId, "moth_wear", "head", sourceItem) end
						if sourceItem.parameters.category=="headwear" then world.sendEntityMessage(sourceId, "moth_wear", "headCosmetic", sourceItem) end
						if sourceItem.parameters.category=="chestarmour" then world.sendEntityMessage(sourceId, "moth_wear", "chest", sourceItem) end
						if sourceItem.parameters.category=="chestwear" then world.sendEntityMessage(sourceId, "moth_wear", "chestCosmetic", sourceItem) end
						if sourceItem.parameters.category=="legarmour" then world.sendEntityMessage(sourceId, "moth_wear", "legs", sourceItem) end
						if sourceItem.parameters.category=="legwear" then world.sendEntityMessage(sourceId, "moth_wear", "legsCosmetic", sourceItem) end
						if sourceItem.parameters.category=="enviroProtectionPack" then world.sendEntityMessage(sourceId, "moth_wear", "back", sourceItem) end
						if sourceItem.parameters.category=="backwear" then world.sendEntityMessage(sourceId, "moth_wear", "backCosmetic", sourceItem) end
					end
					if valueExists("moth_" .. npcData.giftPreferences.hated, item.parameters.itemTags) then 
						giftEnjoyement = "onGiftHated"
						playerRelationships = unlocksRelationshipValue(playerRelationships, npcData.fullSeed, "giftHated")
						localEmote = {
							style = "looping",
							name = "sad",
							size = 5,
							speed = 0.2,
							time = 3.0
						}
						gain = mothConfig.flirtingValues.giftHatedValue * (1 - (item.parameters.durabilityHit/100))
					end
					if valueExists("moth_" .. npcData.giftPreferences.disliked, item.parameters.itemTags) then 
						giftEnjoyement = "onGiftDislike"
						playerRelationships = unlocksRelationshipValue(playerRelationships, npcData.fullSeed, "giftDisliked")
						localEmote = {
							style = "persist",
							name = "annoyed",
							size = 2,
							speed = 0.2,
							time = 2.0
						}
						gain = mothConfig.flirtingValues.giftDislikedValue * (1 - (item.parameters.durabilityHit/100))
					end
					if valueExists("moth_" .. npcData.giftPreferences.liked, item.parameters.itemTags) then 
						giftEnjoyement = "onGiftLiked"
						playerRelationships = unlocksRelationshipValue(playerRelationships, npcData.fullSeed, "giftLiked")
						localEmote = {
							style = "persist",
							name = "happy",
							size = 2,
							speed = 0.2,
							time = 2.0
						}
						gain = mothConfig.flirtingValues.giftLikedValue * (item.parameters.durabilityHit/100)
					end
					if valueExists("moth_" .. npcData.giftPreferences.loved, item.parameters.itemTags) then 
						giftEnjoyement = "onGiftLoved"
						playerRelationships = unlocksRelationshipValue(playerRelationships, npcData.fullSeed, "giftLoved")
						localEmote = {
							style = "persist",
							name = "oooh",
							size = 3,
							speed = 0.2,
							time = 2.0
						}
						gain = mothConfig.flirtingValues.giftLovedValue * (item.parameters.durabilityHit/100)
					end
					newEmote(localEmote.style, localEmote.name, localEmote.size, localEmote.speed, localEmote.time)
					playerRelationships = stackRelationshipLevel(playerRelationships, npcData.fullSeed, sourceId, gain)
					queuedMessages = growArray(queuedMessages, getTranslatedDialogue(mothConfig.language, giftEnjoyement, species, npcData.personality))
					refreshOwnedGifts()
					useCooldown("btnGift", mothConfig.flirtingValues.giftCount, mothConfig.flirtingValues.giftCooldown)
				else
					require(root.itemConfig(sourceItem).config.giftScript)
					loadUniqueInteractions(sourceItem)
					refreshOwnedGifts()
				end
			end
		end
	elseif widgetData=="procreating" then
		local name = widget.getText("buttonBox.babyInput")
		if name ~= "" then
			babyConfig.identity.name = name
			local family = getRelationshipValue(playerRelationships, npcData.fullSeed, "relations")
			table.insert(family.children, name)
			playerRelationships = updateRelationshipValue(playerRelationships, npcData.fullSeed, "relations", family)
			world.sendEntityMessage(sourceId, "moth_modifyFamily", "children", name)
			babyConfig.scriptConfig = {}
			babyConfig.scriptConfig.initialStorage = {advancedFamily={parents={world.entityName(player.id()), world.entityName(sourceId)},children={},siblings={}}}
			local window = world.clientWindow() --[983,994,1103,1059]
			--sb.logInfo("Window position : " .. sb.printJson(window))
			local pos = world.entityPosition(player.id())
			--sb.logInfo("Initial position : " .. sb.printJson(pos))
			local direction = 1
			local offset = (((window[4] - window[2]) * 1.1) - (window[4] - window[2])) * -1
			pos[2] = window[4] + offset
			if babyConfig.identity.gender == "female" then
				direction = -1
				pos[1] = window[3] + (direction*(offset*2))
			else
				pos[1] = window[1] + (direction*(offset*2))
			end
			--sb.logInfo("Final position : " .. sb.printJson(pos))
			world.spawnProjectile("moth_stork", pos, player.id(), {direction,0}, true, {npcParameters=babyConfig})
			hideSub()
			showMain()
		end
	end
end

function loadUniqueInteractions(item)
end

function busy()
	showLoad()
	hideAll()
	widget.setImage("portraitLayout.portraitEmote", emoteImage .. ":idle.1" .. emoteDirectives)
	wasChatting = widget.active("chatbubble")
	widget.setVisible("chatbubble", false)
end

function unbusy()
	hideLoad()
	showMain()
	widget.setVisible("chatbubble", wasChatting)
end

function hideAll()
	hideMain()
	hideSub()
end

function showLoad()
	widget.setVisible("busy", true)
	widget.setVisible("busyHint", true)
	loading = true
	loadTimer = 0
	loadFrame = 1
	loadDots = 0
end

function hideLoad()
	widget.setVisible("busy", false)
	widget.setVisible("busyHint", false)
	loading = false
end

function showMain()
	for _, v in pairs({
		"buttonBox.btnTalk",
		"buttonBox.btnGift",
		"buttonBox.btnProcreate",
		"buttonBox.btnDate",
		"buttonBox.btnKiss"
	}) do
		widget.setVisible(v, true)
	end
end

function hideMain()
	for _, v in pairs({
		"buttonBox.btnTalk",
		"buttonBox.btnGift",
		"buttonBox.btnProcreate",
		"buttonBox.btnDate",
		"buttonBox.btnKiss"
	}) do
		widget.setVisible(v, false)
	end
end

function showSub(wList, data, pos)
	for _, v in pairs(wList) do
		widget.setVisible(v, true)
	end
	widget.setVisible("buttonBox.btnConfirm", true)
	widget.setData("buttonBox.btnConfirm", data)
	widget.setPosition("buttonBox.btnConfirm", pos)
	widget.setVisible("buttonBox.btnBack", true)
	widget.setPosition("buttonBox.btnBack", {pos[1],(pos[2]+15)})
end

function hideSub()
	for _, v in pairs({
		"buttonBox.giftSelect",
		"buttonBox.dateSelect",
		"buttonBox.babyInput",
		"buttonBox.babyInputBg",
		"buttonBox.babyLabel",
		"buttonBox.babyLabelGender",
		"buttonBox.babyLabelGenderShadow",
		"buttonBox.babyButton",
		"buttonBox.btnConfirm",
		"buttonBox.btnBack"
	}) do
		widget.setVisible(v, false)
	end
end

function manageHearts()
	widget.setText("relationshipStatus", getTranslatedMiscellaneous(mothConfig.language, getRelationshipStatus(playerRelationships, npcData.fullSeed), gender))
	setHearts("heartsLayout.heart", getRelationshipValue(playerRelationships, npcData.fullSeed, "level"), "_big")
end

function manageMarriage()
	if getRelationshipStatus(playerRelationships, npcData.fullSeed) == "Spouse" then
		widget.setVisible("married", true)
		if cooldownReady(playerRelationships, npcData.fullSeed, "btnProcreate") or mothConfig.clientConfigs.debug.value then
			if (getRelationshipValue(playerRelationships, npcData.fullSeed, "level") >= (mothConfig.flirtingValues.overHeartsCap+mothConfig.flirtingValues.heartsCap)) or mothConfig.clientConfigs.debug.value then
				widget.setButtonEnabled("buttonBox.btnProcreate", true)
				widget.setText("buttonBox.btnProcreate", getTranslatedMiscellaneous(mothConfig.language, "btnProcreate"))
			else
				widget.setButtonEnabled("buttonBox.btnProcreate", false)
				widget.setText("buttonBox.btnProcreate", getTranslatedMiscellaneous(mothConfig.language, "btnProcreateRequirement"))
			end
		end
	else
		widget.setVisible("married", false)
		widget.setButtonEnabled("buttonBox.btnProcreate", false)
		widget.setText("buttonBox.btnProcreate", getTranslatedMiscellaneous(mothConfig.language, "btnProcreateLocked"))
	end
end

function updatePortrait()
	widget.removeAllChildren("portraitLayout")
	local bgDirectives = mothConfig.personalityConfig
	if bgDirectives[npcData.personality] then
		bgDirectives = bgDirectives[npcData.personality].color
	else
		bgDirectives = bgDirectives["normal"].color
	end
	widget.addChild("portraitLayout", {
		type = "image",
		file = "/interface/scripted/moth_romance/colorscreen.png?replace;ff0000=" .. bgDirectives .. "33",
		position = {0,0},
		scale = 400,
		zlevel = 0
	}, "personalityColor")
	local portraitPosition = config.getParameter("portraitPosition", {0, 0})
	local portraitScale = config.getParameter("portraitScale", 1)
	local portraitNumber = -99
	for key, value in pairs(world.entityPortrait(sourceId, "full")) do
		if (string.find(value.image, "emote.png") == nil) then 
			portraitNumber = portraitNumber + 1
			widget.addChild("portraitLayout", {
				type = "image",
				file = value.image,
				position = portraitPosition,
				scale = portraitScale,
				zlevel = portraitNumber
			}, "portrait" .. portraitNumber)
		else
			widget.addChild("portraitLayout", {
				type = "image",
				file = value.image,
				position = portraitPosition,
				scale = portraitScale,
				zlevel = -1
			}, "portraitEmote")
			emoteImage = value.image
			--"/humanoid/floran/emote.png:idle.1?replace;6f2919=5e6142;ffca8a=c4d0a5;e0975c=a3af83;a85636=7f8760?replace;735e3a=29160f;f7e7b2=7f5a39;a38d59=3b1f15;d9c189=5b3523"
			local first = 0
			local last = 0
			first, _ = string.find(emoteImage, "?replace")
			_, last = string.find(emoteImage, "emote.png")
			if first then emoteDirectives = string.sub(emoteImage, first, -1) end
			if last then emoteImage = string.sub(emoteImage, 1, last) end
		end
	end
	widget.addChild("portraitLayout", {
		type = "image",
		file = "/interface/scripted/moth_romance/background.png",
		position = {0,0},
		scale = 1,
		zlevel = 0
	}, "background")
end

function manageCooldowns()
	local cds = getRelationshipValue(playerRelationships, npcData.fullSeed, "cooldowns")
	for _, cdKey in pairs({
		"btnTalk",
		"btnGift",
		"btnProcreate"
	}) do
		manageCooldown(cds, cdKey)
	end
end

function useCooldown(cdKey, cdCount, cdSize)
	local cds = getCooldown(playerRelationships, npcData.fullSeed, cdKey)
	if os.time()-cds.time >= cdSize then 
		cds.time = os.time() 
		cds.count = cdCount
		cds.maxTime = cdSize
	end
	playerRelationships = setCooldown(playerRelationships, npcData.fullSeed, cdKey, cds.time, cds.count - 1)
	if getCooldown(playerRelationships, npcData.fullSeed, cdKey).count <= 0 then button_back() end
	updateReloads()
end

function manageCooldown(cdTable, cdKey)
	if not cdTable[cdKey] then cdTable[cdKey] = { time = 0, count = 0, maxTime = 0 } end
	local cd = calculateCooldown(cdTable[cdKey], os.time())
	if ((cdTable[cdKey].count <= 0) and (cd)) and (not mothConfig.clientConfigs.debug.value) then
		widget.setButtonEnabled("buttonBox." .. cdKey, false)
		widget.setText("buttonBox." .. cdKey, cd)
	else
		widget.setButtonEnabled("buttonBox." .. cdKey, true)
		widget.setText("buttonBox." .. cdKey, getTranslatedMiscellaneous(mothConfig.language, cdKey))
	end
end

function manageChatBubble(dt)
	if (#queuedMessages > 0) and (messageState == "idle") and (not waitingForAnswer) then
		messageState = "opening"
		bubbleCanvas:clear()
		widget.setVisible("chatbubble", true)
		transitionTimer = 0
		if type(queuedMessages[1]) == "table" then
			question = queuedMessages[1].question
			currentMessage = queuedMessages[1].line
			hideAll()
		else
			currentMessage = queuedMessages[1]
		end
		queuedMessages = shiftArray(queuedMessages)
	end
	if messageState == "opening" then
		transitionTimer = transitionTimer + dt
		drawChatBubble((transitionTimer / mothConfig.clientConfigs.chatTransitionTime.value))
		if (transitionTimer > mothConfig.clientConfigs.chatTransitionTime.value) then
			messageState = "chatting"
			speechTimer = 0
			isTalking = true
			drawChatBubble(1)
		end
	end
	if messageState == "chatting" then
		if speechTimer == 0 then currentMessage = replacePlaceholders(currentMessage) end
		speechTimer = speechTimer + dt
		local proportion = (speechTimer / (string.len(currentMessage) / mothConfig.clientConfigs.chatScrollSpeed.value))
		widget.setText("chatbubbleText", string.sub(currentMessage,1,math.floor(proportion * string.len(currentMessage))))
		widget.playSound(chatSFX(), 0, 1.0)
		if (speechTimer > (string.len(currentMessage) / mothConfig.clientConfigs.chatScrollSpeed.value)) then
			messageState = "persist"
			isTalking = false
			widget.setText("chatbubbleText", currentMessage)
			persistTimer = 0
		end
	end
	if messageState == "persist" then
		persistTimer = persistTimer + dt
		if (persistTimer > mothConfig.clientConfigs.chatPersistTime.value) then
			messageState = "closing"
			transitionTimer = 0
		end
	end
	if messageState == "closing" then
		widget.setText("chatbubbleText", "")
		transitionTimer = transitionTimer + dt
		drawChatBubble((1-(transitionTimer / mothConfig.clientConfigs.chatTransitionTime.value)))
		if (transitionTimer > mothConfig.clientConfigs.chatTransitionTime.value) then
			widget.setVisible("chatbubble", false)
			messageState = "idle"
			if question then 
				waitingForAnswer = true
				for i = 1, 3 do
					widget.setText("buttonBox.answerText" .. i, question.answers["" .. i].answer)
					widget.setVisible("buttonBox.answerButton" .. i, true)
					widget.setVisible("buttonBox.answerText" .. i, true)
				end
				randomiseAnswerPosition()
			end
			bubbleCanvas:clear()
		end
	end
end

function randomiseAnswerPosition()
	local t = {
		{button={193, 107},text={265, 134}},
		{button={193, 54},text={265, 81}},
		{button={193, 1},text={265, 28}}
	}
	t = shuffleTable(t)
	for i = 1, 3 do
		widget.setPosition("buttonBox.answerButton" .. i, t[i].button)
		widget.setPosition("buttonBox.answerText" .. i, t[i].text)
	end
end

function newEmote(style, name, size, speed, maxTime)
	-- emoteData.style == "single", "looping", "persist"
	-- emoteData.speed
	-- emoteData.size
	-- emoteData.name
	-- emoteData.time
    -- [ null, "blabber.1", "blabber.2", null, "shout.1", "shout.2", null, null ],
    -- [ null, "happy.1", "happy.2", null, null, null, null, "idle.1" ],
    -- [ null, "sad.1", "sad.2", "sad.3", "sad.4", "sad.5", null, null ],
    -- [ null, "neutral.1", "neutral.2", null, "laugh.1", "laugh.2", null, null ],
    -- [ null, "annoyed.1", "annoyed.2", null, null, null, null, null ],
    -- [ null, "oh.1", "oh.2", null, "oooh.1", "oooh.2", "oooh.3", null ],
    -- [ null, null, null, null, null, null, null, null ],
    -- [ null, "blink.1", "blink.2", null, "wink.1", "wink.2", "wink.3", "wink.4" ]
	-- function newEmote(style, name, maxTime, speed, size)
		-- if not emoteData then emoteData = {
			-- style = style,
			-- speed = speed,
			-- size = size,
			-- name = name,
			-- time = maxTime
		-- } end
	-- end
	-- newEmote("persist", "annoyed", 2, 0.2, 2.0)
	if not emoteData then emoteData = {
		style = style,
		speed = speed,
		size = size,
		name = name,
		time = maxTime
	} end
end

function manageEmotes(dt)
	if emoteData then
		if emoteData.style == "persist" then
			for i = (emoteData.size-1), 0, -1 do
				if emoteTimer >= (i*emoteData.speed) then
					local frame = i + 1
					emoteState = emoteData.name .. "." .. frame
					if (emoteTimer-(emoteData.speed*emoteData.size)) >= emoteData.time then
						emoteData = nil
					end
					break
				end
			end
		elseif emoteData.style == "looping" then
			for i = (emoteData.size-1), 0, -1 do
				if (emoteTimer%(emoteData.speed*emoteData.size)) >= (i*emoteData.speed) then
					local frame = i + 1
					emoteState = emoteData.name .. "." .. frame
					break
				end
			end
			if emoteTimer >= emoteData.time then
				emoteData = nil
			end
		else 
			for i = (emoteData.size-1), 0, -1 do
				if emoteTimer >= (i*emoteData.speed) then
					local frame = i + 1
					emoteState = emoteData.name .. "." .. frame
					if emoteTimer >= (emoteData.speed*emoteData.size) then
						emoteData = nil
					end
					break
				end
			end
		end
		widget.setImage("portraitLayout.portraitEmote", emoteImage .. ":" .. emoteState .. emoteDirectives)
		emoteTimer = emoteTimer + dt
		if not emoteData then emoteTimer = 0 end
	elseif isTalking then
		-- "idle.1", "blabber.1", "blabber.2" are the existing states.
		if (speechTimer % (10 / mothConfig.clientConfigs.chatScrollSpeed.value) <= (5 / mothConfig.clientConfigs.chatScrollSpeed.value)) then 
			emoteState = "blabber.1" 
		else 
			emoteState = "blabber.2" 
		end
		widget.setImage("portraitLayout.portraitEmote", emoteImage .. ":" .. emoteState .. emoteDirectives)
	else
		emoteState = "idle.1"
		widget.setImage("portraitLayout.portraitEmote", emoteImage .. ":" .. emoteState .. emoteDirectives)
	end
end

function drawChatBubble(proportion)
	bubbleCanvas:clear()
	local dimensions = bubbleCanvas:size()
	bubbleCanvas:drawImage("/interface/scripted/moth_romance/chatbubblebottomleft.png", {0,0})
	bubbleCanvas:drawImage("/interface/scripted/moth_romance/chatbubbletopleft.png", {0,(dimensions[2]-7)})
	bubbleCanvas:drawImage("/interface/scripted/moth_romance/chatbubblebottomright.png", {((dimensions[1]*proportion)-3),0})
	bubbleCanvas:drawImage("/interface/scripted/moth_romance/chatbubbletopright.png", {((dimensions[1]*proportion)-3),(dimensions[2]-7)})
	bubbleCanvas:drawRect({3,0,((dimensions[1]*proportion)-3),(dimensions[2]-4)}, {0,0,0,255})
	bubbleCanvas:drawRect({0,3,((dimensions[1]*proportion)),(dimensions[2]-7)}, {0,0,0,255})
	bubbleCanvas:drawRect({3,1,((dimensions[1]*proportion)-3),(dimensions[2]-5)}, {116,123,130,255})
	bubbleCanvas:drawRect({1,3,((dimensions[1]*proportion)-1),(dimensions[2]-7)}, {116,123,130,255})
	bubbleCanvas:drawRect({3,2,((dimensions[1]*proportion)-3),(dimensions[2]-6)}, {61,61,61,255})
	bubbleCanvas:drawRect({2,3,((dimensions[1]*proportion)-2),(dimensions[2]-7)}, {61,61,61,255})
	bubbleCanvas:drawImage("/interface/scripted/moth_romance/chatbubblearrow.png", {2+(((dimensions[1]/5)-2)*proportion),(dimensions[2]-6)})
end

function replacePlaceholders(s)
	s = string.gsub(s, "<player>", world.entityName(player.id()))
	s = string.gsub(s, "<npc>", world.entityName(sourceId))
	s = string.gsub(s, "<sexuality>", "pansexual")
	s = string.gsub(s, "<gender>", gender)
	return s
end

function chatSFX()
	local valid = false
	if keyExists(species, mothConfig.racialConfig) then
		if #mothConfig.racialConfig[species][gender].chatSFX > 0 then
			valid = true
		end
	end
	if valid then 
		local linesCount = #mothConfig.racialConfig[species][gender].chatSFX
		return mothConfig.racialConfig[species][gender].chatSFX[randomNumber(1,linesCount)]
	else
		local linesCount = #mothConfig.racialConfig.default[gender].chatSFX
		return mothConfig.racialConfig.default[gender].chatSFX[randomNumber(1,linesCount)]
	end
end

function refreshOwnedGifts()
	widget.removeChild(giftList, "itemList")
	local i = 0
	for key, value in pairs(player.itemsWithTag("moth_present")) do 
		if mothConfig.clientConfigs.debug.value or (not((value.name == "moth_perfectlydespicableitem") or (value.name == "moth_perfectlyromanticitem"))) then
			i = i + 1
		end
	end
	local listConfig = config.getParameter("giftSelectList")
	listConfig.columns = i
	widget.addChild(giftList, listConfig, "itemList")
	widget.setVisible("buttonBox.giftSelect.itemList", true)
	i = 0
	for key, value in pairs(player.itemsWithTag("moth_present")) do
		if mothConfig.clientConfigs.debug.value or (not((value.name == "moth_perfectlydespicableitem") or (value.name == "moth_perfectlyromanticitem"))) then
			local potentialPresent = string.format("%s.%s",giftList .. ".itemList",widget.addListItem(giftList .. ".itemList"))
			widget.setItemSlotItem(potentialPresent .. ".present", value)
			i = i + 1
		end
	end
end

function loadDateSpots()
	widget.clearListItems(dateList)
	for key, value in pairs(mothConfig.dateConfig) do
		local dateLocation = string.format("%s.%s",dateList,widget.addListItem(dateList))
		widget.setImage(dateLocation .. ".location", value)
	end
end

function showAnswers()
end