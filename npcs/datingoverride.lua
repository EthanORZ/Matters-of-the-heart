require "/scripts/mothutil.lua"
require "/scripts/mothmisc.lua"

local mothInit = init
local mothInteract = interact
local mothDie = die

init = function()
	mothConfig = getConfig()
	message.setHandler("moth_pacify", function (_, _)
		if (config.getParameter("aggressive", false)) then
			local params = {
				scriptConfig = {
					behaviorConfig = {
						patrolTime = 0
					}
				},
				items = {
					override = {
						{
							0, {
								{}
							}
						}
					}
				}
			}
			if npc.getItemSlot("head") then params.items.override[1][2][1].head = {npc.getItemSlot("head")} end
			if npc.getItemSlot("headCosmetic") then params.items.override[1][2][1].headCosmetic = {npc.getItemSlot("headCosmetic")} end
			if npc.getItemSlot("chest") then params.items.override[1][2][1].chest = {npc.getItemSlot("chest")} end
			if npc.getItemSlot("chestCosmetic") then params.items.override[1][2][1].chestCosmetic = {npc.getItemSlot("chestCosmetic")} end
			if npc.getItemSlot("legs") then params.items.override[1][2][1].legs = {npc.getItemSlot("legs")} end
			if npc.getItemSlot("legsCosmetic") then params.items.override[1][2][1].legsCosmetic = {npc.getItemSlot("legsCosmetic")} end
			if npc.getItemSlot("back") then params.items.override[1][2][1].back = {npc.getItemSlot("back")} end
			if npc.getItemSlot("backCosmetic") then params.items.override[1][2][1].backCosmetic = {npc.getItemSlot("backCosmetic")} end
			if npc.getItemSlot("primary") then params.items.override[1][2][1].primary = {npc.getItemSlot("primary")} end
			if npc.getItemSlot("alt") then params.items.override[1][2][1].alt = {npc.getItemSlot("alt")} end
			if npc.getItemSlot("sheathedprimary") then params.items.override[1][2][1].sheathedprimary = {npc.getItemSlot("sheathedprimary")} end
			if npc.getItemSlot("sheathedalt") then params.items.override[1][2][1].sheathedalt = {npc.getItemSlot("sheathedalt")} end
			local id = world.spawnNpc(npc.toAbsolutePosition({0,0}), npc.species(), "guard", npc.level(), npc.seed(), params)
			world.spawnProjectile("moth_placeholder", world.entityPosition(id), id, {0,1}, true, { timeToLive = 0.2, actionOnReap = {{ action = "sound", options = { "/sfx/galgun/success.ogg" }}}})
			mcontroller.setYPosition(0)
			self.forceDie = true
		end
	end)
	message.setHandler("moth_modifyRelationship", function (_, _, key, value)
		advancedRelationships()
		if not storage.advancedRelationships[key] then
			storage.advancedRelationships[key] = { married = false, level = 0 }
		end
		storage.advancedRelationships[key].level = value
	end)
	message.setHandler("moth_modifyFamily", function (_, _, relation, name)
		advancedRelationships()
		table.insert(storage.advancedFamily[relation], name)
	end)
	message.setHandler("moth_wear", function (_, _, slot, item)
		npc.setItemSlot(slot, item)
	end)
	message.setHandler("moth_getFullSeed", function (_, _)
		return getFullSeed()
	end)
	message.setHandler("moth_immigrate", function (_, _)
		storage.itemSlots = {}
		if npc.getItemSlot("head") then storage.itemSlots[string.lower("head")] = npc.getItemSlot("head") end
		if npc.getItemSlot("headCosmetic") then storage.itemSlots[string.lower("headCosmetic")] = npc.getItemSlot("headCosmetic") end
		if npc.getItemSlot("chestCosmetic") then storage.itemSlots[string.lower("chestCosmetic")] = npc.getItemSlot("chestCosmetic") end
		if npc.getItemSlot("legsCosmetic") then storage.itemSlots[string.lower("legsCosmetic")] = npc.getItemSlot("legsCosmetic") end
		if npc.getItemSlot("back") then storage.itemSlots[string.lower("back")] = npc.getItemSlot("back") end
		if npc.getItemSlot("backCosmetic") then storage.itemSlots[string.lower("backCosmetic")] = npc.getItemSlot("backCosmetic") end
		if npc.getItemSlot("primary") then storage.itemSlots[string.lower("primary")] = npc.getItemSlot("primary") end
		if npc.getItemSlot("alt") then storage.itemSlots[string.lower("alt")] = npc.getItemSlot("alt") end
		if npc.getItemSlot("sheathedprimary") then storage.itemSlots[string.lower("sheathedprimary")] = npc.getItemSlot("sheathedprimary") end
		if npc.getItemSlot("sheathedalt") then storage.itemSlots[string.lower("sheathedalt")] = npc.getItemSlot("sheathedalt") end
		return {			
			species = npc.species(),
			seed = npc.seed(),
			type = npc.npcType(),
			storedData = storage,
			identity = npc.humanoidIdentity()
		}
	end)
	message.setHandler("moth_getIdentity", function(_, _)
		return npc.humanoidIdentity()
	end)
	message.setHandler("moth_immigratereturn", function (_, _)
		immigration = true
		status.setPersistentEffects("mattersoftheheart", {"beamoutanddie"})
	end)
	message.setHandler("moth_trydelete", function (_, _, id)
		local deletable = false
		if keyExists(getFullKey(id), storage.advancedRelationships) then
			deletable = true
			if isMarried(id) then
				deletable = false
			end
		end
		return deletable			
	end)
	message.setHandler("moth_delete", function (_, _, id)
		storage.advancedRelationships[getFullKey(id)] = nil		
	end)
	message.setHandler("moth_trymarry", function (_, _, id, playerCanMarry)
		local marriable = false
		if canMarry(id) and couldMarry(id) and playerCanMarry then
			marriable = true
			local key = getFullKey(id)
			storage.advancedRelationships[key].married = true
		end
		return marriable			
	end)
	message.setHandler("moth_trydivorce", function (_, _, id, isDivorcing)
		local divorcable = false
		if isMarried(id) then
			divorcable = true
			if isDivorcing then
				local key = getFullKey(id)
				storage.advancedRelationships[key].married = false
			end
		end
		return divorcable			
	end)
	
	local deaths = world.getProperty("moth_npcdeaths", {})
	for deathKey, deathValue in pairs(deaths) do
		if deathValue == getFullSeed() then
			deaths[deathKey] = nil
		end
	end
	world.setProperty("moth_npcdeaths", deaths)
	immigration = false
	if mothInit then mothInit() end
end

interact = function(args)
	if ((not config.getParameter("aggressive", false)) and (world.terrestrial() or (world.type() == "unknown"))) then
		local playerSpecies = world.entitySpecies(args.sourceId)
		world.sendEntityMessage(args.sourceId, "moth_romance", entity.id(), {
			fullSeed = getFullSeed(),
			personality = personalityType(),
			giftPreferences = giftPreferences(),
			genderPreference = genderPreference(),
			relations = getRomanceStatus(args.sourceId),
			romanticAffinity = romanticAffinity(args.sourceId),
			portrait = world.entityPortrait(entity.id(), "bust")
		})
	end
	if mothInteract then return mothInteract(args) end
end

die = function()
	if not immigration then
		if storage.advancedRelationships then
			local deaths = world.getProperty("moth_npcdeaths", {})
			deaths[getFullSeed()] = {
				seed = npc.seed(),
				species = npc.species(),
				identity = npc.humanoidIdentity(),
				type = npc.npcType(),
				storage = storage
			}
			world.setProperty("moth_npcdeaths", deaths)
			local year, month, day = nebTimeUtil.getCurrentYearMonthDay()
			local graveParams = {
				yearOfDeath = year,
				monthOfDeath = month,
				dayOfDeath = day,
				victim = world.entityName(entity.id())
			}
			world.spawnItem("moth_gravestone", npc.toAbsolutePosition({0,0}), 1, graveParams, {0,60}, 0.5)
		end
		if mothDie then mothDie() end
	end
end

function getRomanceStatus(id)
	advancedFamily()
	return { 
		couldMarry = couldMarry(id), 
		isSpouse = isMarried(id),
		parents = storage.advancedFamily.parents,
		siblings = storage.advancedFamily.siblings,
		children = storage.advancedFamily.children
	}
end

function canMarry(id)
	local marriable = true
	local key = getFullKey(id)
	if keyExists(key, advancedRelationships()) then
		if advancedRelationships()[key].level < mothConfig.flirtingValues.MarryCap then marriable = false end
	else
		marriable = false
	end
	return marriable
end

function couldMarry(id)
	local marriable = true
	local key = getFullKey(id)
	if not mothConfig.allowPolygamy then
		for k, v in pairs(advancedRelationships()) do
			if v.married then marriable = false end
		end
	end
	if not mothConfig.allowIncest then
		for k, v in pairs(advancedFamily().parents) do
			if v == world.entityName(id) then marriable = false end
		end
		for k, v in pairs(advancedFamily().siblings) do
			if v == world.entityName(id) then marriable = false end
		end
		for k, v in pairs(advancedFamily().children) do
			if v == world.entityName(id) then marriable = false end
		end
	end
	return marriable
end

function isMarried(id)
	local hasSpouse = false
	local key = getFullKey(id)
	if keyExists(key, advancedRelationships()) then
		hasSpouse = advancedRelationships()[key].married or false
	end
	return hasSpouse
end

-- Returns the full seed of a NPC
function getFullSeed()
	return npc.species() .. "_" .. npc.seed()
end

-- Returns the full key of a player
function getFullKey(id)
	return world.entitySpecies(id) .. "_" .. world.entityUniqueId(id)
end

-- Existing advancedFamily
function advancedFamily()
	if not storage.advancedFamily then
		storage.advancedFamily = {
			parents = {},
			siblings = {},
			children = {}
		}
	end
	return storage.advancedFamily
end

-- Existing advancedRelationships
function advancedRelationships()
	if not storage.advancedRelationships then
		storage.advancedRelationships = {}
	end
	return storage.advancedRelationships
end

-- Gift preferences
function giftPreferences()
	if not 
		storage.giftPreferences or 
		storage.lastCategoriesSize or 
		storage.lastUniquesSize or 
		(storage.lastCategoriesSize ~= tLength(mothConfig.giftCategories)) or 
		(storage.lastUniquesSize ~= tLength(mothConfig.giftCategoriesUnique)) 
	then
		storage.giftPreferences = generateGiftPreferences()
		storage.lastCategoriesSize = tLength(mothConfig.giftCategories)
		storage.lastUniquesSize = tLength(mothConfig.giftCategoriesUnique)
	end
	return storage.giftPreferences
end

function generateGiftPreferences()
	local influence = copy(mothConfig.personalityGiftInfluence)
	local preferences = {
		hated = influence^-1,
		disliked = (influence^-1)^0.5,
		liked = (influence)^0.5,
		loved = influence
	}
	preferences.loved = generateLoved(preferences.loved, {})
	preferences.liked = generateLiked(preferences.liked, {preferences.loved})
	preferences.disliked = generateDisliked(preferences.disliked, {preferences.loved, preferences.liked})
	preferences.hated = generateHated(preferences.hated, {preferences.loved, preferences.liked, preferences.disliked})
	return preferences
end
function generateLoved(giftAffinity, blockRepeatsArray)
	local giftTypes = copy(mothConfig.giftCategories)
	giftTypes["miscellaneous"] = copy(mothConfig.giftCategoriesUnique.miscellaneous)
	giftTypes["outfits"] = copy(mothConfig.giftCategoriesUnique.outfits)
	for giftKey, giftValue in pairs(giftTypes) do
		if valueExists(personalityType(), giftValue.undesired) then
			table.insert(blockRepeatsArray, giftKey)
		end
	end
	return weightedRandom({
		{499, generateGiftPreference(giftTypes, blockRepeatsArray, giftAffinity)},
		{1, "junk"}
	}, npc.seed()).value
end
function generateLiked(giftAffinity, blockRepeatsArray)
	local giftTypes = copy(mothConfig.giftCategories)
	giftTypes["miscellaneous"] = copy(mothConfig.giftCategoriesUnique.miscellaneous)
	giftTypes["outfits"] = copy(mothConfig.giftCategoriesUnique.outfits)
	return generateGiftPreference(giftTypes, blockRepeatsArray, giftAffinity)
end
function generateDisliked(giftAffinity, blockRepeatsArray)
	local giftTypes = copy(mothConfig.giftCategories)
	giftTypes["miscellaneous"] = copy(mothConfig.giftCategoriesUnique.miscellaneous)
	return generateGiftPreference(giftTypes, blockRepeatsArray, giftAffinity)
end
function generateHated(giftAffinity, blockRepeatsArray)
	local giftTypes = copy(mothConfig.giftCategories)
	giftTypes["miscellaneous"] = copy(mothConfig.giftCategoriesUnique.miscellaneous)
	for giftKey, giftValue in pairs(giftTypes) do
		if valueExists(personalityType(), giftValue.prefered) then
			table.insert(blockRepeatsArray, giftKey)
		end
	end
	return generateGiftPreference(giftTypes, blockRepeatsArray, giftAffinity)
end
function generateGiftPreference(selection, blockedSelection, giftAffinity)
	local giftWeights = {}
	for key, value in pairs(blockedSelection) do
		selection[value] = nil
	end
	for giftKey, giftValue in pairs(selection) do
		if valueExists(personalityType(), giftValue.prefered) then
			table.insert(giftWeights, {giftAffinity, giftKey})
		elseif valueExists(personalityType(), giftValue.undesired) then
			table.insert(giftWeights, {(giftAffinity^-1), giftKey})
		else
			table.insert(giftWeights, {1.0, giftKey})
		end
	end
	return weightedRandom(giftWeights, npc.seed()).value
end

-- Gender preferences
function genderPreference()
	local preference = "pansexual"
	if not storage.genderPreference then
		storage.genderPreference = generateGenderPreference()
	end
	-- remove once out of beta
	if print(type(storage.genderPreference)) == "table" then generateGenderPreference() end
	if mothConfig.enableGenderPreferences then preference = storage.genderPreference end
	return preference
end

function generateGenderPreference()
	return weightedRandom(mothConfig.genderPreferencesOdds, npc.seed()).value
end

-- Romantic affinity : random affinity and racial affinity
function romanticAffinity(id)
	local affinity = 0
	-- remove once out of beta
	if print(type(storage.romanticAffinity)) == "number" then storage.romanticAffinity = nil end
	if not storage.romanticAffinity then storage.romanticAffinity = {} end
	if not keyExists(getFullKey(id), storage.romanticAffinity) then
		storage.romanticAffinity[getFullKey(id)] = generateRomanticAffinity()
		sb.logInfo(sb.printJson(storage.romanticAffinity))
	end
	if mothConfig.enableRandomAffinity then
		affinity = storage.romanticAffinity[getFullKey(id)]
		if (mothConfig.enableRacialAffinity) then
			local nRace = "default"
			local pRace = "default"
			
			if keyExists(npc.species(), mothConfig.racialConfig) then nRace = npc.species() end
			if keyExists(world.entitySpecies(id), mothConfig.racialConfig[nRace].affinities) then pRace = world.entitySpecies(id) end
				
			local proportion = mothConfig.randomRacialAffinityProportion[1] + mothConfig.randomRacialAffinityProportion[2]
			affinity = (affinity * (mothConfig.randomRacialAffinityProportion[1]/proportion)) + (mothConfig.racialConfig[nRace].affinities[pRace] * (mothConfig.randomRacialAffinityProportion[2]/proportion))
		end
	else
		if (mothConfig.enableRacialAffinity) then
			local nRace = "default"
			local pRace = "default"
			
			if keyExists(npc.species(), mothConfig.racialConfig) then nRace = npc.species() end
			if keyExists(world.entitySpecies(id), mothConfig.racialConfig[nRace].affinities) then pRace = world.entitySpecies(id) end
			
			affinity = mothConfig.racialConfig[nRace].affinities[pRace]
		end
	end
	return affinity
end

function generateRomanticAffinity()
	return weightedRandom({
			{0.2, -4},
			{0.4, -3},
			{0.6, -2},
			{0.8, -1},
			{1.0, 0},
			{0.8, 1},
			{0.6, 2},
			{0.4, 3},
			{0.2, 4}
		}, 
		npc.seed()
	).value
end