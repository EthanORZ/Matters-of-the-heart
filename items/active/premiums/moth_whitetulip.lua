loadUniqueInteractions = function(item)
	payload = {
		promise = world.sendEntityMessage(sourceId, "moth_trydivorce", player.id(), false),
		funct = function(result)
			if result then
				playerRelationships = setRelationshipLevel(playerRelationships, npcData.fullSeed, sourceId, 0)
				queuedMessages = growArray(queuedMessages, getTranslatedDialogue(mothConfig.language, "greetingAcquaintance", species, npcData.personality))
			else
				world.spawnItem(payload.item, world.entityPosition(player.id()))
			end
		end
	}
end