loadUniqueInteractions = function(item)
	playerRelationships = setRelationshipLevel(playerRelationships, npcData.fullSeed, sourceId, (mothConfig.flirtingValues.heartsCap+mothConfig.flirtingValues.overHeartsCap))
	newEmote("persist", "oooh", 3, 0.2, 2.0)
	queuedMessages = growArray(queuedMessages, getTranslatedDialogue(mothConfig.language, "onGiftLoved", species, npcData.personality))
	useCooldown("btnGift", mothConfig.flirtingValues.giftCount, mothConfig.flirtingValues.giftCooldown)
end