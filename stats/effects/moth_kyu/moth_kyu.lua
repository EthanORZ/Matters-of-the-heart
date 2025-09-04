function init()
	if not world.getProperty("moth_kyuSpawned", false) then
		world.setProperty("moth_kyuSpawned", true)
		world.spawnNpc(entity.position(), "human", "moth_kyu", 0)
	end
end