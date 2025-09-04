loadUniqueInteractions = function(item)
	playerRelationships = stackRelationshipLevel(playerRelationships, npcData.fullSeed, sourceId, mothConfig.flirtingValues.giftLikedValue)
	newEmote("persist", "happy", 2, 0.2, 2.0)
	queuedMessages = growArray(queuedMessages, getTranslatedDialogue(mothConfig.language, "onGiftLiked", species, npcData.personality))
	useCooldown("btnGift", mothConfig.flirtingValues.giftCount, mothConfig.flirtingValues.giftCooldown)
end