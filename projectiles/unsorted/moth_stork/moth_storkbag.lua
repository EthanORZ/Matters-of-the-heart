require "/scripts/vec2.lua"
require "/scripts/util.lua"

function update(dt)
	if world.distance(mcontroller.position(), world.entityPosition(projectile.sourceEntity()))[2] < 0 then
		world.spawnItem({name="moth_baby", count=1, parameters={npcParameters=config.getParameter("npcParameters")}}, mcontroller.position())
		projectile.die()
	end
end