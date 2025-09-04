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

	-- select the generation profile to use
	local builderConfig = {}
	if config.builderConfig then
		builderConfig = randomFromList(config.builderConfig, seed, "builderConfig")
	end
	
	-- localises the item
	local language = getConfig().language
	if ((not (parameters.localisation)) or (not (parameters.localisation == language))) then
		parameters.localisation = language
		parameters.shortdescription = getTranslatedMiscellaneous(language, config.entryshortdescription)
		parameters.description = getTranslatedMiscellaneous(language, config.entrydescription)
		parameters.category = getTranslatedMiscellaneous(language, config.entrycategory)
		if parameters.entryshortdescription then parameters.shortdescription = getTranslatedMiscellaneous(language, parameters.entryshortdescription) end
		if parameters.entrydescription then parameters.description = getTranslatedMiscellaneous(language, parameters.entrydescription) end
		if parameters.entrycategory then parameters.category = getTranslatedMiscellaneous(language, parameters.entrycategory) end
	end

	return config, parameters
end