require "/scripts/vec2.lua"
require "/scripts/util.lua"

function update(dt)
	if mcontroller.xVelocity() < 0 then
		if world.distance(mcontroller.position(), world.entityPosition(projectile.sourceEntity()))[1] < 0 then
			world.spawnProjectile("moth_storkbag", mcontroller.position(), projectile.sourceEntity(), {0,-1}, true, {npcParameters=config.getParameter("npcParameters")})
			world.spawnProjectile("moth_storkdelivered", mcontroller.position(), projectile.sourceEntity(), {mcontroller.xVelocity(),0}, true)
			projectile.die()
		end
	else
		if world.distance(mcontroller.position(), world.entityPosition(projectile.sourceEntity()))[1] > 0 then
			world.spawnProjectile("moth_storkbag", mcontroller.position(), projectile.sourceEntity(), {0,-1}, true, {npcParameters=config.getParameter("npcParameters")})
			world.spawnProjectile("moth_storkdelivered", mcontroller.position(), projectile.sourceEntity(), {mcontroller.xVelocity(),0}, true)
			projectile.die()
		end
	end
end