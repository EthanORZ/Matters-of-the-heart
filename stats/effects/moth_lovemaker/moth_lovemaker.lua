function init()
	mothConfig = getConfig()
	animator.setParticleEmitterOffsetRegion("lovefire", mcontroller.boundBox())
	animator.setParticleEmitterActive("lovefire", true)
	effect.setParentDirectives("fade=d35eae=0.15")
	
	if status.statusProperty("moth_innerpeace", 0) < mothConfig.galGunSteps then
		status.setStatusProperty("moth_innerpeace", status.statusProperty("moth_innerpeace", 0)+1)
	else
		status.setStatusProperty("moth_innerpeace", 0)
		world.sendEntityMessage(entity.id(), "moth_pacify")
	end
end