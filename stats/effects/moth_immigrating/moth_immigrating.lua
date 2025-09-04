function init()
	script.setUpdateDelta(30)
	immigration = status.statusProperty("moth_immigrating", nil)
	refund = true
	failed = false
	succeededFind = false
	succeededWarp = false
	successData = {}
	searchData = {}
	searchPromise = nil
	warpPromise = nil
end

function update()
	if ((not (succeededFind)) and (not (succeededWarp)) and (not (failed))) then
		--sb.logInfo("Waiting...")
		if (not immigration) then
			failed = true
		elseif (not immigration.npcKey) or (not immigration.oldLocation) or (not immigration.checkLocation) or (not immigration.newLocation) or (not math.worldId) or (not math.warp) then
			failed = true
		elseif isTargetDead() then
			failed = true
		else
			local matches = world.npcQuery(entity.position(), 10, { withoutEntityId = entity.id() })
			for _,v in pairs(matches) do
				if not searchData[v] then
					searchData[v] = world.sendEntityMessage(v, "moth_getFullSeed")
				end
			end
			for k,v in pairs(searchData) do
				if v:finished() then
					if v:succeeded() then
						if v:result() == immigration.npcKey then
							succeededFind = true
							successData.entityId = k
							searchData = nil
						end
					else
						searchData[k] = nil
					end
				end
			end
		end
	elseif succeededWarp then
		--sb.logInfo("Succeeded data fetch! Trying to warp...")
		if not warpPromise then warpPromise = world.sendEntityMessage(successData.entityId, "moth_immigratereturn") end
		if warpPromise:finished() then
			if warpPromise:succeeded() then
				succeed()
			else
				warpPromise = nil
			end
		end
	elseif succeededFind then
		--sb.logInfo("Succeeded find! Trying to fetch data...")
		if not searchPromise then searchPromise = world.sendEntityMessage(successData.entityId, "moth_immigrate") end
		if searchPromise:finished() then
			if searchPromise:succeeded() then
				if searchPromise:result() then
					for k,v in pairs(searchPromise:result()) do
						successData[k] = v
					end
					succeededWarp = true
				end
			else
				searchPromise = nil
			end
		end
	elseif failed then
		fail()
	else
		failed = true
	end
end

function uninit()
	if effect.duration() < 1 then
		status.setStatusProperty("moth_immigrating", nil)
		if refund then 
			world.spawnItem("moth_proofofcitizenship", entity.position(), 1)
		end
	end
end

function succeed()
	--sb.logInfo("Succeeded!")
	refund = false
	
	local params = {}
	params.scriptConfig = {}
	params.identity = {}
	for k,v in pairs(successData.identity) do
		params.identity[k] = v
	end
	params.scriptConfig.initialStorage = successData.storedData
	local params = partialJarrayfication(params)
	
	local finalData = {
		checkLocation = immigration.checkLocation,
		species = successData.species, 
		type = successData.type, 
		seed = successData.seed,
		parameters = params
	}
	
	status.setStatusProperty("moth_immigratingreturn", finalData)
	status.setStatusProperty("moth_immigrating", nil)
	world.sendEntityMessage(entity.id(), "moth_updateLocation", immigration.npcKey, immigration.newLocation)
	-- local immigrations = world.getProperty("moth_immigrations", {})
	-- if not string.find(immigration.newLocation, "Ship") then
		-- immigrations[immigration.npcKey] = immigration.newLocation
	-- else
		-- immigrations[immigration.npcKey] = "ship"
	-- end
	world.setProperty("moth_immigrations", immigrations)
	math.warp(immigration.newLocation, "beam")
	status.addEphemeralEffect("moth_immigratingreturn", 60)
	effect.expire()
end

function fail()
	--sb.logInfo("Failed!")
	status.setStatusProperty("moth_immigrating", nil)
	if immigration then 
		if immigration.newLocation then 
			if math.warp then 
				math.warp(immigration.newLocation, "beam") 
			end 
		end 
	end
	effect.expire()
end

function isTargetDead()
	local dead = false
	local deaths = world.getProperty("moth_npcdeaths", {})
	for deathKey, deathValue in pairs(deaths) do
		if deathKey == immigration.npcKey then
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