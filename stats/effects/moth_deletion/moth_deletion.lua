function init()
	script.setUpdateDelta(30)
	breakingup = status.statusProperty("moth_breakingup", nil)
	failed = false
	succeededSearch = false
	successData = nil
	deleteData = {}
	deletePromise = nil
	deaths = world.getProperty("moth_npcdeaths", {})
	if deaths then
		for k,v in pairs(deaths) do
			if k == breakingup.npcKey then
				succeededSearch = true
			end
		end
	end
end

function update()
	if ((not (succeededSearch)) and (not (failed))) then
		--sb.logInfo("Waiting...")
		if (not breakingup) then
			failed = true
			sb.logInfo("property doesnt exist")
		elseif (not breakingup.npcKey) or (not breakingup.oldLocation) or (not breakingup.checkLocation) or (not breakingup.newLocation) or (not math.worldId) or (not math.warp) then
			failed = true
			sb.logInfo("property keys dont exist")
		else
			local matches = world.npcQuery(entity.position(), 10, { withoutEntityId = entity.id() })
			for _,v in pairs(matches) do
				if not deleteData[v] then
					deleteData[v] = world.sendEntityMessage(v, "moth_getFullSeed", entity.id())
				end
			end
			for k,v in pairs(deleteData) do
				if v:finished() then
					if v:succeeded() then
						if v:result() == breakingup.npcKey then
							successData = k
							succeededSearch = true
						end
					else
						deleteData[k] = nil
					end
				end
			end
		end
	elseif succeededSearch then
		sb.logInfo("search ok")
		if not isTargetDead() then
			--sb.logInfo("Succeeded data fetch! Trying to warp...")
			if not deletePromise then deletePromise = world.sendEntityMessage(successData, "moth_trydelete", entity.id()) end
			if deletePromise:finished() then
				if deletePromise:succeeded() and deletePromise:result() then
					succeed()
				else
					deletePromise = nil
				end
			end
		else
			succeed()
		end
	elseif failed then
		fail()
	else
		failed = true
	end
end

function uninit()
	if effect.duration() < 1 then
		status.setStatusProperty("moth_breakingup", nil)
	end
end

function succeed()
	if isTargetDead() then
		deaths[breakingup.npcKey] = nil
		world.setProperty("moth_npcdeaths", deaths)
	else
		world.sendEntityMessage(successData, "moth_delete", entity.id())
	end
	status.setStatusProperty("moth_breakingup", nil)
	world.sendEntityMessage(entity.id(), "moth_deleteRelationship", breakingup.npcKey)
	math.warp(breakingup.newLocation, "beam")
	effect.expire()
end

function fail()
	--sb.logInfo("Failed!")
	status.setStatusProperty("moth_breakingup", nil)
	if breakingup then 
		if breakingup.newLocation then 
			if math.warp then 
				math.warp(breakingup.newLocation, "beam") 
			end 
		end 
	end
	effect.expire()
end

function isTargetDead()
	local dead = false
	deaths = world.getProperty("moth_npcdeaths", {})
	for deathKey, deathValue in pairs(deaths) do
		if deathKey == breakingup.npcKey then
			dead = true
		end
	end
	return dead
end

function partialJarrayfication(t)
	local allNumbers = true
	local j = nil
	for k,v in pairs(t) do
		if type(v) == "table" then
			partialJarrayfication(v)
		end
		if type(tonumber(k)) ~= "number" then
			allNumbers = false
		end
	end
	if allNumbers then
		--sb.logInfo("Numbered keys")
		j = jarray()
		for k,v in pairs(t) do
			j[tonumber(k)] = v
		end
	else
		--sb.logInfo("String keys")
	end
	return j or t
end