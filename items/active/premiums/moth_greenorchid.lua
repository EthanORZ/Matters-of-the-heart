loadUniqueInteractions = function(item)
	playerRelationships[npcData.fullSeed].cooldowns.data = {}
	newEmote("persist", "oooh", 3, 0.2, 2.0)
	queuedMessages = growArray(queuedMessages, getTranslatedDialogue(mothConfig.language, "onGiftNeutral", species, npcData.personality))
end