require "/scripts/util.lua"
require "/scripts/vec2.lua"
require "/scripts/versioningutils.lua"
require "/scripts/staticrandom.lua"
require "/scripts/mothutil.lua"
require "/scripts/mothmisc.lua"

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
	if not parameters.graved then
		parameters.graved = true
		local year, month, day = nebTimeUtil.getCurrentYearMonthDay()
		if not parameters.victim then parameters.victim = getTranslatedMiscellaneous(mothConfig.language, "stranger") end
		if not parameters.yearOfDeath then parameters.yearOfDeath = year end
		if not parameters.monthOfDeath then parameters.monthOfDeath = month end
		if not parameters.dayOfDeath then parameters.dayOfDeath = day end
	end
	parameters.shortdescription = string.format(getTranslatedMiscellaneous(mothConfig.language, "graveName"), parameters.victim)
	parameters.description = string.format(
		getTranslatedMiscellaneous(mothConfig.language, "graveDescription"), 
		parameters.victim, 
		string.format("%02d/%02d/%04d", parameters.dayOfDeath, parameters.monthOfDeath, parameters.yearOfDeath)
	)
	
	return config, parameters
end