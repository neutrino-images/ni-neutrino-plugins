
function loadConfig()
	config:loadConfig(confFile)

	conf.enableLivestreams	= config:getString("enableLivestreams", "on")
	conf.streamQuality	= config:getString("streamQuality",     "max")
end

function saveConfig()
	if confChanged == 1 then
		_saveConfig(false)
	end
	return MENU_RETURN.EXIT_REPAINT
end

function _saveConfig(skipMsg)
	if (skipMsg == false) then
		local box = paintMiniInfoBox("Settings are saved...", 320);
	end

	saveLivestreamConfig()
	config:setString("enableLivestreams",	conf.enableLivestreams)
	config:setString("streamQuality",	conf.streamQuality)

	config:saveConfig(confFile)
	confChanged = 0
	if (skipMsg == false) then
		posix.sleep(1)
		gui.hideInfoBox(box)
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

function setStringLs(k, v)
	_k = tonumber(k)
	conf.livestream[_k] = v
helpers.printf("conf.livestream[%d]: %s\n", _k, conf.livestream[_k])
	confChanged = 1
end

function setString(k, v)
	conf[k] = v
	confChanged = 1
end

function setInt(k, v)
	conf[k] = v
	confChanged = 1
end

function set1(k, v)
	local a
	if (v == "on") then a = true else a = false end
	m_conf:setActive{item=m_conf_item1, activ=a}
	setInt(k, v)
end

function enableLivestreams()
	local screen = saveFullScreen()
	getLivestreamConfig()

	local m_ls=menu.new{name="Livestreams anzeigen", icon="settings"}
	m_ls:addKey{directkey=RC["home"], id="home", action="exitConfigMenu"}
	m_ls:addKey{directkey=RC["setup"], id="setup", action="exitConfigMenu"}
	m_ls:addItem{type="back"}
	m_ls:addItem{type="separatorline"}

	opt={ "on", "off" }
	for i = 1, #videoTable do
		m_ls:addItem{type="chooser", action="setStringLs", options={opt[1], opt[2]}, id=i, value=conf.livestream[i], name=videoTable[i][1]}
	end
	m_ls:exec()
	restoreFullScreen(screen, true)
	if menuRet == MENU_RETURN.EXIT_ALL then
		return menuRet
	end
	return MENU_RETURN.REPAINT;
end

function configMenu()
	m_conf=menu.new{name="Einstellungen", icon="settings"}
	m_conf:addKey{directkey=RC["home"], id="home", action="exitConfigMenu"}
	m_conf:addKey{directkey=RC["setup"], id="setup", action="exitConfigMenu"}
	m_conf:addItem{type="back"}
	m_conf:addItem{type="separatorline"}
	m_conf:addItem{type="forwarder", name="Einstellungen jetzt speichern", action="saveConfig", icon="rot", directkey=RC["red"]}

	m_conf:addItem{type="separatorline"}
	opt={ "on", "off" }
	m_conf:addItem{type="chooser", action="set1", options={opt[1], opt[2]}, id="enableLivestreams", value=conf.enableLivestreams, name="Livestreams anzeigen"}
	if (conf.enableLivestreams == "on") then enabled=true else enabled=false end
	m_conf_item1 = m_conf:addItem{type="forwarder", enabled=enabled, name="Livestreams", action="enableLivestreams", icon=1, directkey=RC["1"]}

	m_conf:addItem{type="separatorline"}

	opt={ "max", "normal" ,"min" }
	m_conf:addItem{type="chooser", action="setString", options={opt[1], opt[2], opt[3]}, id="streamQuality", value=conf.streamQuality, name="Streamqualität"}

	m_conf:exec()
end

