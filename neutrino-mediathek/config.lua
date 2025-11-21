function _loadConfig()
	config:loadConfig(confFile)

	conf.enableLivestreams	= config:getString('enableLivestreams',	'on')
	conf.streamQuality	= config:getString('streamQuality',	'max')
	conf.downloadPath	= config:getString('downloadPath',	'/')
	conf.downloadQuality	= config:getString('downloadQuality',	'max')
	conf.allTitles		= config:getString('allTitles',		'on')
	conf.title		= config:getString('title',		'')
	conf.partialTitle	= config:getString('partialTitle',	'off')
	conf.inDescriptionToo	= config:getString('inDescriptionToo',	'off')
	conf.ignoreCase		= config:getString('ignoreCase',	'on')
	conf.channel		= config:getString('channel',		'ARD')
	conf.allThemes		= config:getString('allThemes',		'on')
	conf.theme		= config:getString('theme',		'')
	conf.seeFuturePrograms	= config:getString('seeFuturePrograms',	'off')
	conf.seePeriod		= config:getString('seePeriod',		'7')
	conf.seeMinimumDuration	= config:getInt32('seeMinimumDuration',	0)
	conf.iconSystemPath	= config:getString('iconSystemPath',	'@ICONSDIR@')
	conf.iconUserPath	= config:getString('iconUserPath',	'@ICONSDIR_VAR@')
	conf.guiUseSystemIcons	= config:getString('guiUseSystemIcons',	'on')
	conf.guiMainMenuSize	= config:getInt32('guiMainMenuSize',	30)
	conf.guiTimeMsg		= config:getInt32('guiTimeMsg',		10)
	conf.localRecordingsEnabled = config:getString('localRecordingsEnabled', 'off')
	conf.localRecordingsPath = config:getString('localRecordingsPath', '/media/hdd/movie')

	conf.networkIPV4Only	= config:getString('networkIPV4Only',	'off')
	conf.networkDlSilent	= config:getString('networkDlSilent',	'off')
	conf.networkDlVerbose	= config:getString('networkDlVerbose',	'off')
	conf.apiBaseUrl		= config:getString('apiBaseUrl',	url_new_default)
	conf.privacyAccepted	= config:getString('privacyAccepted',	'off')
	conf.sortMode		= config:getString('sortMode',		'date_desc')
	conf.geoMode		= config:getString('geoMode',		'all')
	conf.qualityFilter	= config:getString('qualityFilter',	'all')
	local function normalizeIconPath(value, fallback, placeholder)
		if value == nil or value == '' or value == placeholder then
			value = fallback
		end
		if string.sub(value, -1) ~= '/' then
			value = value .. '/'
		end
		return value
	end
	local defaultSystemIconPath = '/usr/share/tuxbox/neutrino/icons/'
	local defaultUserIconPath = '/var/tuxbox/icons/'
	conf.iconSystemPath = normalizeIconPath(conf.iconSystemPath, defaultSystemIconPath, '@ICONSDIR@')
	conf.iconUserPath = normalizeIconPath(conf.iconUserPath, defaultUserIconPath, '@ICONSDIR_VAR@')
	if conf.apiBaseUrl == nil or conf.apiBaseUrl == '' then
		conf.apiBaseUrl = url_new_default
	end
	if conf.privacyAccepted == nil or conf.privacyAccepted == '' then
		conf.privacyAccepted = 'off'
	end

	if NEUTRINO_MEDIATHEK_API_OVERRIDE ~= nil and NEUTRINO_MEDIATHEK_API_OVERRIDE ~= '' then
		if conf.apiBaseUrl ~= NEUTRINO_MEDIATHEK_API_OVERRIDE then
			H.printf("[neutrino-mediathek] apiBaseUrl override via env (config=%s, env=%s)", tostring(conf.apiBaseUrl), tostring(NEUTRINO_MEDIATHEK_API_OVERRIDE))
		end
		conf.apiBaseUrl = NEUTRINO_MEDIATHEK_API_OVERRIDE
	end

	if (conf.networkIPV4Only == 'on') then
		url_base = url_base_4
	else
		url_base = url_base_b
	end
	url_new = conf.apiBaseUrl
end

function _saveConfig()
	local screen = 0

	saveLivestreamConfig()
	config:setString('enableLivestreams',	conf.enableLivestreams)
	config:setString('streamQuality',	conf.streamQuality)
	config:setString('downloadPath',	conf.downloadPath)
	config:setString('downloadQuality',	conf.downloadQuality)
	config:setString('allTitles',		conf.allTitles)
	config:setString('title',		conf.title)
	config:setString('partialTitle',	conf.partialTitle)
	config:setString('inDescriptionToo',	conf.inDescriptionToo)
	config:setString('ignoreCase',		conf.ignoreCase)
	config:setString('channel',		conf.channel)
	config:setString('allThemes',		conf.allThemes)
	config:setString('theme',		conf.theme)
	config:setString('seeFuturePrograms',	conf.seeFuturePrograms)
	config:setString('seePeriod',		conf.seePeriod)
	config:setInt32('seeMinimumDuration',	conf.seeMinimumDuration)
	config:setString('iconSystemPath',	conf.iconSystemPath)
	config:setString('iconUserPath',	conf.iconUserPath)
	config:setString('guiUseSystemIcons',	conf.guiUseSystemIcons)
	config:setInt32('guiMainMenuSize',	conf.guiMainMenuSize)
	config:setInt32('guiTimeMsg',		conf.guiTimeMsg)

	config:setString('networkIPV4Only',	conf.networkIPV4Only)
	config:setString('networkDlSilent',	conf.networkDlSilent)
	config:setString('networkDlVerbose',	conf.networkDlVerbose)
	config:setString('apiBaseUrl',		conf.apiBaseUrl)
	config:setString('privacyAccepted',	conf.privacyAccepted)
	config:setString('sortMode',		conf.sortMode)
	config:setString('geoMode',		conf.geoMode)
	config:setString('qualityFilter',	conf.qualityFilter)
	config:setString('localRecordingsEnabled', conf.localRecordingsEnabled)
	config:setString('localRecordingsPath', conf.localRecordingsPath)

	config:saveConfig(confFile)
end

function getLivestreamConfig()
	if (#videoTable == 0) then
		getLivestreams()
	end
	for i=1, #videoTable do
		conf.livestream[i] = config:getString(videoTable[i][4], 'on')
	end
end -- functiuon getLivestreamConfig

function saveLivestreamConfig()
	if (#conf.livestream == 0) then return end
	for i=1, #videoTable do
		config:setString(videoTable[i][4], conf.livestream[i])
	end
end

function exitConfigMenu(id)
	_saveConfig()
	if (id == 'home') then
		menuRet = MENU_RETURN.EXIT
	else
		menuRet = MENU_RETURN.EXIT_ALL
	end
	return menuRet
end

function translateOnOff(s)
	local ret = 'off'
	if (s == l.on) then ret = 'on' end
	return ret
end

function unTranslateOnOff(s)
	local ret = l.off
	if (s == 'on') then ret = l.on end
	return ret
end

function setConfigStringLs(k, v)
	_k = tonumber(k)
	conf.livestream[_k] = translateOnOff(v)
end

function setConfigOnOff(k, v)
	conf[k] = translateOnOff(v)
end

function setConfigValue(k, v)
	conf[k] = v
end

function changeLocalRecordingsPath(dummy, value)
	if value ~= nil and value ~= '' then
		conf.localRecordingsPath = value
	end
	return MENU_RETURN.REPAINT
end

function changeEnableLifestreams(k, v)
	local a
	if (translateOnOff(v) == 'on') then a = true else a = false end
	m_conf:setActive{item=m_conf_item1, activ=a}
	setConfigOnOff(k, v)
end

function enableLivestreams()
	local screen = saveFullScreen()
	getLivestreamConfig()
	local m_ls = menu.new{name=l.lifeHeader, icon=pluginIcon}
	m_ls:addItem{type="subhead", name=l.lifeSubheader}
	m_ls:addItem{type="separator"}
	m_ls:addItem{type="back", hint_icon="hint_back", hint=l.backH}
	m_ls:addItem{type="separatorline"}
	m_ls:addKey{directkey=RC["home"], id="home", action="exitConfigMenu"}
	m_ls:addKey{directkey=RC["setup"], id="setup", action="exitConfigMenu"}
	addKillKey(m_ls)

	local opt={l.on, l.off}
	for i=1, #videoTable do
		m_ls:addItem{type="chooser", action="setConfigStringLs", hint_icon="hint_service", hint=l.lifeEntryH, options=opt, id=i, value=unTranslateOnOff(conf.livestream[i]), name=videoTable[i][1]}
	end
	m_ls:exec()
	restoreFullScreen(screen, true)
	if menuRet == MENU_RETURN.EXIT_ALL then
		return menuRet
	end
	return MENU_RETURN.REPAINT
end

function changeNetworkDLVerbose(k, v)
	local a
	if (translateOnOff(v) == 'off') then a = true else a = false end
	m_nw_conf:setActive{item=m_configSilent, activ=a}
	setConfigOnOff(k, v)
end

function changeApiBaseUrl(dummy, value)
	if value == nil or value == '' then
		value = url_new_default
	end
	conf.apiBaseUrl = value
	url_new = conf.apiBaseUrl
	return MENU_RETURN.REPAINT
end

function networkSetup()
	local screen = saveFullScreen()
	m_nw_conf = menu.new{name=l.networkHeader, icon=pluginIcon}
	m_nw_conf:addItem{type="subhead", name=l.networkSubheader}
	m_nw_conf:addItem{type="separator"}
	m_nw_conf:addItem{type="back", hint_icon="hint_back", hint=l.backH}
	m_nw_conf:addItem{type="separatorline"}
	m_nw_conf:addKey{directkey=RC["home"], id="home", action="exitConfigMenu"}
	m_nw_conf:addKey{directkey=RC["setup"], id="setup", action="exitConfigMenu"}
	addKillKey(m_nw_conf)

	m_nw_conf:addItem{
		type="keyboardinput",
		action="changeApiBaseUrl",
		hint_icon="hint_service",
		hint=l.networkApiBaseUrlH,
		id="apiBaseUrl",
		value=conf.apiBaseUrl,
		name=l.networkApiBaseUrl,
		size=160
	}

	addToggle(m_nw_conf, {confKey="networkIPV4Only", hint=l.networkUsePIV4H, name=l.networkUsePIV4})

	m_nw_conf:addItem{type="separatorline", name=l.networkDebug}
	addToggle(m_nw_conf, {confKey="networkDlVerbose", action="changeNetworkDLVerbose", hint=l.networkFullH, name=l.networkFull})

	if (conf.networkDlVerbose == 'off') then
		enabled = true
	else
		enabled = false
		conf.networkDlSilent = 'on'
	end
	m_configSilent = addToggle(m_nw_conf, {confKey="networkDlSilent", enabled=enabled, hint=l.networkProgressH, name=l.networkProgress})

	m_nw_conf:exec()
	restoreFullScreen(screen, true)
	if menuRet == MENU_RETURN.EXIT_ALL then
		return menuRet
	end
	return MENU_RETURN.REPAINT
end

function changeDLPath(dummy, downloadPath)
	conf.downloadPath = downloadPath
	return MENU_RETURN.REPAINT
end

function addToggle(menu, params)
	local id = params.id or params.confKey
	local value = params.value or unTranslateOnOff(conf[params.confKey])
	return menu:addItem{
		type = "chooser",
		action = params.action or "setConfigOnOff",
		hint_icon = params.hint_icon or "hint_service",
		hint = params.hint,
		options = params.options or {l.on, l.off},
		enabled = params.enabled,
		id = id,
		value = value,
		name = params.name
	}
end


function configMenu()
	local old_guiUseSystemIcons	= conf.guiUseSystemIcons
	local old_enableLivestreams	= conf.enableLivestreams
	local old_networkIPV4Only	= conf.networkIPV4Only
	local old_guiMainMenuSize	= conf.guiMainMenuSize

	m_conf = menu.new{name=l.settingsHeader, icon=pluginIcon}
	m_conf:addItem{type="subhead", name=l.settingsSubheader}
	m_conf:addItem{type="separator"}
	m_conf:addItem{type="back", hint_icon="hint_back", hint=l.backH}
	m_conf:addItem{type="separatorline", name=l.settingsOSD}
	m_conf:addKey{directkey=RC["home"], id="home", action="exitConfigMenu"}
	m_conf:addKey{directkey=RC["setup"], id="setup", action="exitConfigMenu"}
	addKillKey(m_conf)

	addToggle(m_conf, {confKey="guiUseSystemIcons", hint=l.settingsSysIconsH, name=l.settingsSysIcons})
	m_conf:addItem{type="numeric", action="setConfigValue", range="24,55", hint_icon="hint_service", hint=l.settingsSizeMenuH, id="guiMainMenuSize", value=conf.guiMainMenuSize, name=l.settingsSizeMenu}
	m_conf:addItem{type="numeric", action="setConfigValue", range="1,60", hint_icon="hint_service", hint=l.settingsTimeMsgH, id="guiTimeMsg", value=conf.guiTimeMsg, name=l.settingsTimeMsg}

	m_conf:addItem{type="separatorline", name=l.settingsPlayer}
	addToggle(m_conf, {confKey="enableLivestreams", action="changeEnableLifestreams", hint=l.settingsShowLifeH, name=l.settingsShowLife})
	if (conf.enableLivestreams == "on") then enabled=true else enabled=false end
	m_conf_item1 = m_conf:addItem{type="forwarder", enabled=enabled, action="enableLivestreams", hint_icon="hint_service", hint=l.settingsLifestreamsH, name=l.settingsLifestreams, icon=1, directkey=RC["1"]}
	opt={ 'max', 'normal' ,'min' }
	m_conf:addItem{type="chooser", action="setConfigValue", hint_icon="hint_service", hint=l.settingsStreamQualityH, options=opt, id="streamQuality", value=conf.streamQuality, name=l.settingsStreamQuality}

	m_conf:addItem{type="separatorline", name=l.settingsNetworkSection}
	m_conf:addItem{type="forwarder", action="networkSetup", hint_icon="hint_service", hint=l.settingsNetworkH, name=l.settingsNetwork, icon=2, directkey=RC["2"]}

	m_conf:addItem{type="separatorline", name=l.settingsDownload}
	m_conf:addItem{type="filebrowser", dir_mode="1", action="changeDLPath", hint_icon="hint_service", hint=l.settingsDLPathH, id="downloadPath", value=conf.downloadPath, name=l.settingsDLPath}
	opt={ 'max', 'normal' ,'min' }
	m_conf:addItem{type="chooser", action="setConfigValue", hint_icon="hint_service", hint=l.settingsDownloadQualityH, options=opt, id="downloadQuality", value=conf.downloadQuality, name=l.settingsDownloadQuality}

	m_conf:addItem{type="separatorline", name=l.settingsLocalRecordingsHeader}
	addToggle(m_conf, {confKey="localRecordingsEnabled", hint=l.settingsLocalRecordingsH, name=l.settingsLocalRecordings})
	m_conf:addItem{type="filebrowser", dir_mode="1", action="changeLocalRecordingsPath", hint_icon="hint_service", hint=l.settingsLocalRecordingsPathH, id="localRecordingsPath", value=conf.localRecordingsPath, name=l.settingsLocalRecordingsPath}

	m_conf:exec()
	_saveConfig()

	if (old_guiMainMenuSize ~= conf.guiMainMenuSize) then
		fontMainMenu = nil
		setFonts()
	end

	if ((old_enableLivestreams ~= conf.enableLivestreams) or
	    (old_guiMainMenuSize ~= conf.guiMainMenuSize)) then
		N:deleteSavedScreen(mainScreen)
		paintMainWindow(false)
		mainScreen = saveFullScreen()
	else
		restoreFullScreen(mainScreen, false)
	end

	if (old_guiUseSystemIcons ~= conf.guiUseSystemIcons) then
		createImages()
	end

	if (old_networkIPV4Only ~= conf.networkIPV4Only) then
		if (conf.networkIPV4Only == 'on') then
			url_base = url_base_4
		else
			url_base = url_base_b
		end
	end
end
