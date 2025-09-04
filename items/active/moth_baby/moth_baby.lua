require "/scripts/mothutil.lua"
function init()
	incubationTime = config.getParameter("incubationTime", 3600)
	local lastTime = config.getParameter("lastTime", player.playTime())
	incubationTime = incubationTime - (player.playTime() - lastTime)
	local b = "baby"
	if config.getParameter("oviparous", false) then b = "egg" end
	language = getConfig().language
	activeItem.setInstanceValue("category", getTranslatedMiscellaneous(language, b))
	activeItem.setInstanceValue("description", getAgeTimeDescription(incubationTime))
end

function uninit()
	activeItem.setInstanceValue("incubationTime", incubationTime)
	activeItem.setInstanceValue("lastTime", player.playTime())
	activeItem.setInstanceValue("description", getAgeTimeDescription(incubationTime))
end

function update(dt, fireMode, shiftHeld)
	incubationTime = incubationTime - dt
	activeItem.setInstanceValue("incubationTime", incubationTime)
	activeItem.setInstanceValue("lastTime", player.playTime())
	activeItem.setInstanceValue("description", getAgeTimeDescription(incubationTime))
end

function activate(fireMode, shiftHeld)
	if incubationTime<=0 then
		local npc = config.getParameter("npcParameters")
		world.spawnNpc(entity.position(), npc.species, "villager", world.threatLevel(), npc.seed, {identity=npc.identity,scriptConfig=npc.scriptConfig})
		item.consume(1)
	end
end

function getAgeTimeDescription()
	local entry = "Description"
	local b = "baby"
	if config.getParameter("oviparous", false) then b = "egg" end
	if incubationTime<=0 then
		entry = "Ready"
	elseif (incubationTime / config.getParameter("incubationTimeMax", 3600))<=0.1 then
		entry = "Almost"
	end
	entry = b .. entry
	return string.format(getTranslatedMiscellaneous(language, entry), config.getParameter("cleanName", "Human"))
end
