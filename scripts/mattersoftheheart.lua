local oldInit = init
init = function()
	if oldInit then oldInit() end

	message.setHandler("moth_particle", function(_, _, value, position)
		local bad = false
		if value < 0 then 
			bad = true 
			value = -value 
		end
		local bigCount = math.floor(value)
		local smallCount = math.floor((value%1)*10)
		
		if not bad then
			for i=1,smallCount do
				localAnimator.spawnParticle("moth_heart", position) 
			end
			for i=1,bigCount do
				localAnimator.spawnParticle("moth_bigheart", position) 
			end
		else
			for i=1,smallCount do
				localAnimator.spawnParticle("moth_evilheart", position) 
			end
			for i=1,bigCount do
				localAnimator.spawnParticle("moth_bigevilheart", position) 
			end
		end
	end)
end