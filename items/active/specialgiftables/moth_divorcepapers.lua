loadUniqueInteractions = function(item)
	payload = {
		promise = world.sendEntityMessage(sourceId, "moth_trydivorce", player.id(), true),
		funct = function(result)
			if result then
				playerRelationships[npcData.fullSeed].relations.data.isSpouse = false
				queuedMessages = growArray(queuedMessages, getTranslatedDialogue(mothConfig.language, "onDivorce", species, npcData.personality))
				playerRelationships = stackRelationshipLevel(playerRelationships, npcData.fullSeed, sourceId, -(mothConfig.flirtingValues.overHeartsCap + (mothConfig.flirtingValues.heartsCap/2)))
				newEmote("looping", "sad", 5, 0.2, 3.0)
			else
				world.spawnItem(payload.item, world.entityPosition(player.id()))
			end
		end
	}
end