function buildLoveCondition(config)
	local gatherLoveCondition = {
		description = config.description,
		property = config.property
	}

	function gatherLoveCondition:conditionMet()
		local flags = player.getProperty("moth_questflags", {})
		if keyExists(self.property, flags) then return flags[self.property] else return false end
	end

	function gatherLoveCondition:onQuestComplete()
	end

	function gatherLoveCondition:objectiveText()
		return self.description
	end

	return gatherLoveCondition
end