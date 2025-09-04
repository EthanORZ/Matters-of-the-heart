require "/scripts/util.lua"
require "/scripts/rect.lua"
require "/scripts/mothutil.lua"

function init()
	mothConfig = getConfig()
	-- for k,v in pairs(world) do
		-- sb.logInfo(k)
	-- end
	message.setHandler("moth_romance", function(_, _, sourceId, npcData)
		if canRomance() then
			local cfg = root.assetJson("/interface/scripted/moth_romance/moth_romance.config")
			
			cfg.gui["npcData"] = {
				type = "label",
				value = "",
				data = npcData
			}
			cfg.gui["npcId"] = {
				type = "label",
				value = "",
				data = sourceId
			}
			
			local bgDirectives = mothConfig.personalityConfig
			if bgDirectives[npcData.personality] then
				bgDirectives = bgDirectives[npcData.personality].color
			else
				bgDirectives = bgDirectives["normal"].color
			end
			bgDirectives = "?replace;1C4F6F=" .. darken(bgDirectives, 0.8) .. ";0F3145F0=" .. darken(bgDirectives, 0.4) .. "F0;0F3145F1=" .. darken(bgDirectives, 0.4) .. "F1" 
			cfg.gui.background.fileHeader = "/interface/scripted/moth_romance/header.png" .. bgDirectives
			cfg.gui.background.fileBody = "/interface/scripted/moth_romance/body.png" .. bgDirectives
			cfg.gui.background.fileFooter = "/interface/scripted/moth_romance/footer.png" .. bgDirectives
			
			cfg.gui.windowtitle.title = string.format(getTranslatedMiscellaneous(mothConfig.language, "romanceTitle"), world.entityName(sourceId))
			cfg.gui.windowtitle.subtitle = " ^#b9b5b2;" .. getTranslatedMiscellaneous(mothConfig.language, "romanceSubtitle")
			cfg.gui.buttonBox.children.babyLabel.value = "^shadow;" .. getTranslatedMiscellaneous(mothConfig.language, "babyLabel") .. "^reset;"
			
			cfg.gui.buttonBox.children.btnTalk.caption = getTranslatedMiscellaneous(mothConfig.language, "btnTalk")
			cfg.gui.buttonBox.children.btnDate.caption = getTranslatedMiscellaneous(mothConfig.language, "wip") --getTranslatedMiscellaneous(mothConfig.language, "btnDate")
			cfg.gui.buttonBox.children.btnGift.caption = getTranslatedMiscellaneous(mothConfig.language, "btnGift")
			cfg.gui.buttonBox.children.btnKiss.caption = getTranslatedMiscellaneous(mothConfig.language, "wip") --getTranslatedMiscellaneous(mothConfig.language, "btnKiss")
			cfg.gui.buttonBox.children.btnProcreate.caption = getTranslatedMiscellaneous(mothConfig.language, "btnProcreateLocked")
			cfg.gui.buttonBox.children.btnConfirm.caption = getTranslatedMiscellaneous(mothConfig.language, "btnConfirm")
			cfg.gui.buttonBox.children.btnBack.caption = getTranslatedMiscellaneous(mothConfig.language, "btnBack")
			
			player.interact("ScriptPane", cfg, player.id())
		end
	end)
	message.setHandler("moth_kyu", function(_, _, sourceId)
		local cfg = root.assetJson("/interface/scripted/moth_venusiandeals/moth_venusiandeals.config")
		local language = mothConfig.language
		
		cfg.gui["npcId"] = {
			type = "label",
			value = "",
			data = sourceId
		}
		
		cfg.gui.windowtitle.title = string.format(getTranslatedMiscellaneous(language, "shopTitle"), "Kyu")
		cfg.gui.windowtitle.subtitle = " ^#b9b5b2;" .. getTranslatedMiscellaneous(language, "shopSubtitle")
		cfg.gui.btnBuy.caption = getTranslatedMiscellaneous(language, "buy")
			
		player.interact("ScriptPane", cfg, player.id())
	end)
	message.setHandler("moth_updateLocation", function(_, _, npcKey, location)
		playerRelationships = player.getProperty("moth_relationships", {})
		playerRelationships[npcKey].location.data = location
		player.setProperty("moth_relationships", playerRelationships)
	end)
	message.setHandler("moth_deleteRelationship", function(_, _, npcKey)
		playerRelationships = player.getProperty("moth_relationships", {})
		playerRelationships[npcKey] = nil
		player.setProperty("moth_relationships", playerRelationships)
	end)
	lastSeed = rotationSeed()
	notificationData = { 
		important = true,
		unique = false,
		type = "generic",
		textSpeed = 30,
		portraitFrames = 2,
		persistTime = 3,
		messageId = sb.makeUuid(),		
		chatterSound = "/sfx/interface/aichatter1_loop.ogg",
		portraitImage = "/ai/portraits/lovenetportrait.png:talk.<frame>",
		senderName = getTranslatedMiscellaneous(mothConfig.language, "kyuAi"),
		text = getTranslatedMiscellaneous(mothConfig.language, "restockMessage")
	}
end

function darken(hex, percent)
	local r = toHex(math.ceil(tonumber(string.sub(hex, 1, 2),16) * percent))
	local g = toHex(math.ceil(tonumber(string.sub(hex, 3, 4),16) * percent))
	local b = toHex(math.ceil(tonumber(string.sub(hex, 5, 6),16) * percent))
	return r .. g .. b
end

function toHex(n)
	local s = string.format("%x", n)
	if string.len(s) < 2 then s = "0" .. s end
	return s
end

function update(dt)
	math.localAnimator = _ENV.localAnimator
	math.worldId = _ENV.player.worldId
	math.warp = _ENV.player.warp
	if lastSeed ~= rotationSeed() then
		lastSeed = rotationSeed()
		mothConfig = getConfig()
		if mothConfig.clientConfigs.notifyOnRestock then
			world.sendEntityMessage(player.id(), "queueRadioMessage", notificationData)
		end
	end
end

function canRomance()
	if player.primaryHandItem() then
		if player.primaryHandItem().name == "moth_huniebee" then
			return true
		else
			return false
		end
	else 
		return false 
	end
end