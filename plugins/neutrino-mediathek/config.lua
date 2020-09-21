function _loadConfig()
	config:loadConfig(confFile)

	conf.enableLivestreams	= config:getString('enableLivestreams',	'on')		-- no NLS
	conf.streamQuality	= config:getString('streamQuality',	'max')		-- no NLS
	conf.downloadPath	= config:getString('downloadPath',	'/')		-- no NLS
	conf.downloadQuality	= config:getString('downloadQuality',	'max')		-- no NLS
	conf.allTitles		= config:getString('allTitles',		'on')		-- no NLS
	conf.title		= config:getString('title',		'')		-- no NLS
	conf.partialTitle	= config:getString('partialTitle',	'off')		-- no NLS
	conf.inDescriptionToo	= config:getString('inDescriptionToo',	'off')		-- no NLS
	conf.ignoreCase		= config:getString('ignoreCase',	'on')		-- no NLS
	conf.channel		= config:getString('channel',		'ARD')		-- no NLS
	conf.allThemes		= config:getString('allThemes',		'on')		-- no NLS
	conf.theme		= config:getString('theme',		'')		-- no NLS
	conf.seeFuturePrograms	= config:getString('seeFuturePrograms',	'off')		-- no NLS
	conf.seePeriod		= config:getString('seePeriod',		'7')		-- no NLS
	conf.seeMinimumDuration	= config:getInt32('seeMinimumDuration',	0)		-- no NLS
	conf.guiUseSystemIcons	= config:getString('guiUseSystemIcons',	'off')		-- no NLS
	conf.guiMainMenuSize	= config:getInt32('guiMainMenuSize',	30)		-- no NLS
	conf.guiTimeMsg		= config:getInt32('guiTimeMsg',		10)		-- no NLS

	conf.networkIPV4Only	= config:getString('networkIPV4Only',	'off')		-- no NLS
	conf.networkDlSilent	= config:getString('networkDlSilent',	'off')		-- no NLS
	conf.networkDlVerbose	= config:getString('networkDlVerbose',	'off')		-- no NLS

	if (conf.networkIPV4Only == 'on') then	-- no NLS
		url_base = url_base_4
	else
		url_base = url_base_b
	end
end -- function _loadConfig

function _saveConfig()
	local screen = 0

	saveLivestreamConfig()
	config:setString('enableLivestreams',	conf.enableLivestreams)	-- no NLS
	config:setString('streamQuality',	conf.streamQuality)	-- no NLS
	config:setString('downloadPath',	conf.downloadPath)	-- no NLS
	config:setString('downloadQuality',	conf.downloadQuality)	-- no NLS
	config:setString('allTitles',		conf.allTitles)		-- no NLS
	config:setString('title',		conf.title)		-- no NLS
	config:setString('partialTitle',	conf.partialTitle)	-- no NLS
	config:setString('inDescriptionToo',	conf.inDescriptionToo)	-- no NLS
	config:setString('ignoreCase',		conf.ignoreCase)	-- no NLS
	config:setString('channel',			conf.channel)	-- no NLS
	config:setString('allThemes',		conf.allThemes)		-- no NLS
	config:setString('theme',		conf.theme)		-- no NLS
	config:setString('seeFuturePrograms',	conf.seeFuturePrograms)	-- no NLS
	config:setString('seePeriod',		conf.seePeriod)		-- no NLS
	config:setInt32('seeMinimumDuration',	conf.seeMinimumDuration)-- no NLS
	config:setString('guiUseSystemIcons',	conf.guiUseSystemIcons)	-- no NLS
	config:setInt32('guiMainMenuSize',	conf.guiMainMenuSize)	-- no NLS
	config:setInt32('guiTimeMsg',		conf.guiTimeMsg)	-- no NLS

	config:setString('networkIPV4Only',	conf.networkIPV4Only)	-- no NLS
	config:setString('networkDlSilent',	conf.networkDlSilent)	-- no NLS
	config:setString('networkDlVerbose',	conf.networkDlVerbose)	-- no NLS

	config:saveConfig(confFile)
end -- function _saveConfig

function getLivestreamConfig()
	if (#videoTable == 0) then
		getLivestreams()
	end
	for i=1, #videoTable do
		conf.livestream[i] = config:getString(videoTable[i][4], 'on')	-- no NLS
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
	if (id == 'home') then	-- no NLS
		menuRet = MENU_RETURN.EXIT
	else
		menuRet = MENU_RETURN.EXIT_ALL
	end
	return menuRet
end -- function exitConfigMenu

function translateOnOff(s)
	local ret = 'off'	-- no NLS
	if (s == l.on) then ret = 'on' end	-- no NLS
	return ret
end -- function translateOnOff

function unTranslateOnOff(s)
	local ret = l.off
	if (s == 'on') then ret = l.on end	-- no NLS
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
	if (translateOnOff(v) == 'on') then a = true else a = false end	-- no NLS
	m_conf:setActive{item=m_conf_item1, activ=a}
	setConfigOnOff(k, v)
end -- function changeEnableLifestreams

function enableLivestreams()
	local screen = saveFullScreen()
	getLivestreamConfig()
	local m_ls = menu.new{name=l.lifeHeader, icon=pluginIcon}
	m_ls:addItem{type="subhead", name=l.lifeSubheader}	-- no NLS
	m_ls:addItem{type="separator"}	-- no NLS
	m_ls:addItem{type="back", hint_icon="hint_back", hint=l.backH}	-- no NLS
	m_ls:addItem{type="separatorline"}	-- no NLS
	m_ls:addKey{directkey=RC["home"], id="home", action="exitConfigMenu"}	-- no NLS
	m_ls:addKey{directkey=RC["setup"], id="setup", action="exitConfigMenu"}	-- no NLS
	addKillKey(m_ls)

	local opt={l.on, l.off}
	for i=1, #videoTable do
		m_ls:addItem{type="chooser", action="setConfigStringLs", hint_icon="hint_service", hint=l.lifeEntryH, options=opt, id=i, value=unTranslateOnOff(conf.livestream[i]), name=videoTable[i][1]}	-- no NLS
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
	if (translateOnOff(v) == 'off') then a = true else a = false end	-- no NLS
	m_nw_conf:setActive{item=m_configSilent, activ=a}
	setConfigOnOff(k, v)
end -- function changeNetworkDLVerbose

function networkSetup()
	local screen = saveFullScreen()
	m_nw_conf = menu.new{name=l.networkHeader, icon=pluginIcon}
	m_nw_conf:addItem{type="subhead", name=l.networkSubheader}	-- no NLS
	m_nw_conf:addItem{type="separator"}	-- no NLS
	m_nw_conf:addItem{type="back", hint_icon="hint_back", hint=l.backH}	-- no NLS
	m_nw_conf:addItem{type="separatorline"}	-- no NLS
	m_nw_conf:addKey{directkey=RC["home"], id="home", action="exitConfigMenu"}	-- no NLS
	m_nw_conf:addKey{directkey=RC["setup"], id="setup", action="exitConfigMenu"}	-- no NLS
	addKillKey(m_nw_conf)

	local opt={l.on, l.off}
	m_nw_conf:addItem{type="chooser", action="setConfigOnOff", hint_icon="hint_service", hint=l.networkUsePIV4H, options=opt, id="networkIPV4Only", value=unTranslateOnOff(conf.networkIPV4Only), name=l.networkUsePIV4}	-- no NLS

	m_nw_conf:addItem{type="separatorline", name=l.networkDebug}	-- no NLS
	m_nw_conf:addItem{type="chooser", action="changeNetworkDLVerbose", hint_icon="hint_service", hint=l.networkFullH, options=opt, id="networkDlVerbose", value=unTranslateOnOff(conf.networkDlVerbose), name=l.networkFull}	-- no NLS

	if (conf.networkDlVerbose == 'off') then	-- no NLS
		enabled = true
	else
		enabled = false
		conf.networkDlSilent = 'on'	-- no NLS
	end
	local opt={l.on, l.off}
	m_configSilent = m_nw_conf:addItem{type="chooser", enabled=enabled, action="setConfigOnOff", hint_icon="hint_service", hint=l.networkProgressH, options=opt, id="networkDlSilent", value=unTranslateOnOff(conf.networkDlSilent), name=l.networkProgress}	-- no NLS

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
	m_conf:addItem{type="subhead", name=l.settingsSubheader}	-- no NLS
	m_conf:addItem{type="separator"}	-- no NLS
	m_conf:addItem{type="back", hint_icon="hint_back", hint=l.backH}	-- no NLS
	m_conf:addItem{type="separatorline", name=l.settingsOSD}	-- no NLS
	m_conf:addKey{directkey=RC["home"], id="home", action="exitConfigMenu"}	-- no NLS
	m_conf:addKey{directkey=RC["setup"], id="setup", action="exitConfigMenu"}	-- no NLS
	addKillKey(m_conf)

	local opt={l.on, l.off}
	m_conf:addItem{type="chooser", action="setConfigOnOFF", hint_icon="hint_service", hint=l.settingsSysIconsH, options=opt, id="guiUseSystemIcons", value=unTranslateOnOff(conf.guiUseSystemIcons), name=l.settingsSysIcons}	-- no NLS
	m_conf:addItem{type="numeric", action="setConfigValue", range="24,55", hint_icon="hint_service", hint=l.settingsSizeMenuH, id="guiMainMenuSize", value=conf.guiMainMenuSize, name=l.settingsSizeMenu}	-- no NLS
	m_conf:addItem{type="numeric", action="setConfigValue", range="1,60", hint_icon="hint_service", hint=l.settingsTimeMsgH, id="guiTimeMsg", value=conf.guiTimeMsg, name=l.settingsTimeMsg}	-- no NLS

	m_conf:addItem{type="separatorline", name=l.settingsPlayer}	-- no NLS
	local opt={l.on, l.off}
	m_conf:addItem{type="chooser", action="changeEnableLifestreams", hint_icon="hint_service", hint=l.settingsShowLifeH, options=opt, id="enableLivestreams", value=unTranslateOnOff(conf.enableLivestreams), name=l.settingsShowLife}	-- no NLS
	if (conf.enableLivestreams == "on") then enabled=true else enabled=false end
	m_conf_item1 = m_conf:addItem{type="forwarder", enabled=enabled, action="enableLivestreams", hint_icon="hint_service", hint=l.settingsLifestreamsH, name=l.settingsLifestreams, icon=1, directkey=RC["1"]}	-- no NLS
	opt={ 'max', 'normal' ,'min' }	-- no NLS
	m_conf:addItem{type="chooser", action="setConfigValue", hint_icon="hint_service", hint=l.settingsStreamQualityH, options=opt, id="streamQuality", value=conf.streamQuality, name=l.settingsStreamQuality}	-- no NLS

	m_conf:addItem{type="separatorline", name=l.settingsIP}	-- no NLS
	m_conf:addItem{type="forwarder", action="networkSetup", hint_icon="hint_service", hint=l.settingsNetworkH, name=l.settingsNetwork, icon=2, directkey=RC["2"]}	-- no NLS

	m_conf:addItem{type="separatorline", name=l.settingsDownload}	-- no NLS
	m_conf:addItem{type="filebrowser", dir_mode="1", action="changeDLPath", hint_icon="hint_service", hint=l.settingsDLPathH, id="downloadPath", value=conf.downloadPath, name=l.settingsDLPath}	-- no NLS
	opt={ 'max', 'normal' ,'min' }	-- no NLS
	m_conf:addItem{type="chooser", action="setConfigValue", hint_icon="hint_service", hint=l.settingsDownloadQualityH, options=opt, id="downloadQuality", value=conf.downloadQuality, name=l.settingsDownloadQuality}	-- no NLS

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
		if (conf.networkIPV4Only == 'on') then	-- no NLS
			url_base = url_base_4
		else
			url_base = url_base_b
		end
	end
end -- function configMenu
