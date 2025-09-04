require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/versioningutils.lua"
require "/items/buildscripts/abilities.lua"
require "/scripts/mothutil.lua"

function build(directory, config, parameters, level)
	local configParameter = function(keyName, defaultValue)
		if parameters[keyName] ~= nil then
			return parameters[keyName]
		elseif config[keyName] ~= nil then
			return config[keyName]
		else
			return defaultValue
		end
	end
	local mothConfig = getConfig()
	
	-- setups the baby
	if not parameters.generated then
		parameters.generated = true
		parameters.shortdescription = parameters.npcParameters.identity.name
		local species = "default"
		if mothConfig.racialConfig[parameters.npcParameters.species] then species = parameters.npcParameters.species end
		local directives = ""
		for k,v in pairs(parameters.npcParameters.identity) do
			if (not ((k == "name") or (k == "gender"))) then 
				directives = directives .. v
			end
		end
		parameters.inventoryIcon = mothConfig.racialConfig[species][parameters.npcParameters.identity.gender].babyImage .. directives
		parameters.incubationTime = mothConfig.racialConfig[species].incubationTime
		parameters.incubationTimeMax = mothConfig.racialConfig[species].incubationTime
		parameters.oviparous = mothConfig.racialConfig[species].oviparous
		parameters.cleanName = root.assetJson("/species/" .. parameters.npcParameters.species .. ".species").charCreationTooltip.title
		parameters.category = getTranslatedMiscellaneous(mothConfig.language, "baby")
		local b = "baby"
		if parameters.oviparous then b = "egg" end
		parameters.description = string.format(getTranslatedMiscellaneous(mothConfig.language, b .. "Description"), parameters.cleanName)
	end

	return config, parameters
end