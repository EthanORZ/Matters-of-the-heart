loadUniqueInteractions = function(item)
	playerRelationships = setRelationshipLevel(playerRelationships, npcData.fullSeed, sourceId, mothConfig.flirtingValues.evilHeartsCap)
	newEmote("looping", "sad", 5, 0.2, 3.0)
	queuedMessages = growArray(queuedMessages, getTranslatedDialogue(mothConfig.language, "onGiftHated", species, npcData.personality))
	useCooldown("btnGift", mothConfig.flirtingValues.giftCount, mothConfig.flirtingValues.giftCooldown)
end