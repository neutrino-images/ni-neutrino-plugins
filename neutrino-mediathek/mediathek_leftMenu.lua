
function set_playerSeePeriod()
	local period = ""
	local s = "-"
	if (conf.playerSeeFuturePrograms == "on") then
		s = "+/-"
	end
	if (conf.playerSeePeriod == "all") then
		period = "Alles"
	elseif (conf.playerSeePeriod == "1") then
		period = s .. " 1 Tag"
	else
		period = s .. " " .. conf.playerSeePeriod .. " Tage"
	end
	return period
end

function repaintMediathek()
	mtRightMenu_select	= 1
	mtRightMenu_view_page	= 1
	mtRightMenu_list_start	= 0
	paintMtRightMenu()

	leftMenuEntry[2][2] = conf.playerSelectChannel
	leftMenuEntry[4][2] = set_playerSeePeriod()
	leftMenuEntry[5][2] = tostring(conf.playerSeeMinimumDuration) .. " Minuten"
	paintMtLeftMenu(leftMenuEntry)
	paintMtRightMenu()
end

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
	addKillKey(mi)
--	mi:addKey{directkey=RC["home"], id="home", action="key_home"}
--	mi:addKey{directkey=RC["setup"], id="setup", action="key_setup"}

	local query_url = url_new .. actionCmd_listChannels
	local dataFile = createCacheFileName(query_url, "json")
	local s = getJsonData2(query_url, dataFile, nil, queryMode_listChannels);
--	H.printf("\nretData:\n%s\n", tostring(s))

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
		local channelCount = "(" .. tostring(j_table.entry[i].count) .. ")"
		mi:addItem{type="forwarder", action="changeChannel", id=j_table.entry[i].channel, name=j_table.entry[i].channel, value=channelCount};
	end

	mi:exec()
	restoreFullScreen(screen, true)
	if (conf.playerSelectChannel ~= old_selectChannel) then
		repaintMediathek()
	end
end

function minDurationMenu()
	old_playerSeeMinimumDuration = conf.playerSeeMinimumDuration
	local screen = saveFullScreen()
	local mi = menu.new{name="min. Sendungsdauer", icon=pluginIcon};
	mi:addItem{type="subhead", name=langStr_channelSelection};
	mi:addItem{type="separator"};
	mi:addItem{type="back"};
	mi:addItem{type="separatorline"};
	addKillKey(mi)

	mi:addItem{type="numeric", action="setConfigInt", range="0,90", id="playerSeeMinimumDuration", value=conf.playerSeeMinimumDuration, name="Zeitraum in Minuten"}

	mi:exec()
	restoreFullScreen(screen, true)
	if (old_playerSeeMinimumDuration ~= conf.playerSeeMinimumDuration) then
		repaintMediathek()
	end
end

function periodOfTime()

	local old_playerSeeFuturePrograms = conf.playerSeeFuturePrograms
	local old_playerSeePeriod = conf.playerSeePeriod

	local screen = saveFullScreen()
	local mi = menu.new{name="Zeitraum", icon=pluginIcon};
	mi:addItem{type="subhead", name=langStr_channelSelection};
	mi:addItem{type="separator"};
	mi:addItem{type="back"};
	mi:addItem{type="separatorline"};
	addKillKey(mi)

	local opt={ l.on, l.off }
	mi:addItem{type="chooser", action="setConfigString", options=opt, id="playerSeeFuturePrograms", value=unTranslateOnOff(conf.playerSeeFuturePrograms), name="Auch zukünftige Sendungen anzeigen"}

	opt={ "all", "1", "3", "7", "14", "28", "60"}
	mi:addItem{type="chooser", action="setConfigStringNT", options=opt, id="playerSeePeriod", value=conf.playerSeePeriod, name="Zeitraum in Tagen"}


--	mi:addItem{type="forwarder", action="dummy", id=1, name="Auch zukünftige Sendungen anzeigen"};

	mi:exec()
	restoreFullScreen(screen, true)

	if ((old_playerSeeFuturePrograms ~= conf.playerSeeFuturePrograms) or
	    (old_playerSeePeriod ~= conf.playerSeePeriod)) then
		repaintMediathek()
	end


end
