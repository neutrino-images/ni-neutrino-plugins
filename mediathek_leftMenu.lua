function repaintMediathek()
	selectionChanged = true
	leftMenuEntry[1][2] = formatTitle(conf.allTitles, conf.title)
	leftMenuEntry[2][2] = conf.channel
	leftMenuEntry[3][2] = formatTheme(conf.allThemes, conf.theme)
	leftMenuEntry[4][2] = formatseePeriod()
	leftMenuEntry[5][2] = formatMinDuration(conf.seeMinimumDuration)
	paintMtLeftMenu()

	mtRightMenu_select	= 1
	mtRightMenu_view_page	= 1
	mtRightMenu_list_start	= 0
	paintMtRightMenu()
end -- function repaintMediathek

function changeTitle(k, v)
	conf.title = v
	return MENU_RETURN.REPAINT
end -- function changeTitle

function changeAllTitles(k, v)
	conf.allTitles = translateOnOff(v)
	for i=1, 4 do
		m_title_sel:setActive{item=titleList[i], activ=(conf.allTitles=='off')}	-- no NLS
	end
	return MENU_RETURN.EXIT_ALL
end -- function changeAllTitles

function changePartSearch(k, v)
	conf.partialTitle = translateOnOff(v)
	if conf.partialTitle == 'off' then	-- no NLS
		conf.inDescriptionToo = 'off'	-- no NLS
	end
	return MENU_RETURN.EXIT_All
end -- function changePartSearch

function changeInDescr(k, v)
	conf.inDescriptionToo = translateOnOff(v)
	if conf.inDescriptionToo == 'on' then	-- no NLS
		conf.partialTitle = 'on'	-- no NLS
	end
	return MENU_RETURN.EXIT_AlL
end -- function changeInDescr

function changeIgnoreCase(k, v)
	conf.ignoreCase = translateOnOff(v)
	return MENU_RETURN.EXIT_ALL
end -- function changeIgnoreCase

function titleMenu()
	local old_title			= conf.title
	local old_allTitles		= conf.allTitles
	local old_partialTitle		= conf.partialTitle
	local old_inDescriptionToo	= conf.inDescriptionToo
	local old_ignoreCase		= conf.ignoreCase
	local screen = saveFullScreen()
	m_title_sel = menu.new{name=l.titleHeader, icon=pluginIcon}
	m_title_sel:addItem{type="subhead", name=l.titleSubheader}	-- no NLS
	m_title_sel:addItem{type="separator"}	-- no NLS
	m_title_sel:addItem{type="back", hint_icon="hint_back", hint=l.backH}	-- no NLS
	m_title_sel:addItem{type="separatorline"}	-- no NLS
--	m_title_sel:addKey{directkey=RC["home"], id="home", action="key_home"}
--	m_title_sel:addKey{directkey=RC["setup"], id="setup", action="key_setup"}
	addKillKey(m_title_sel)

	titleList = {}
	local opt={l.on, l.off}
	m_title_sel:addItem{type="chooser", action="changeAllTitles", hint_icon="hint_service", hint=l.titleAllTitlesH ,options=opt, id="allTitles", value=unTranslateOnOff(conf.allTitles), name=l.titleAllTitles}	-- no NLS
	local opt={l.on, l.off}
	local titleItem = m_title_sel:addItem{type="chooser", action="changePartSearch", hint_icon="hint_service", hint=l.titlePartSearchH , options=opt, id="partSearch", value=unTranslateOnOff(conf.partialTitle), name=l.titlePartSearch}	-- no NLS
	titleList[1] = titleItem
	local opt={l.on, l.off}
	local titleItem = m_title_sel:addItem{type="chooser", action="changeInDescr", hint_icon="hint_service", hint=l.titleInDescrH, options=opt, id="inDescr", value=unTranslateOnOff(conf.inDescriptionToo), name=l.titleInDescr}	-- no NLS
	titleList[2] = titleItem
	local opt={l.on, l.off}
	local titleItem = m_title_sel:addItem{type="chooser", action="changeIgnoreCase", hint_icon="hint_service", hint=l.titleIgnoreCaseH , options=opt, id="ignoreCase", value=unTranslateOnOff(conf.ignoreCase), name=l.titleIgnoreCase}	-- no NLS
	titleList[3] = titleItem
	local titleItem = m_title_sel:addItem{type="keyboardinput", action="changeTitle", hint_icon="hint_service", hint=l.titleTitleH , id="title", value=conf.title, name=l.titleTitle, size=32, icon=l.iconRed, directkey=RC['red']}	-- no NLS
	titleList[4] = titleItem
	for i=1, 4 do
		m_title_sel:setActive{item=titleList[i], activ=(conf.allTitles=='off')}	-- no NLS
	end

	m_title_sel:exec()
	restoreFullScreen(screen, true)
	if ((conf.title ~= old_title) or (conf.allTitles ~= old_allTitles) or (conf.partialTitle ~= old_partialTitle) or (conf.inDescriptionToo ~= old_inDescriptionToo) or (conf.ignoreCase ~= old_ignoreCase)) then
		repaintMediathek()
	end
end -- function titleMenu

function changeChannel(channel)
	conf.channel = channel
--	conf.title = l.allTitles
	conf.allTitles = 'on'	-- no NLS
--	conf.theme = l.allThemes
	conf.allThemes = 'on'	-- no NLS
	return MENU_RETURN.EXIT_ALL
end -- function changeChannel

function channelMenu()
	local old_channel = conf.channel
	local screen = saveFullScreen()
	local mi = menu.new{name=l.channelHeader, icon=pluginIcon}
	mi:addItem{type="subhead", name=l.channelSubheader}	-- no NLS
	mi:addItem{type="separator"}	-- no NLS
	mi:addItem{type="back", hint_icon="hint_back", hint=l.backH}	-- no NLS
	mi:addItem{type="separatorline"}	-- no NLS
--	mi:addKey{directkey=RC["home"], id="home", action="key_home"}
--	mi:addKey{directkey=RC["setup"], id="setup", action="key_setup"}
	addKillKey(mi)

	local query_url = url_new .. actionCmd_listChannels
	local dataFile = createCacheFileName(query_url, 'json')	-- no NLS
	local s = getJsonData2(query_url, dataFile, nil, queryMode_listChannels)
--	H.printf("\nretData:\n%s\n", tostring(s))

	local j_table = {}
	j_table = decodeJson(s)
	if (j_table == nil) then
		os.execute('rm -f ' .. dataFile)	-- no NLS
		return false
	end
	if checkJsonError(j_table) == false then
		os.execute('rm -f ' .. dataFile)	-- no NLS
		return false
	end
	for i=1, #j_table.entry do
		local channelCount = '(' .. tostring(j_table.entry[i].count) .. ')'	-- no NLS
		mi:addItem{type="forwarder", action="changeChannel", hint_icon="hint_service", hint=l.channelEntryH, id=j_table.entry[i].channel, value=channelCount, name=j_table.entry[i].channel}	-- no NLS
	end

	mi:exec()
	restoreFullScreen(screen, true)
	if (conf.channel ~= old_channel) then
		repaintMediathek()
	end
end -- function channelMenu

function changeTheme(theme)
	conf.theme = theme
	return MENU_RETURN.EXIT_ALL
end -- function changeTheme

function changeAllThemes(k, v)
	conf.allThemes = translateOnOff(v)
	for i=1, #themeList do
		m_theme_sel:setActive{item=themeList[i], activ=(conf.allThemes=='off')}	-- no NLS
	end
	return MENU_RETURN.EXIT_ALL
end -- function changeAllThemes

function themeMenu()
	local old_theme     = conf.theme
	local old_allThemes = conf.allThemes
	local screen = saveFullScreen()
	m_theme_sel = menu.new{name=l.themeHeader, icon=pluginIcon}
	m_theme_sel:addItem{type="subhead", name=l.themeSubheader}	-- no NLS
	m_theme_sel:addItem{type="separator"}	-- no NLS
	m_theme_sel:addItem{type="back", hint_icon="hint_back", hint=l.backH}	-- no NLS
	m_theme_sel:addItem{type="separatorline"}	-- no NLS
--	m_theme_sel:addKey{directkey=RC["home"], id="home", action="key_home"}
--	m_theme_sel:addKey{directkey=RC["setup"], id="setup", action="key_setup"}
	addKillKey(m_theme_sel)

	local el = {}
	local channel = conf.channel
	el['channel'] = channel

	local timeMode = timeMode_normal
	if (conf.seeFuturePrograms == 'on') then	-- no NLS
		timeMode = timeMode_future
	end
	el['timeMode'] = timeMode

	local period = 0
	if (conf.seePeriod == 'all') then	-- no NLS
		period = -1
	else
		period = tonumber(conf.seePeriod)
		if (period == nil) then
			period = 7
			conf.seePeriod = period
		end
	end
	el['epoch'] = period

	local minDuration = conf.seeMinimumDuration*60
	el['duration'] = minDuration

	local refTime = 0
	el['refTime'] = refTime

	local start = 0
	local limit = 1000

	local j = 1
	local themeindex = {}
	if (#mtList > 1) then
		while (#mtList > 1) do table.remove(mtList) end
	end
	local actentries = 0
	local maxentries = 999999

	while (actentries < maxentries) do
		local sendData = getSendDataHead(queryMode_listVideos)
		el['limit'] = limit
		el['start'] = start
		sendData['data'] = {}
		sendData['data'] = el
		local post = J:encode(sendData)

		local dataFile = createCacheFileName(post, 'json')	-- no NLS
		post = C:setUriData('data1', post)	-- no NLS
		local s = getJsonData2(url_new .. actionCmd_sendPostData, dataFile, post, queryMode_listVideos)
--	H.printf("\nretData:\n%s\n", tostring(s))

		local endentries = actentries + limit - 1
		if (endentries > maxentries) then
			endentries = maxentries
		end
		local totalentries = maxentries
		if (totalentries == 999999) then
			totalentries = l.searchThemeInfoAll
		end
		local box = paintAnInfoBox(string.format(l.searchThemeInfoMsg, actentries, endentries, tostring(totalentries)), WHERE.CENTER)
		local j_table = {}
		j_table = decodeJson(s)
		if (j_table == nil) then
			os.execute('rm -f ' .. dataFile)	-- no NLS
			return false
		end
		if checkJsonError(j_table) == false then
			os.execute('rm -f ' .. dataFile)	-- no NLS
			if (j_table.err ~= 2) then
				return false
			end
		end

		for i=1, #j_table.entry do
			if themeindex[j_table.entry[i].theme] == nil then
				mtList[j] = {}
				mtList[j].name = j_table.entry[i].theme
				mtList[j].count = 1
				themeindex[j_table.entry[i].theme] = j
				j = j + 1
			else
				mtList[themeindex[j_table.entry[i].theme]].count = mtList[themeindex[j_table.entry[i].theme]].count + 1
			end
		end

		start = start + limit
		actentries = actentries + limit
		maxentries = j_table.head.total
		G.hideInfoBox(box)
	end -- up to max number of entries read
	j = j - 1

	table.sort(mtList, function(a, b) return string.upper(a.name) < string.upper(b.name) end)

	local opt={l.on, l.off}
	m_theme_sel:addItem{type="chooser", action="changeAllThemes", hint_icon="hint_service", hint=l.themeAllH, options=opt, id="allThemes", value=unTranslateOnOff(conf.allThemes), name=l.themeAll}	-- no NLS

	themeList = {}
	for i=1, j do
		local themeCount = '(' .. tostring(mtList[i].count) .. ')'
		local themeItem = m_theme_sel:addItem{type="forwarder", action="changeTheme", hint_icon="hint_service", hint=l.themeEntryH, id=mtList[i].name, value=themeCount, name=mtList[i].name}	-- no NLS
		m_theme_sel:setActive{item=themeItem, activ=(conf.allThemes=='off')}	-- no NLS
		themeList[i] = themeItem
	end

	m_theme_sel:exec()
	restoreFullScreen(screen, true)
	if ((conf.theme ~= old_theme) or (conf.allThemes ~= old_allThemes)) then
		repaintMediathek()
	end
end -- function themeMenu

function periodOfTimeMenu()
	local old_seeFuturePrograms = conf.seeFuturePrograms
	local old_seePeriod = conf.seePeriod
	local screen = saveFullScreen()
	local mi = menu.new{name=l.seePeriodHeader, icon=pluginIcon}
	mi:addItem{type="subhead", name=l.seePeriodSubheader}	-- no NLS
	mi:addItem{type="separator"}	-- no NLS
	mi:addItem{type="back", hint_icon="hint_back", hint=l.backH}	-- no NLS
	mi:addItem{type="separatorline"}	-- no NLS
	addKillKey(mi)

	local opt={l.on, l.off}
	mi:addItem{type="chooser", action="setConfigOnOff", hint_icon="hint_service", hint=l.seePeriodFutureH, options=opt, id="seeFuturePrograms", value=unTranslateOnOff(conf.seeFuturePrograms), name=l.seePeriodFuture}	-- no NLS
	opt={ 'all', '1', '3', '7', '14', '28', '60'}	-- no NLS
	mi:addItem{type="chooser", action="setConfigValue", hint_icon="hint_service", hint=l.seePeriodDaysH, options=opt, id="seePeriod", value=conf.seePeriod, name=l.seePeriodDays}	-- no NLS

	mi:exec()
	restoreFullScreen(screen, true)
	if ((conf.seeFuturePrograms ~= old_seeFuturePrograms) or (conf.seePeriod ~= old_seePeriod)) then
		repaintMediathek()
	end
end -- function periodOfTimeMenu

function minDurationMenu()
	local old_seeMinimumDuration = conf.seeMinimumDuration
	local screen = saveFullScreen()
	local mi = menu.new{name=l.durationHeader, icon=pluginIcon}
	mi:addItem{type="subhead", name=l.durationSubheader}	-- no NLS
	mi:addItem{type="separator"}	-- no NLS
	mi:addItem{type="back", hint_icon="hint_back", hint=l.backH}	-- no NLS
	mi:addItem{type="separatorline"}	-- no NLS
	addKillKey(mi)

	mi:addItem{type="numeric", action="setConfigValue", range="0,120", hint_icon="hint_service", hint=l.durationMinH, id="seeMinimumDuration", value=conf.seeMinimumDuration, name=l.durationMin}	-- no NLS

	mi:exec()
	restoreFullScreen(screen, true)
	if (conf.seeMinimumDuration ~= old_seeMinimumDuration) then
		repaintMediathek()
	end
end -- function minDurationMenu
