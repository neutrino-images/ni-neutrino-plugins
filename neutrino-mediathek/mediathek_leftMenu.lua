function repaintMediathek()
	selectionChanged = true
	leftMenuEntry[1][2] = formatTitle(conf.allTitles, conf.title)
	leftMenuEntry[2][2] = conf.channel
	leftMenuEntry[3][2] = formatTheme(conf.allThemes, conf.theme)
	leftMenuEntry[4][2] = formatseePeriod()
	leftMenuEntry[5][2] = formatMinDuration(conf.seeMinimumDuration)
	leftMenuEntry[6][2] = formatSortMode()
	leftMenuEntry[7][2] = formatGeoMode()
	leftMenuEntry[8][2] = formatQualityMode()
	paintMtLeftMenu()

	mtRightMenu_select	= 1
	mtRightMenu_view_page	= 1
	mtRightMenu_list_start	= 0
	paintMtRightMenu()
end

local function loadJsonResponse(cacheKey, url, mode, postData)
	local dataFile = createCacheFileName(cacheKey, 'json')
	local s = getJsonData2(url, dataFile, postData, mode)
	if not s then
		messagebox.exec{title=pluginName, text=l.networkError, buttons={'ok'}}
		return nil
	end
	local j_table, err = decodeJson(s)
	if not j_table then
		messagebox.exec{title=pluginName, text=l.jsonError, buttons={'ok'}}
		os.execute('rm -f ' .. dataFile)
		return nil
	end
	if checkJsonError(j_table) == false then
		os.execute('rm -f ' .. dataFile)
		if j_table.err == 2 then
			return j_table
		end
		return nil
	end
	return j_table
end

function changeTitle(k, v)
	conf.title = v
	return MENU_RETURN.REPAINT
end

function changeAllTitles(k, v)
	conf.allTitles = translateOnOff(v)
	for i=1, 4 do
		m_title_sel:setActive{item=titleList[i], activ=(conf.allTitles=='off')}
	end
	return MENU_RETURN.EXIT_ALL
end

function changePartSearch(k, v)
	conf.partialTitle = translateOnOff(v)
	if conf.partialTitle == 'off' then
		conf.inDescriptionToo = 'off'
	end
	return MENU_RETURN.EXIT_All
end

function changeInDescr(k, v)
	conf.inDescriptionToo = translateOnOff(v)
	if conf.inDescriptionToo == 'on' then
		conf.partialTitle = 'on'
	end
	return MENU_RETURN.EXIT_AlL
end

function changeIgnoreCase(k, v)
	conf.ignoreCase = translateOnOff(v)
	return MENU_RETURN.EXIT_ALL
end

function titleMenu()
	local old_title			= conf.title
	local old_allTitles		= conf.allTitles
	local old_partialTitle		= conf.partialTitle
	local old_inDescriptionToo	= conf.inDescriptionToo
	local old_ignoreCase		= conf.ignoreCase
	local screen = saveFullScreen()
	m_title_sel = menu.new{name=l.titleHeader, icon=pluginIcon}
	m_title_sel:addItem{type="subhead", name=l.titleSubheader}
	m_title_sel:addItem{type="separator"}
	m_title_sel:addItem{type="back", hint_icon="hint_back", hint=l.backH}
	m_title_sel:addItem{type="separatorline"}
--	m_title_sel:addKey{directkey=RC["home"], id="home", action="key_home"}
--	m_title_sel:addKey{directkey=RC["setup"], id="setup", action="key_setup"}
	addKillKey(m_title_sel)

	titleList = {}
	addToggle(m_title_sel, {confKey="allTitles", action="changeAllTitles", hint=l.titleAllTitlesH, name=l.titleAllTitles})
	local titleItem = addToggle(m_title_sel, {confKey="partialTitle", action="changePartSearch", hint=l.titlePartSearchH, id="partSearch", name=l.titlePartSearch})
	titleList[1] = titleItem
	local titleItem = addToggle(m_title_sel, {confKey="inDescriptionToo", action="changeInDescr", hint=l.titleInDescrH, id="inDescr", name=l.titleInDescr})
	titleList[2] = titleItem
	local titleItem = addToggle(m_title_sel, {confKey="ignoreCase", action="changeIgnoreCase", hint=l.titleIgnoreCaseH, id="ignoreCase", name=l.titleIgnoreCase})
	titleList[3] = titleItem
	local titleItem = m_title_sel:addItem{type="keyboardinput", action="changeTitle", hint_icon="hint_service", hint=l.titleTitleH , id="title", value=conf.title, name=l.titleTitle, size=32, icon=l.iconRed, directkey=RC['red']}
	titleList[4] = titleItem
	for i=1, 4 do
		m_title_sel:setActive{item=titleList[i], activ=(conf.allTitles=='off')}
	end

	m_title_sel:exec()
	restoreFullScreen(screen, true)
	if ((conf.title ~= old_title) or (conf.allTitles ~= old_allTitles) or (conf.partialTitle ~= old_partialTitle) or (conf.inDescriptionToo ~= old_inDescriptionToo) or (conf.ignoreCase ~= old_ignoreCase)) then
		repaintMediathek()
	end
end

function changeChannel(channel)
	conf.channel = channel
--	conf.title = l.allTitles
	conf.allTitles = 'on'
--	conf.theme = l.allThemes
	conf.allThemes = 'on'
	return MENU_RETURN.EXIT_ALL
end

function channelMenu()
	local old_channel = conf.channel
	local screen = saveFullScreen()
	local mi = menu.new{name=l.channelHeader, icon=pluginIcon}
	mi:addItem{type="subhead", name=l.channelSubheader}
	mi:addItem{type="separator"}
	mi:addItem{type="back", hint_icon="hint_back", hint=l.backH}
	mi:addItem{type="separatorline"}
--	mi:addKey{directkey=RC["home"], id="home", action="key_home"}
--	mi:addKey{directkey=RC["setup"], id="setup", action="key_setup"}
	addKillKey(mi)

	local query_url = url_new .. actionCmd_listChannels
	local j_table = loadJsonResponse(query_url, query_url, queryMode_listChannels, nil)
	if not j_table or not j_table.entry then
		return false
	end
	for i=1, #j_table.entry do
		local channelCount = '(' .. tostring(j_table.entry[i].count) .. ')'
		mi:addItem{type="forwarder", action="changeChannel", hint_icon="hint_service", hint=l.channelEntryH, id=j_table.entry[i].channel, value=channelCount, name=j_table.entry[i].channel}
	end

	mi:exec()
	restoreFullScreen(screen, true)
	if (conf.channel ~= old_channel) then
		repaintMediathek()
	end
end

function changeTheme(theme)
	conf.theme = theme
	return MENU_RETURN.EXIT_ALL
end

function changeAllThemes(k, v)
	conf.allThemes = translateOnOff(v)
	for i=1, #themeList do
		m_theme_sel:setActive{item=themeList[i], activ=(conf.allThemes=='off')}
	end
	return MENU_RETURN.EXIT_ALL
end

function themeMenu()
	local old_theme     = conf.theme
	local old_allThemes = conf.allThemes
	local screen = saveFullScreen()
	m_theme_sel = menu.new{name=l.themeHeader, icon=pluginIcon}
	m_theme_sel:addItem{type="subhead", name=l.themeSubheader}
	m_theme_sel:addItem{type="separator"}
	m_theme_sel:addItem{type="back", hint_icon="hint_back", hint=l.backH}
	m_theme_sel:addItem{type="separatorline"}
--	m_theme_sel:addKey{directkey=RC["home"], id="home", action="key_home"}
--	m_theme_sel:addKey{directkey=RC["setup"], id="setup", action="key_setup"}
	addKillKey(m_theme_sel)

	local el = {}
	local channel = conf.channel
	el['channel'] = channel

	local timeMode = timeMode_normal
	if (conf.seeFuturePrograms == 'on') then
		timeMode = timeMode_future
	end
	el['timeMode'] = timeMode

	local period = 0
	if (conf.seePeriod == 'all') then
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

		post = C:setUriData('data1', post)
		local j_table = loadJsonResponse(post, url_new .. actionCmd_sendPostData, queryMode_listVideos, post)

		local endentries = actentries + limit - 1
		if (endentries > maxentries) then
			endentries = maxentries
		end
		local totalentries = maxentries
		if (totalentries == 999999) then
			totalentries = l.searchThemeInfoAll
		end
		local box = paintAnInfoBox(string.format(l.searchThemeInfoMsg, actentries, endentries, tostring(totalentries)), WHERE.CENTER)
		if not j_table then
			return MENU_RETURN.EXIT_ALL
		end
		if j_table.err == 2 then
			return false
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

	addToggle(m_theme_sel, {confKey="allThemes", action="changeAllThemes", hint=l.themeAllH, name=l.themeAll})

	themeList = {}
	for i=1, j do
		local themeCount = '(' .. tostring(mtList[i].count) .. ')'
		local themeItem = m_theme_sel:addItem{type="forwarder", action="changeTheme", hint_icon="hint_service", hint=l.themeEntryH, id=mtList[i].name, value=themeCount, name=mtList[i].name}
		m_theme_sel:setActive{item=themeItem, activ=(conf.allThemes=='off')}
		themeList[i] = themeItem
	end

	m_theme_sel:exec()
	restoreFullScreen(screen, true)
	if ((conf.theme ~= old_theme) or (conf.allThemes ~= old_allThemes)) then
		repaintMediathek()
	end
end

function periodOfTimeMenu()
	local old_seeFuturePrograms = conf.seeFuturePrograms
	local old_seePeriod = conf.seePeriod
	local screen = saveFullScreen()
	local mi = menu.new{name=l.seePeriodHeader, icon=pluginIcon}
	mi:addItem{type="subhead", name=l.seePeriodSubheader}
	mi:addItem{type="separator"}
	mi:addItem{type="back", hint_icon="hint_back", hint=l.backH}
	mi:addItem{type="separatorline"}
	addKillKey(mi)

	addToggle(mi, {confKey="seeFuturePrograms", hint=l.seePeriodFutureH, name=l.seePeriodFuture})
	opt={ 'all', '1', '3', '7', '14', '28', '60'}
	mi:addItem{type="chooser", action="setConfigValue", hint_icon="hint_service", hint=l.seePeriodDaysH, options=opt, id="seePeriod", value=conf.seePeriod, name=l.seePeriodDays}

	mi:exec()
	restoreFullScreen(screen, true)
	if ((conf.seeFuturePrograms ~= old_seeFuturePrograms) or (conf.seePeriod ~= old_seePeriod)) then
		repaintMediathek()
	end
end

function minDurationMenu()
	local old_seeMinimumDuration = conf.seeMinimumDuration
	local screen = saveFullScreen()
	local mi = menu.new{name=l.durationHeader, icon=pluginIcon}
	mi:addItem{type="subhead", name=l.durationSubheader}
	mi:addItem{type="separator"}
	mi:addItem{type="back", hint_icon="hint_back", hint=l.backH}
	mi:addItem{type="separatorline"}
	addKillKey(mi)

	mi:addItem{type="numeric", action="setConfigValue", range="0,120", hint_icon="hint_service", hint=l.durationMinH, id="seeMinimumDuration", value=conf.seeMinimumDuration, name=l.durationMin}

	mi:exec()
	restoreFullScreen(screen, true)
	if (conf.seeMinimumDuration ~= old_seeMinimumDuration) then
		repaintMediathek()
	end
end

function setSortMode(mode)
	conf.sortMode = mode
	return MENU_RETURN.EXIT_ALL
end

function sortMenu()
	local old_mode = conf.sortMode
	local screen = saveFullScreen()
	local mi = menu.new{name=l.sortHeader, icon=pluginIcon}
	mi:addItem{type="subhead", name=l.sortSubheader}
	mi:addItem{type="separator"}
	mi:addItem{type="back", hint_icon="hint_back", hint=l.backH}
	mi:addItem{type="separatorline"}
	addKillKey(mi)

	for _, mode in ipairs(sortModeOrder) do
		local labelFn = sortModeLabels[mode]
		local label = labelFn and labelFn() or mode
		local marker = ''
		if mode == conf.sortMode then
			marker = l.menuActive
		end
		mi:addItem{type="forwarder", action="setSortMode", hint_icon="hint_service", hint=l.menuSortHint, id=mode, value=marker, name=label}
	end

	mi:exec()
	restoreFullScreen(screen, true)
	if (conf.sortMode ~= old_mode) then
		repaintMediathek()
	end
end

function setGeoMode(mode)
	conf.geoMode = mode
	return MENU_RETURN.EXIT_ALL
end

function geoFilterMenu()
	local old_mode = conf.geoMode
	local screen = saveFullScreen()
	local mi = menu.new{name=l.geoHeader, icon=pluginIcon}
	mi:addItem{type="subhead", name=l.geoSubheader}
	mi:addItem{type="separator"}
	mi:addItem{type="back", hint_icon="hint_back", hint=l.backH}
	mi:addItem{type="separatorline"}
	addKillKey(mi)

	for _, mode in ipairs(geoModeOrder) do
		local labelFn = geoModeLabels[mode]
		local label = labelFn and labelFn() or mode
		local marker = ''
		if mode == conf.geoMode then
			marker = l.menuActive
		end
		mi:addItem{type="forwarder", action="setGeoMode", hint_icon="hint_service", hint=l.geoFilterHint, id=mode, value=marker, name=label}
	end

	mi:exec()
	restoreFullScreen(screen, true)
	if (conf.geoMode ~= old_mode) then
		repaintMediathek()
	end
end

function setQualityFilter(mode)
	conf.qualityFilter = mode
	return MENU_RETURN.EXIT_ALL
end

function qualityFilterMenu()
	local old_mode = conf.qualityFilter
	local screen = saveFullScreen()
	local mi = menu.new{name=l.qualityHeader, icon=pluginIcon}
	mi:addItem{type="subhead", name=l.qualitySubheader}
	mi:addItem{type="separator"}
	mi:addItem{type="back", hint_icon="hint_back", hint=l.backH}
	mi:addItem{type="separatorline"}
	addKillKey(mi)

	for _, mode in ipairs(qualityModeOrder) do
		local labelFn = qualityModeLabels[mode]
		local label = labelFn and labelFn() or mode
		local marker = ''
		if mode == conf.qualityFilter then
			marker = l.menuActive
		end
		mi:addItem{type="forwarder", action="setQualityFilter", hint_icon="hint_service", hint=l.qualityFilterHint, id=mode, value=marker, name=label}
	end

	mi:exec()
	restoreFullScreen(screen, true)
	if (conf.qualityFilter ~= old_mode) then
		repaintMediathek()
	end
end
