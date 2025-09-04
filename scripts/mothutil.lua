require "/scripts/util.lua"
require "/scripts/mothidentity.lua"
----------------------------
-- PLAYER-SIDE INTERFACES --
----------------------------



-- This opens the settings menu
function openSettings()
	local cfg = root.assetJson("/interface/scripted/moth_settings/moth_settings.config")
	cfg.gui.save_button.caption = getTranslatedMiscellaneous(mothConfig.language, "settingSave")
	cfg.gui.reset_button.caption = getTranslatedMiscellaneous(mothConfig.language, "settingReset")
	cfg.gui.windowtitle.title = getTranslatedMiscellaneous(mothConfig.language, "settingTitle")
	cfg.gui.windowtitle.subtitle = " ^#b9b5b2;" .. getTranslatedMiscellaneous(mothConfig.language, "settingSubtitle")
	local orderedList = {}
	local maxHeight = 196
	local minHeight = 45
	local height = maxHeight 
	local page = 1
	local widgetCount = 1
	for key, value in pairs(mothConfig.clientConfigs) do
		local setting = copy(value)
		orderedList[value.order] = copy(value)
		orderedList[value.order].name = key
	end
	for i = 1,#orderedList do
		local v = orderedList[i]
		local w = { height = 0 }
		for key, value in pairs(cfg.clientConfigTypes[v.type]) do
			--sb.logInfo("setting_" .. widgetCount .. "_" .. key .. " | " .. sb.printJson(value))
			if key == "height" then 
				w.height = copy(value)
			else
				local k = "setting_" .. widgetCount .. "_" .. key
				w[k] = copy(value)
				-- sb.logInfo(sb.printJson(w[k]))
			end
		end
		height = height - w.height
		if height < minHeight then
			height = maxHeight
			page = page + 1
			cfg.gui.pagesGroup.buttons[page] = copy(cfg.gui.pagesGroup.buttons[1])
			cfg.gui.pagesGroup.buttons[page].selected = false
			cfg.gui.pagesGroup.buttons[page].id = page
			cfg.gui.pagesGroup.buttons[page].text = "" .. page
			cfg.gui.pagesGroup.buttons[page].position[2] = (151 - (25*page))
			-- "buttons" : [
				-- {
					-- "id" : 1,
					-- "baseImage": "/interface/scripted/moth_settings/page.png",
					-- "hoverImage": "/interface/scripted/moth_settings/page.png?brightness=30",
					-- "baseImageChecked": "/interface/scripted/moth_settings/selectedpage.png",
					-- "hoverImageChecked": "/interface/scripted/moth_settings/selectedpage.png?brightness=30",
					-- "pressedOffset": [ 0, 0 ],
					-- "text" : "1",
					-- "fontColor" : "gray",
					-- "fontColorChecked" : "white",
					-- "position": [ 1, 126 ],
					-- "selected": true
				-- }
			-- ]
		end
		for key, value in pairs(w) do
			if key ~= "height" then
				-- sb.logInfo(sb.print(w[key].position))
				w[key].position[2] = w[key].position[2] + height
				-- sb.logInfo(sb.print(w[key].position))
				w[key].visible = false
			end
		end
		-- sb.logInfo(sb.printJson(w))
		w["setting_" .. widgetCount .. "_label"].value = getTranslatedMiscellaneous(mothConfig.language, v.title)
		if v.type == "slider" then
			w["setting_" .. widgetCount .. "_slider"].data = v.name
			w["setting_" .. widgetCount .. "_value"].value = "" .. v.value
			--local percent = math.floor(((v.value-v.minimum)/(v.maximum-v.minimum))*100)
			w["setting_" .. widgetCount .. "_slider"].value = percent
			
			-- sb.logInfo(sb.printJson(cfg.pages))
			-- sb.logInfo(sb.printJson(cfg.pages[page]))
			-- sb.logInfo(sb.printJson(cfg.pages[page][tLength(cfg.pages[page])]))
			table.insert(cfg.pages[page], "setting_" .. widgetCount .. "_label")
			table.insert(cfg.pages[page], "setting_" .. widgetCount .. "_value")
			table.insert(cfg.pages[page], "setting_" .. widgetCount .. "_box")
			table.insert(cfg.pages[page], "setting_" .. widgetCount .. "_slider")
		elseif v.type == "check" then
			w["setting_" .. widgetCount .. "_button"].data = v.name
			w["setting_" .. widgetCount .. "_button"].checked = v.value
			
			table.insert(cfg.pages[page], "setting_" .. widgetCount .. "_label")
			table.insert(cfg.pages[page], "setting_" .. widgetCount .. "_button")
		end
		height = height - cfg.settingsSpacing
		widgetCount = widgetCount + 1
		for key, value in pairs(w) do
			if key ~= "height" then
				cfg.gui[key] = copy(value)
			end
		end
	end
	-- sb.logInfo(sb.printJson(cfg, 1))
	player.interact("ScriptPane", cfg, player.id())
end

-- This gets the server configs and the client configs, merges them and returns them
function getConfig()
	local serverConfig = root.assetJson("/mattersoftheheart.config")
	if player then
		if player.getProperty then
			local clientConfig = player.getProperty("moth_settings", {})
			for k, v in pairs(clientConfig) do
				serverConfig.clientConfigs[k].value = v 
			end
			if not player.isAdmin() then serverConfig.clientConfigs.debug.value = false end
		end
	end
	return serverConfig
end

-- This gets a random dialogue line from the selected type, based on species and personality, if available
function getTranslatedDialogue(language, dialogueType, species, personality)
	local dialog = root.assetJson("/localisation/" .. language .. "/moth_romance.config")
	if (not (dialog)) then dialog = root.assetJson("/localisation/eng/moth_romance.config") end
	
	local subject = species
	if not (keyExists(subject, dialog)) then subject = "human" end
	if not (keyExists(personality, dialog[subject])) then subject = "human" end
	
	local linesCount = #dialog[subject][personality][dialogueType]
	return dialog[subject][personality][dialogueType][randomNumber(1,linesCount)]
end

-- This gets a random question, based on species and personality, if available
function getTranslatedQuestion(language, species, personality)
	local questions = root.assetJson("/localisation/" .. language .. "/moth_questions.config")
	if (not (questions)) then questions = root.assetJson("/localisation/eng/moth_questions.config") end
	local chosenQuestion = questions[randomNumber(1,#questions)]
	
	local subject = species
	if not (keyExists(subject, chosenQuestion.question)) then subject = "human" end
	if not (keyExists(personality, chosenQuestion.question[subject])) then subject = "human" end
	
	local linesCount = #chosenQuestion.question[subject][personality]
	return { 
		line = chosenQuestion.question[subject][personality][randomNumber(1,linesCount)], 
		question = chosenQuestion 
	}
end

-- This gets an entry key and returns the translated one, if available
function getTranslatedMiscellaneous(language, entry, g)
	local gender = g or "neutral"
	if not((gender=="male")or(gender=="female")) then gender = "neutral" end
	local word = ""
	local text = root.assetJson("/localisation/" .. language .. "/moth_miscellaneous.config")
	if (not (text)) then text = root.assetJson("/localisation/eng/moth_miscellaneous.config") end
	
	if not (keyExists(entry, text)) then 
		text = root.assetJson("/localisation/eng/moth_miscellaneous.config")
	end
	if type(text[entry]) == "table" then
		if text[entry][gender] then
			word = text[entry][gender]
		else
			word = text[entry]["neutral"]
		end
	else
		word = text[entry]
	end
	
	return word
end

-- Adds the relationship value to the player's data
function stackRelationshipLevel(t, k, sourceId, value)
	local mothConfig = getConfig()
	local munie = math.ceil(value*mothConfig.shopConfig.munieRatio)
	player.addCurrency("moth_munie", munie)
	if value >= 0 then
		value = calculateGain(t[k].romanticAffinity.data) * value
	else
		value = calculateLoss(t[k].romanticAffinity.data) * value
	end
	local new = t[k].level.data + value
	local pos = world.entityPosition(sourceId)
	pos[2] = pos[2] + 2
	world.sendEntityMessage(player.id(), "moth_particle", value, pos)
	
	if new < mothConfig.flirtingValues.evilHeartsCap then new = mothConfig.flirtingValues.evilHeartsCap end
	local cap = mothConfig.flirtingValues.heartsCap
	if getRelationshipStatus(t, k) == "Spouse" then cap = cap + mothConfig.flirtingValues.overHeartsCap end
	if new > cap then new = cap end
	
	t[k].level.data = new
	world.sendEntityMessage(sourceId, "moth_modifyRelationship", player.species() .. "_" .. player.uniqueId(), new)
	return t
end

-- Sets the relationship value to the player's data
function setRelationshipLevel(t, k, sourceId, value)
	local mothConfig = getConfig()
	local new = value
	
	if new < mothConfig.flirtingValues.evilHeartsCap then new = mothConfig.flirtingValues.evilHeartsCap end
	local cap = mothConfig.flirtingValues.heartsCap
	if getRelationshipStatus(t, k) == "Spouse" then cap = cap + mothConfig.flirtingValues.overHeartsCap end
	if new > cap then new = cap end
	
	t[k].level.data = new
	world.sendEntityMessage(sourceId, "moth_modifyRelationship", player.species() .. "_" .. player.uniqueId(), new)
	return t
end

-- Updates a value from the player's data
function updateRelationshipValue(t, k, valueName, value)
	t[k][valueName].data = value
	return t
end

-- Returns a value from the player's data
function getRelationshipValue(t, k, valueName)
	return t[k][valueName].data
end

-- Unlocks a value from the player's data
function unlocksRelationshipValue(t, k, valueName)
	t[k][valueName].unlocked = true
	return t
end

-- Removes a relationship from a player's data
function deleteRelationship(t, k)
	if keyExists(k, t) then
		t[k] = nil
	end
	return t
end

-- Checks if every learnable thing is unlocked
function everythingUnlocked(t, k)
	local somethingLocked = false
	for key, value in pairs(t[k]) do
		if not value.ignore then
			if not value.unlocked then
				somethingLocked = true
			end
		end
	end
	return not somethingLocked
end

-- Returns the cooldown for a specific key
function getCooldown(t, k, cooldownKey)
	local cds = getRelationshipValue(t, k, "cooldowns")
	if keyExists(cooldownKey, cds) then
		return cds[cooldownKey]
	else
		return { time = 0, count = 0, maxTime = 0 }
	end
end

-- Sets a cooldown and a count for a specific key
function setCooldown(t, k, cooldownKey, currentTime, c)
	local cds = getRelationshipValue(t, k, "cooldowns")
	cds[cooldownKey].time = currentTime
	cds[cooldownKey].count = c
	return updateRelationshipValue(t, k, "cooldowns", cds)
end

-- This provides cooldown management
function calculateCooldown(cd, currentTime)
	local passedTime = cd.maxTime-(currentTime-cd.time)
	if passedTime <= 0 then
		return false
	else
		return parseCooldown(passedTime)
	end
end

-- Checks if a cooldown is ready
function cooldownReady(t, k, cooldownKey)
	local cds = getCooldown(t, k, cooldownKey)
	local cd = calculateCooldown(cds, os.time())
	if (not((cds.count <= 0) and (cd))) then
		return true
	else
		return false
	end
end

-- This transforms a time into a string
function parseCooldown(t)
	t = t - 1
	local seconds = math.floor(t) % 60
	local minutes = math.floor(t/60) % 60
	local hours = math.floor(t/3600)
	return (string.format("%02d",hours) .. ":" .. string.format("%02d",minutes) .. ":" .. string.format("%02d",seconds))
end

-- Gets the relationship status depending on the level
function getRelationshipStatus(t, npcKey)
	local genderNPC = t[npcKey].gender.data
	local genderPlayer = player.gender()
	local status = "Acquaintance"
	local mothConfig = getConfig()
	if keyExists(npcKey, t) then
		if t[npcKey].relations.data.isSpouse then
			status = "Spouse"
		else
			if (t[npcKey].level.data <= mothConfig.flirtingValues.AnnoyanceCap) then
				status = "Annoyance"
			elseif (t[npcKey].level.data >= mothConfig.flirtingValues.LoverCap) then
				if 	(t[npcKey].relations.data.couldMarry and playerCanMarry(t) and
					((t[npcKey].genderPreference.data == "pansexual") or 
					(t[npcKey].genderPreference.data == "homosexual" and (genderNPC == genderPlayer)) or 
					(t[npcKey].genderPreference.data == "heterosexual" and (genderNPC ~= genderPlayer)))) then
					status =  "Lover"
				else
					status =  "BestFriend"
				end
			elseif (t[npcKey].level.data >= mothConfig.flirtingValues.FriendCap) then
				status =  "Friend"
			end
		end
	end
	return status
end

-- Checks if the player can marry the NPC
function playerCanMarry(t)
	local marriable = true
	if not mothConfig.allowPolygamy then
		for k, v in pairs(t) do
			if v.relations.data.isSpouse then marriable = false end
		end
	end
	return marriable
end

-- This provides affinity gain multipliers
function calculateGain(n)
	return truncateDecimals(2^(n/3), 1)
end

-- This provides affinity loss multipliers
function calculateLoss(n)
	return truncateDecimals(2^(-n/3), 1)
end

-- This provides affinity loss multipliers
function calculateBirthChance(n)
	if n >= 0 then
		return ((-2^(-n/2))*50+100)
	else
		return (((2^(n/2))-2)*50+100)
	end
end

-- Returns a string displaying how long it has been since the last interaction
function lastTime(language, t)
	local timeDifference = math.floor(player.playTime())-t
	local s = ""
	if timeDifference < 60 then
		if (timeDifference>1) then 
			s = string.format(getTranslatedMiscellaneous(language, "seconds"), timeDifference)
		else
			s = string.format(getTranslatedMiscellaneous(language, "second"), timeDifference)
		end
	elseif timeDifference < 3600 then
		local n = math.floor(timeDifference/60)
		if (n>1) then 
			s = string.format(getTranslatedMiscellaneous(language, "minutes"), n)
		else
			s = string.format(getTranslatedMiscellaneous(language, "minute"), n)
		end
	elseif timeDifference < 86400 then
		local n = math.floor(timeDifference/3600)
		if (n>1) then 
			s = string.format(getTranslatedMiscellaneous(language, "hours"), n)
		else
			s = string.format(getTranslatedMiscellaneous(language, "hour"), n)
		end
	else
		local n = math.floor(timeDifference/86400)
		if (n>1) then 
			s = string.format(getTranslatedMiscellaneous(language, "days"), n)
		else
			s = string.format(getTranslatedMiscellaneous(language, "day"), n)
		end
	end
	return s
end

-- Sets the hearts to the specified level
function setHearts(w, level, style)
	local mothConfig = getConfig()
	for i=1,10 do
		if level >= ((i*(mothConfig.flirtingValues.overHeartsCap/10))+mothConfig.flirtingValues.heartsCap) then
			widget.setImage(w .. i, "/interface/scripted/moth_romance/heart_over" .. style .. ".png")			
		elseif level >= (i*(mothConfig.flirtingValues.heartsCap/10)) then
			widget.setImage(w .. i, "/interface/scripted/moth_romance/heart" .. style .. ".png")
		elseif level <= (i*(mothConfig.flirtingValues.evilHeartsCap/10)) then
			widget.setImage(w .. i, "/interface/scripted/moth_romance/heart_evil" .. style .. ".png")
		else
			widget.setImage(w .. i, "/interface/scripted/moth_romance/heart_empty" .. style .. ".png")
		end
	end
end

-- Gives a seed to generate the rotating shop with
function rotationSeed() return math.floor(os.time()/mothConfig.shopConfig.shopRotationTime) end

-- Gets the identity from the player's portrait
function getPlayerIdentity()
	return buildIdentity()
end

-- Removes the first element in the array and shifts everything down
function shiftArray(list)
	local new = {}
	if ((#list)-1) > 0 then
		for i = 1, ((#list)-1) do
			new[i] = list[(i+1)]
		end
	end
	return new
end

-- Adds an element in the first index of the array and shifts everything up
function growArray(list, elem)
	local new = {}
	new[1] = elem
	for i = 1, (#list) do
		new[i+1] = list[i]
	end
	return new
end

-- Gets random integral number from x to y
function randomNumber(n1, n2)
	return math.random(n1, n2)
	--return sb.staticRandomI32Range(n1, n2, os.time())
end

-- Checks if the key exists in the table
function keyExists(k, t)
	return (t[k] ~= nil)
end

-- Checks if the value exists in the table
function valueExists(v, t)
	local exists = false
	for key, value in pairs(t) do
		if v == value then exists = true end
	end
	return exists
end

-- Makes the string's first letter into an uppercase
function firstToUpper(str)
	return (str:gsub("^%l", string.upper))
end

-- This rounds a number
function round(n)
	return math.floor(n+0.5)
end

-- Limits the amount of decimals a number can have
function truncateDecimals(n, zeroes)
	local places = 10 ^ zeroes
	return (round(n*places)/places)
end

-- Returns a random weighted option using a seed
function weightedRandom(options, seed)
	local totalWeight = 0
	for _,pair in ipairs(options) do
		totalWeight = totalWeight + pair[1]
	end

	local choice = (seed and sb.staticRandomDouble(seed) or math.random()) * totalWeight
	for k,pair in ipairs(options) do
		choice = choice - pair[1]
		if choice < 0 then
			return {key = k, value = pair[2]}
		end
	end
	return nil
end

-- Returns the table's size
function tLength(t)
	local index = 0
	for _ in pairs(t) do index = index + 1 end
	return index
end

-- Shuffles a table and returns it
function shuffleTable(t)
    local s = {}
    for i = 1, #t do s[i] = t[i] end
    for i = #t, 2, -1 do
        local j = math.random(i)
        s[i], s[j] = s[j], s[i]
    end
    return s
end