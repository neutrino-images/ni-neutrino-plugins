
function loadConfig()
	config:loadConfig(confFile)

	conf.enableLivestreams		= config:getString("enableLivestreams",		"on")
	conf.streamQuality		= config:getString("streamQuality",		"max")
	conf.playerSelectChannel	= config:getString("playerSelectChannel",	"ARD")
	conf.playerSeeFuturePrograms	= config:getString("playerSeeFuturePrograms",	"off")
	conf.playerSeePeriod		= config:getString("playerSeePeriod",		"7")
	conf.playerSeeMinimumDuration	= config:getInt32("playerSeeMinimumDuration",	0)
	conf.guiUseSystemIcons		= config:getString("guiUseSystemIcons",		"off")
	conf.guiMainMenuSize		= config:getInt32("guiMainMenuSize",		30)

	conf.networkIPV4Only		= config:getString("networkIPV4Only",		"off")
	conf.networkDlSilent		= config:getString("networkDlSilent",		"off")
	conf.networkDlVerbose		= config:getString("networkDlVerbose",		"off")

	if (conf.networkIPV4Only == "on") then
		url_base = url_base_4
	else
		url_base = url_base_b
	end
end

function _saveConfig(skipMsg)
	local screen = 0;
	if (skipMsg == false) then
		screen = saveFullScreen()
		local box = paintMiniInfoBox(l.save_settings);
	end

	saveLivestreamConfig()
	config:setString("enableLivestreams",		conf.enableLivestreams)
	config:setString("streamQuality",		conf.streamQuality)
	config:setString("playerSelectChannel",		conf.playerSelectChannel)
	config:setString("playerSeeFuturePrograms",	conf.playerSeeFuturePrograms)
	config:setString("playerSeePeriod",		conf.playerSeePeriod)
	config:setInt32("playerSeeMinimumDuration",	conf.playerSeeMinimumDuration)
	config:setString("guiUseSystemIcons",		conf.guiUseSystemIcons)
	config:setInt32("guiMainMenuSize",		conf.guiMainMenuSize)

	config:setString("networkIPV4Only",		conf.networkIPV4Only)
	config:setString("networkDlSilent",		conf.networkDlSilent)
	config:setString("networkDlVerbose",		conf.networkDlVerbose)

	config:saveConfig(confFile)
	if (skipMsg == false) then
		P.sleep(1)
		G.hideInfoBox(box)
		restoreFullScreen(screen, true)
	end
end

function getLivestreamConfig()
	if (#videoTable == 0) then
		getLivestreams()
	end
	local i
	for i = 1, #videoTable do
		conf.livestream[i] = config:getString(videoTable[i][4], "on")
	end
end

function saveLivestreamConfig()
	if (#conf.livestream == 0) then return end
	local i
	for i = 1, #videoTable do
		config:setString(videoTable[i][4], conf.livestream[i])
	end
end

function exitConfigMenu(id)
	_saveConfig(true)
	if (id == "home") then
		menuRet = MENU_RETURN.EXIT
	else
		menuRet = MENU_RETURN.EXIT_ALL
	end
	return menuRet
end

function translateOnOff(s)
	local ret = "off"
	if (s == l.on) then ret = "on" end
	return ret
end

function unTranslateOnOff(s)
	local ret = l.off
	if (s == "on") then ret = l.on end
	return ret
end

function setConfigStringLs(k, v)
	_k = tonumber(k)
	conf.livestream[_k] = translateOnOff(v)
end

function setConfigString(k, v)
	conf[k] = translateOnOff(v)
end

function setConfigStringNT(k, v)
	conf[k] = v
end

function setConfigInt(k, v)
	conf[k] = v
end

function set1(k, v)
	local a
	if (translateOnOff(v) == "on") then a = true else a = false end
	m_conf:setActive{item=m_conf_item1, activ=a}
	setConfigString(k, v)
end

function enableLivestreams()
	local screen = saveFullScreen()
	getLivestreamConfig()

	local m_ls=menu.new{name="Livestreams anzeigen", icon="settings"}
	m_ls:addKey{directkey=RC["home"], id="home", action="exitConfigMenu"}
	m_ls:addKey{directkey=RC["setup"], id="setup", action="exitConfigMenu"}
	addKillKey(m_ls)
	m_ls:addItem{type="back"}
	m_ls:addItem{type="separatorline"}

	opt={ l.on, l.off }
	for i = 1, #videoTable do
		m_ls:addItem{type="chooser", action="setConfigStringLs", options={opt[1], opt[2]}, id=i, value=unTranslateOnOff(conf.livestream[i]), name=videoTable[i][1]}
	end
	m_ls:exec()
	restoreFullScreen(screen, true)
	if menuRet == MENU_RETURN.EXIT_ALL then
		return menuRet
	end
	return MENU_RETURN.REPAINT;
end

function set2(k, v)
	local a
	if (translateOnOff(v) == "off") then a = true else a = false end
	m_nw_conf:setActive{item=m_configSilent, activ=a}
	setConfigString(k, v)
end

function networkSetup()
	local screen = saveFullScreen()

	m_nw_conf=menu.new{name="Netzerk", icon="settings"}
	m_nw_conf:addKey{directkey=RC["home"], id="home", action="exitConfigMenu"}
	m_nw_conf:addKey{directkey=RC["setup"], id="setup", action="exitConfigMenu"}
	addKillKey(m_nw_conf)
	m_nw_conf:addItem{type="back"}
	m_nw_conf:addItem{type="separatorline"}

	opt={ l.on, l.off }
	m_nw_conf:addItem{type="chooser", action="setConfigString", options={opt[1], opt[2]}, id="networkIPV4Only", value=unTranslateOnOff(conf.networkIPV4Only), name="Verwende nur IPV4 für Verbindungen"}

	m_nw_conf:addItem{type="separatorline", name="Debug Informationen"}
	m_nw_conf:addItem{type="chooser", action="set2", options={opt[1], opt[2]}, id="networkDlVerbose", value=unTranslateOnOff(conf.networkDlVerbose), name="Ausführlich"}

	if (conf.networkDlVerbose == "off") then
		enabled=true
	else
		enabled=false
		conf.networkDlSilent = "on"
	end
	m_configSilent = m_nw_conf:addItem{type="chooser", enabled=enabled, action="setConfigString", options={opt[1], opt[2]}, id="networkDlSilent", value=unTranslateOnOff(conf.networkDlSilent), name="Download Fortschritt"}

	m_nw_conf:exec()
	restoreFullScreen(screen, true)
	if menuRet == MENU_RETURN.EXIT_ALL then
		return menuRet
	end
	return MENU_RETURN.REPAINT;
end

function configMenu()
	local old_guiUseSystemIcons	= conf.guiUseSystemIcons
	local old_enableLivestreams	= conf.enableLivestreams
	local old_networkIPV4Only	= conf.networkIPV4Only
	local old_guiMainMenuSize	= conf.guiMainMenuSize

	m_conf=menu.new{name="Einstellungen", icon="settings"}
	m_conf:addKey{directkey=RC["home"], id="home", action="exitConfigMenu"}
	m_conf:addKey{directkey=RC["setup"], id="setup", action="exitConfigMenu"}
	addKillKey(m_conf)
	m_conf:addItem{type="back"}

	m_conf:addItem{type="separatorline", name="OSD"}
	local opt={ l.on, l.off }
	m_conf:addItem{type="chooser", action="setConfigString", options={opt[1], opt[2]}, id="guiUseSystemIcons", value=unTranslateOnOff(conf.guiUseSystemIcons), name="Verwende Neutrino System Icons"}
	m_conf:addItem{type="numeric", action="setConfigInt", range="24,55", id="guiMainMenuSize", value=conf.guiMainMenuSize, name="Größe Hauptmenü"}

	m_conf:addItem{type="separatorline", name="Player"}
	opt={ l.on, l.off }
	m_conf:addItem{type="chooser", action="set1", options={opt[1], opt[2]}, id="enableLivestreams", value=unTranslateOnOff(conf.enableLivestreams), name="Livestreams anzeigen"}
	if (conf.enableLivestreams == "on") then enabled=true else enabled=false end
	m_conf_item1 = m_conf:addItem{type="forwarder", enabled=enabled, name="Livestreams", action="enableLivestreams", icon=1, directkey=RC["1"]}
	opt={ "max", "normal" ,"min" }
	m_conf:addItem{type="chooser", action="setConfigStringNT", options={opt[1], opt[2], opt[3]}, id="streamQuality", value=conf.streamQuality, name="Streamqualität"}

	m_conf:addItem{type="separatorline"}
	m_conf:addItem{type="forwarder", name="Netzwerk", action="networkSetup", icon=2, directkey=RC["2"]}

	m_conf:exec()
	_saveConfig(true)

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
		createImages();
	end

	if (old_networkIPV4Only ~= conf.networkIPV4Only) then
		if (conf.networkIPV4Only == "on") then
			url_base = url_base_4
		else
			url_base = url_base_b
		end
	end
end
