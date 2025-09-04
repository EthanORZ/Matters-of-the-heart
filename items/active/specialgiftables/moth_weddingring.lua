loadUniqueInteractions = function(item)
	payload = {
		promise = world.sendEntityMessage(sourceId, "moth_trymarry", player.id(), playerCanMarry(playerRelationships)),
		item = item,
		funct = function(result)
			if result then
				playerRelationships[npcData.fullSeed].relations.data.isSpouse = true
				newEmote("persist", "oooh", 3, 0.2, 2.0)
				queuedMessages = growArray(queuedMessages, getTranslatedDialogue(mothConfig.language, "onMarriage", species, npcData.personality))
			else
				queuedMessages = growArray(queuedMessages, getTranslatedDialogue(mothConfig.language, "onMarriageFailure", species, npcData.personality))
				newEmote("persist", "neutral", 2, 0.2, 2.0)
				world.spawnItem(payload.item, world.entityPosition(player.id()))
			end
		end
	}
end