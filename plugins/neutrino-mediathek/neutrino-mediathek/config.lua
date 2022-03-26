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
	conf.guiUseSystemIcons	= config:getString('guiUseSystemIcons',	'off')
	conf.guiMainMenuSize	= config:getInt32('guiMainMenuSize',	30)
	conf.guiTimeMsg		= config:getInt32('guiTimeMsg',		10)

	conf.networkIPV4Only	= config:getString('networkIPV4Only',	'off')
	conf.networkDlSilent	= config:getString('networkDlSilent',	'off')
	conf.networkDlVerbose	= config:getString('networkDlVerbose',	'off')

	if (conf.networkIPV4Only == 'on') then
		url_base = url_base_4
	else
		url_base = url_base_b
	end
end -- function _loadConfig

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
	config:setString('guiUseSystemIcons',	conf.guiUseSystemIcons)
	config:setInt32('guiMainMenuSize',	conf.guiMainMenuSize)
	config:setInt32('guiTimeMsg',		conf.guiTimeMsg)

	config:setString('networkIPV4Only',	conf.networkIPV4Only)
	config:setString('networkDlSilent',	conf.networkDlSilent)
	config:setString('networkDlVerbose',	conf.networkDlVerbose)

	config:saveConfig(confFile)
end -- function _saveConfig

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
end -- function saveLivestreamConfig

function exitConfigMenu(id)
	_saveConfig()
	if (id == 'home') then
		menuRet = MENU_RETURN.EXIT
	else
		menuRet = MENU_RETURN.EXIT_ALL
	end
	return menuRet
end -- function exitConfigMenu

function translateOnOff(s)
	local ret = 'off'
	if (s == l.on) then ret = 'on' end
	return ret
end -- function translateOnOff

function unTranslateOnOff(s)
	local ret = l.off
	if (s == 'on') then ret = l.on end
	return ret
end -- function unTranslateOnOff

function setConfigStringLs(k, v)
	_k = tonumber(k)
	conf.livestream[_k] = translateOnOff(v)
end -- function setConfigStringLs

function setConfigOnOff(k, v)
	conf[k] = translateOnOff(v)
end -- function setConfigOnOff

function setConfigValue(k, v)
	conf[k] = v
end -- function setConfigValue

function changeEnableLifestreams(k, v)
	local a
	if (translateOnOff(v) == 'on') then a = true else a = false end
	m_conf:setActive{item=m_conf_item1, activ=a}
	setConfigOnOff(k, v)
end -- function changeEnableLifestreams

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
end -- function enableLivestreams

function changeNetworkDLVerbose(k, v)
	local a
	if (translateOnOff(v) == 'off') then a = true else a = false end
	m_nw_conf:setActive{item=m_configSilent, activ=a}
	setConfigOnOff(k, v)
end -- function changeNetworkDLVerbose

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

	local opt={l.on, l.off}
	m_nw_conf:addItem{type="chooser", action="setConfigOnOff", hint_icon="hint_service", hint=l.networkUsePIV4H, options=opt, id="networkIPV4Only", value=unTranslateOnOff(conf.networkIPV4Only), name=l.networkUsePIV4}

	m_nw_conf:addItem{type="separatorline", name=l.networkDebug}
	m_nw_conf:addItem{type="chooser", action="changeNetworkDLVerbose", hint_icon="hint_service", hint=l.networkFullH, options=opt, id="networkDlVerbose", value=unTranslateOnOff(conf.networkDlVerbose), name=l.networkFull}

	if (conf.networkDlVerbose == 'off') then
		enabled = true
	else
		enabled = false
		conf.networkDlSilent = 'on'
	end
	local opt={l.on, l.off}
	m_configSilent = m_nw_conf:addItem{type="chooser", enabled=enabled, action="setConfigOnOff", hint_icon="hint_service", hint=l.networkProgressH, options=opt, id="networkDlSilent", value=unTranslateOnOff(conf.networkDlSilent), name=l.networkProgress}

	m_nw_conf:exec()
	restoreFullScreen(screen, true)
	if menuRet == MENU_RETURN.EXIT_ALL then
		return menuRet
	end
	return MENU_RETURN.REPAINT
end -- function networkSetup

function changeDLPath(dummy, downloadPath)
	conf.downloadPath = downloadPath
	return MENU_RETURN.REPAINT
end -- function changeDLPath


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

	local opt={l.on, l.off}
	m_conf:addItem{type="chooser", action="setConfigOnOFF", hint_icon="hint_service", hint=l.settingsSysIconsH, options=opt, id="guiUseSystemIcons", value=unTranslateOnOff(conf.guiUseSystemIcons), name=l.settingsSysIcons}
	m_conf:addItem{type="numeric", action="setConfigValue", range="24,55", hint_icon="hint_service", hint=l.settingsSizeMenuH, id="guiMainMenuSize", value=conf.guiMainMenuSize, name=l.settingsSizeMenu}
	m_conf:addItem{type="numeric", action="setConfigValue", range="1,60", hint_icon="hint_service", hint=l.settingsTimeMsgH, id="guiTimeMsg", value=conf.guiTimeMsg, name=l.settingsTimeMsg}

	m_conf:addItem{type="separatorline", name=l.settingsPlayer}
	local opt={l.on, l.off}
	m_conf:addItem{type="chooser", action="changeEnableLifestreams", hint_icon="hint_service", hint=l.settingsShowLifeH, options=opt, id="enableLivestreams", value=unTranslateOnOff(conf.enableLivestreams), name=l.settingsShowLife}
	if (conf.enableLivestreams == "on") then enabled=true else enabled=false end
	m_conf_item1 = m_conf:addItem{type="forwarder", enabled=enabled, action="enableLivestreams", hint_icon="hint_service", hint=l.settingsLifestreamsH, name=l.settingsLifestreams, icon=1, directkey=RC["1"]}
	opt={ 'max', 'normal' ,'min' }
	m_conf:addItem{type="chooser", action="setConfigValue", hint_icon="hint_service", hint=l.settingsStreamQualityH, options=opt, id="streamQuality", value=conf.streamQuality, name=l.settingsStreamQuality}

	m_conf:addItem{type="separatorline", name=l.settingsIP}
	m_conf:addItem{type="forwarder", action="networkSetup", hint_icon="hint_service", hint=l.settingsNetworkH, name=l.settingsNetwork, icon=2, directkey=RC["2"]}

	m_conf:addItem{type="separatorline", name=l.settingsDownload}
	m_conf:addItem{type="filebrowser", dir_mode="1", action="changeDLPath", hint_icon="hint_service", hint=l.settingsDLPathH, id="downloadPath", value=conf.downloadPath, name=l.settingsDLPath}
	opt={ 'max', 'normal' ,'min' }
	m_conf:addItem{type="chooser", action="setConfigValue", hint_icon="hint_service", hint=l.settingsDownloadQualityH, options=opt, id="downloadQuality", value=conf.downloadQuality, name=l.settingsDownloadQuality}

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
end -- function configMenu
