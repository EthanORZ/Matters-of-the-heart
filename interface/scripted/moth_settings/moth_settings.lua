require "/scripts/mothutil.lua"

function init()
	mothConfig = getConfig()
	settings = player.getProperty("moth_settings", {})
	showPage(1)
	buildSettings()
	widget.setText("version", getTranslatedMiscellaneous(mothConfig.language, "version") .. " - " .. mothConfig.version)
end

function buildSettings()
	for _,arr in pairs(config.getParameter("pages")) do
		for k,v in pairs(arr) do
			local data = widget.getData(v)
			if data then
				if keyExists(data, mothConfig.clientConfigs) then
					local setting = mothConfig.clientConfigs[data]
					if setting.type == "slider" then
						local percent = math.ceil(((setting.value-setting.minimum)/(setting.maximum-setting.minimum))*255)
						widget.setSliderValue(v, percent)
					elseif setting.type == "check" then
						widget.setChecked(v, setting.value)
					end
				end
			end
		end
	end
end

function uninit()
	player.setProperty("moth_settings", settings)
end

function radiogroup_selected()
	local pageNumber = widget.getSelectedOption("pagesGroup")
	showPage(pageNumber)
end

function button_reset()
	settings = {}
	player.setProperty("moth_settings", settings)
	mothConfig = getConfig()
	buildSettings()
end

function button_save()
	pane.dismiss()
end

function slider_button(widgetName, widgetData)
	local v = widget.getSliderValue(widgetName)
	local w = string.sub(widgetName,1,-7) .. "value"
	v = v / 255
	v = mothConfig.clientConfigs[widgetData].minimum + ((mothConfig.clientConfigs[widgetData].maximum - mothConfig.clientConfigs[widgetData].minimum) * v)
	local mod = v - (math.floor(v/mothConfig.clientConfigs[widgetData].delta)*mothConfig.clientConfigs[widgetData].delta)
	if mod > 0.001 then	v = v - mod end
	if v < mothConfig.clientConfigs[widgetData].minimum then v = mothConfig.clientConfigs[widgetData].minimum end
	if v > mothConfig.clientConfigs[widgetData].maximum then v = mothConfig.clientConfigs[widgetData].maximum end
	settings[widgetData] = v
	widget.setText(w, v)
end

function check_button(widgetName, widgetData)
	if widgetData=="debug" and not player.isAdmin() then
		widget.setChecked(widgetName, false)
	end
	settings[widgetData] = widget.getChecked(widgetName)
end

function hideAll()
	for _,arr in pairs(config.getParameter("pages")) do
		for k,v in pairs(arr) do
			widget.setVisible(v, false)
		end
	end
end

function showPage(page)
	hideAll()
	for k,v in pairs(config.getParameter("pages")[page]) do
		widget.setVisible(v, true)
	end
end