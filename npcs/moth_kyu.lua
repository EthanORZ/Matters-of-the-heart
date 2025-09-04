require "/scripts/mothutil.lua"

function handleInteract(args)
	world.sendEntityMessage(args.sourceId, "moth_kyu", entity.id())
	local language = getConfig().language
    simpleSay({
		dialog = getTranslatedMiscellaneous(language, "availableEntry"),
		entity = args.sourceId,
		tags = {}
    })
end

function QuestParticipant:updateOfferedQuests()
	local offeredQuests = config.getParameter("offeredQuests", jarray())
	npc.setOfferedQuests(offeredQuests)
end

function simpleSay(args, board)
  local dialog = args.dialog

  local tags = sb.jsonMerge(self.dialogTags or {}, args.tags)
  tags.selfname = world.entityName(entity.id())
  if args.entity then
    tags.entityname = world.entityName(args.entity)

    local entityType = world.entityType(args.entity)
    if entityType and entityType == "npc" then
      tags.entitySpecies = world.entitySpecies(args.entity)
    end
  end

  local options = {}

  -- Only NPCs have sound support
  if entity.entityType() == "npc" then
    options.sound = randomChatSound()
  end

  context().say(dialog, tags, options)
  return true
end