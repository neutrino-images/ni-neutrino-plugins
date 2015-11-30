
function loadConfig()
	config:loadConfig(confFile)

	conf.enableLivestreams		= config:getString("enableLivestreams",		"on")
	conf.streamQuality		= config:getString("streamQuality",		"max")
	conf.playerSelectChannel	= config:getString("playerSelectChannel",	"ARD")
	conf.playerSeeFuturePrograms	= config:getString("playerSeeFuturePrograms",	"off")
	conf.playerSeePeriod		= config:getString("playerSeePeriod",		"7")
	conf.playerSeeMinimumDuration	= config:getInt32("playerSeeMinimumDuration",	0)
	conf.guiUseSystemIcons		= config:getString("guiUseSystemIcons",		"off")
	conf.networkUseCurl		= config:getString("networkUseCurl",		"off")
	conf.networkIPV4Only		= config:getString("networkIPV4Only",		"off")

	dl_cmd = wget_cmd
	if ((conf.networkUseCurl == "on") or (conf.networkUseCurl == "1")) then
		local c = helpers.which("curl")
		if (c ~= "") then
			dl_cmd = c .. curl_cmd
		end
	end
end

function saveConfig()
	if confChanged == 1 then
		_saveConfig(false)
	end
	return MENU_RETURN.EXIT_REPAINT
end

function _saveConfig(skipMsg)
	local screen = 0;
	if (skipMsg == false) then
		screen = saveFullScreen()
		local box = paintMiniInfoBox(saveData);
	end

	saveLivestreamConfig()
	config:setString("enableLivestreams",		conf.enableLivestreams)
	config:setString("streamQuality",		conf.streamQuality)
	config:setString("playerSelectChannel",		conf.playerSelectChannel)
	config:setString("playerSeeFuturePrograms",	conf.playerSeeFuturePrograms)
	config:setString("playerSeePeriod",		conf.playerSeePeriod)
	config:setInt32("playerSeeMinimumDuration",	conf.playerSeeMinimumDuration)
	config:setString("guiUseSystemIcons",		conf.guiUseSystemIcons)
	config:setString("networkUseCurl",		conf.networkUseCurl)
	config:setString("networkIPV4Only",		conf.networkIPV4Only)

	config:saveConfig(confFile)
	confChanged = 0
	if (skipMsg == false) then
		posix.sleep(1)
		gui.hideInfoBox(box)
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
		return MENU_RETURN.EXIT
	else
		return MENU_RETURN.EXIT_ALL
	end
end

function translateOnOff(s)
	local ret = "off"
	if (s == onStr) then ret = "on" end
	return ret
end

function unTranslateOnOff(s)
	local ret = offStr
	if (s == "on") then ret = onStr end
	return ret
end

function setConfigStringLs(k, v)
	_k = tonumber(k)
	conf.livestream[_k] = translateOnOff(v)
--helpers.printf("conf.livestream[%d]: %s\n", _k, conf.livestream[_k])
	confChanged = 1
end

function setConfigString(k, v)
	conf[k] = translateOnOff(v)
	confChanged = 1
end

function setConfigInt(k, v)
	conf[k] = v
	confChanged = 1
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
	m_ls:addItem{type="back"}
	m_ls:addItem{type="separatorline"}

	opt={ onStr, offStr }
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

function configMenu()
	old_guiUseSystemIcons = conf.guiUseSystemIcons
	old_enableLivestreams = conf.enableLivestreams
	old_networkIPV4Only   = conf.networkIPV4Only

	m_conf=menu.new{name="Einstellungen", icon="settings"}
	m_conf:addKey{directkey=RC["home"], id="home", action="exitConfigMenu"}
	m_conf:addKey{directkey=RC["setup"], id="setup", action="exitConfigMenu"}
	m_conf:addItem{type="back"}
	m_conf:addItem{type="separatorline"}
	m_conf:addItem{type="forwarder", name="Einstellungen jetzt speichern", action="saveConfig", icon="rot", directkey=RC["red"]}

	m_conf:addItem{type="separatorline", name="OSD"}
	local opt={ onStr, offStr }
	m_conf:addItem{type="chooser", action="setConfigString", options={opt[1], opt[2]}, id="guiUseSystemIcons", value=unTranslateOnOff(conf.guiUseSystemIcons), name="Verwende Neutrino System Icons"}

	m_conf:addItem{type="separatorline", name="Netzwerk"}
	opt={ onStr, offStr }
	m_conf:addItem{type="chooser", action="setConfigString", options={opt[1], opt[2]}, id="networkUseCurl", value=unTranslateOnOff(conf.networkUseCurl), name="Verwende curl, wenn vorhanden"}
	m_conf:addItem{type="chooser", action="setConfigString", options={opt[1], opt[2]}, id="networkIPV4Only", value=unTranslateOnOff(conf.networkIPV4Only), name="Verwende nur IPV4 für Verbindungen"}

	m_conf:addItem{type="separatorline", name="Player"}
	opt={ onStr, offStr }
	m_conf:addItem{type="chooser", action="set1", options={opt[1], opt[2]}, id="enableLivestreams", value=unTranslateOnOff(conf.enableLivestreams), name="Livestreams anzeigen"}
	if (conf.enableLivestreams == "on") then enabled=true else enabled=false end
	m_conf_item1 = m_conf:addItem{type="forwarder", enabled=enabled, name="Livestreams", action="enableLivestreams", icon=1, directkey=RC["1"]}
	opt={ "max", "normal" ,"min" }
	m_conf:addItem{type="chooser", action="setConfigString", options={opt[1], opt[2], opt[3]}, id="streamQuality", value=conf.streamQuality, name="Streamqualität"}

	m_conf:exec()

	if (old_enableLivestreams ~= conf.enableLivestreams) then
		n:deleteSavedScreen(mainScreen)
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
