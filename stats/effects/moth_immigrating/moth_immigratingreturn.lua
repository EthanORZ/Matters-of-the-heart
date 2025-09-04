function init()
	script.setUpdateDelta(30)
	immigration = status.statusProperty("moth_immigratingreturn", nil)
end

function update()
	if (math.worldId() == immigration.checkLocation) then		
		world.spawnNpc(entity.position(), immigration.species, immigration.type, world.threatLevel(), immigration.seed, immigration.parameters)
		status.setStatusProperty("moth_immigratingreturn", nil)
		effect.expire()
	end
end