loadUniqueInteractions = function(item)
	playerRelationships = stackRelationshipLevel(playerRelationships, npcData.fullSeed, sourceId, mothConfig.flirtingValues.giftLovedValue)
	newEmote("persist", "oooh", 3, 0.2, 2.0)
	queuedMessages = growArray(queuedMessages, getTranslatedDialogue(mothConfig.language, "onGiftLoved", species, npcData.personality))
	useCooldown("btnGift", mothConfig.flirtingValues.giftCount, mothConfig.flirtingValues.giftCooldown)
end