require "/scripts/mothutil.lua"

function activate(fireMode, shiftHeld)
	local cfg = {}
	local mothConfig = getConfig()
	if fireMode == "primary" then
		if shiftHeld then
			cfg = root.assetJson("/interface/scripted/moth_venusiandeals/moth_venusiandeals.config")
			cfg.gui.windowtitle.title = string.format(getTranslatedMiscellaneous(mothConfig.language, "shopTitle"), "Kyu")
			cfg.gui.windowtitle.subtitle = " ^#b9b5b2;" .. getTranslatedMiscellaneous(mothConfig.language, "shopSubtitle")
			cfg.gui.btnBuy.caption = getTranslatedMiscellaneous(mothConfig.language, "order")
			cfg.gui.btnBuy.callback = "preOrder"
			cfg.gui.btnBuy.data = "preOrder"
		else
			cfg = root.assetJson("/interface/scripted/moth_huniebee/moth_huniebee.config")
			cfg.gui.windowtitle.title = getTranslatedMiscellaneous(mothConfig.language, "huniebeeTitle")
			cfg.gui.windowtitle.subtitle = " ^#b9b5b2;" .. getTranslatedMiscellaneous(mothConfig.language, "huniebeeSubtitle")
		
			cfg.gui.profileLayout.children.relationship.value = "^#b9b5b2;" .. getTranslatedMiscellaneous(mothConfig.language, "selectContact")
			cfg.gui.label_contacts.value = "^#b9b5b2;" .. getTranslatedMiscellaneous(mothConfig.language, "contacts")
			cfg.gui.label_profile.value = "^#b9b5b2;" .. getTranslatedMiscellaneous(mothConfig.language, "profile")
			cfg.gui.label_teleportable.value = getTranslatedMiscellaneous(mothConfig.language, "canQuickTravel")
			cfg.gui.button_quickTravel.caption = getTranslatedMiscellaneous(mothConfig.language, "quickTravel")
			cfg.gui.button_removeContact.caption = getTranslatedMiscellaneous(mothConfig.language, "deleteContact")
			cfg.gui.button_immigrate.caption = getTranslatedMiscellaneous(mothConfig.language, "immigrate")
			cfg.gui.textBox_filter.hint = getTranslatedMiscellaneous(mothConfig.language, "search")
		end
		activeItem.interact("ScriptPane", cfg, entity.id())
	elseif fireMode == "alt" then
		if mothConfig.clientConfigs.debug.value then
			player.setProperty("moth_relationships", {})
			status.setStatusProperty("moth_breakingup", nil)
			status.setStatusProperty("moth_immigrating", nil)
			status.setStatusProperty("moth_immigratingreturn", nil)
			status.removeEphemeralEffect("moth_deletion")
			status.removeEphemeralEffect("moth_immigrating")
			status.removeEphemeralEffect("moth_immigratingreturn")
		end
	end
end