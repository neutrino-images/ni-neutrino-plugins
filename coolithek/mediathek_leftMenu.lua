
function changeChannel(channel)
	old_selectChannel = conf.playerSelectChannel
	conf.playerSelectChannel = channel
	return MENU_RETURN.EXIT_ALL;
end

function channelMenu()
	local screen = saveFullScreen()
	local mi = menu.new{name="Senderwahl", icon=pluginIcon};
	mi:addItem{type="subhead", name=langStr_channelSelection};
	mi:addItem{type="separator"};
	mi:addItem{type="back"};
	mi:addItem{type="separatorline"};
--	mi:addKey{directkey=RC["home"], id="home", action="key_home"}
--	mi:addKey{directkey=RC["setup"], id="setup", action="key_setup"}

	local query_url = url_base .. "/?" .. actionCmd_listChannels
	local dataFile = createCacheFileName(query_url, "json")
	local s = getJsonData(query_url, dataFile);
	local j_table = {}
	j_table = decodeJson(s)
	if (j_table == nil) then
		os.execute("rm -f " .. dataFile)
		return false
	end
	if checkJsonError(j_table) == false then
		os.execute("rm -f " .. dataFile)
		return false
	end
	for i=1, #j_table.entry do
		mi:addItem{type="forwarder", action="changeChannel", id=j_table.entry[i].channel, name=j_table.entry[i].channel};
	end

	mi:exec()
	restoreFullScreen(screen, true)
	if (conf.playerSelectChannel ~= old_selectChannel) then
		mtRightMenu_select	= 1
		mtRightMenu_view_page	= 1
		mtRightMenu_list_start	= 0
		paintMtRightMenu()

		leftMenuEntry[2][2] = conf.playerSelectChannel
		paintMtLeftMenu(leftMenuEntry)
		paintMtRightMenu()
	end
end
