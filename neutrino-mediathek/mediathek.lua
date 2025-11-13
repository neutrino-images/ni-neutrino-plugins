mtLeftMenu_x	= SCREEN.OFF_X + 10
mtLeftMenu_w	= math.floor(N:scale2Res(240))
subMenuTop	= math.floor(N:scale2Res(10))
subMenuLeft	= math.floor(N:scale2Res(8))
subMenuSpace	= math.floor(N:scale2Res(16))
subMenuHight	= math.floor(N:scale2Res(26))
mtRightMenu_x	= mtLeftMenu_x + 8 + mtLeftMenu_w
mtRightMenu_w	= SCREEN.END_X - mtRightMenu_x-8
mtRightMenu_select	= 1
mtRightMenu_list_start	= 0
mtRightMenu_list_total	= 0
mtRightMenu_view_page	= 1
mtRightMenu_max_page	= 1

leftInfoBox_x	= 0
leftInfoBox_y	= 0
leftInfoBox_w	= 0
leftInfoBox_h	= 0

mtList		= {}
mtBuffer	= {}
titleList	= {}
themeList	= {}

local entryMatchesFilters
local buildEntry
local sortEntries
local requiresFullBuffer
local matchesSearchFilters

local function formatDuration(d)
	local h = math.floor(d/3600)
	d = d - h*3600
	local m = math.floor(d/60)
	d = d - m*60
	local s = d
	return string.format('%02d:%02d:%02d', h, m, s)
end

function playOrDownloadVideo(playOrDownload)
	local flag_max = false
	local flag_normal = false
	local flag_min = false
	if (mtList[mtRightMenu_select].url_hd ~= '') then
		flag_max = true end
	if (mtList[mtRightMenu_select].url ~= '') then
		flag_normal = true end
	if (mtList[mtRightMenu_select].url_small ~= '') then
		flag_min = true end

	local quality = ''
	if (playOrDownload == true) then
		quality = conf.streamQuality
	else
		quality = conf.downloadQuality
	end
	local url = ''
	-- conf=max: 1. max, 2. normal, 3. min
	if (quality == 'max') then
		if (flag_max == true) then
			url = mtList[mtRightMenu_select].url_hd
		elseif (flag_normal == true) then
			url = mtList[mtRightMenu_select].url
		else
			url = mtList[mtRightMenu_select].url_small
		end
	-- conf=min: 1. min, 2. normal, 3. max
	elseif (quality == 'min') then
		if (flag_min == true) then
			url = mtList[mtRightMenu_select].url_small
		elseif (flag_normal == true) then
			url = mtList[mtRightMenu_select].url
		else
			url = mtList[mtRightMenu_select].url_hd
		end
	-- conf=normal: 1. normal, 2. max, 3. min
	else
		if (flag_normal == true) then
			url = mtList[mtRightMenu_select].url
		elseif (flag_max == true) then
			url = mtList[mtRightMenu_select].url_hd
		else
			url = mtList[mtRightMenu_select].url_small
		end
	end

	local screen = saveFullScreen()
	hideMtWindow()
	if (playOrDownload == true) then
		playMovie(url, mtList[mtRightMenu_select].title, mtList[mtRightMenu_select].theme, url, true)
	else
		downloadMovie(url, mtList[mtRightMenu_select].channel, mtList[mtRightMenu_select].title, mtList[mtRightMenu_select].description, mtList[mtRightMenu_select].theme, mtList[mtRightMenu_select].duration, mtList[mtRightMenu_select].date, mtList[mtRightMenu_select].time)
	end
	restoreFullScreen(screen, true)
end

function paint_mtItemLine(count)
	_item_x = mtRightMenu_x + 8
	_itemLine_y = itemLine_y + subMenuHight*count
	local bgCol  = 0
	local txtCol = 0
	local select
	if (count == mtRightMenu_select) then select=true else select=false end

	if (select == true) then
		txtCol = COL.MENUCONTENTSELECTED_TEXT
		bgCol  = COL.MENUCONTENTSELECTED_PLUS_0
	elseif ((count % 2) == 0) then
		txtCol = COL.MENUCONTENTDARK_TEXT
		bgCol  = COL.MENUCONTENTDARK_PLUS_0
	else
		txtCol = COL.MENUCONTENT_TEXT
		bgCol  = COL.MENUCONTENT_PLUS_0
	end
	N:PaintBox(rightItem_x, _itemLine_y, rightItem_w, subMenuHight, bgCol)

	local function paintItem(vH, txt, center)
		local _x = 0
		if (center == 0) then _x=6 end
		local w = math.floor(((rightItem_w / 100) * vH))
		if (vH > 20) then txt = adjustStringLen(txt, w-_x*2, fontLeftMenu1) end
		N:RenderString(useDynFont, fontLeftMenu1, txt, _item_x+_x, _itemLine_y+subMenuHight, txtCol, w, subMenuHight, center)
		_item_x = _item_x + w
	end

	if (count <= #mtList) then
		paintItem(29,	mtList[count].theme,	0)
		paintItem(40,	mtList[count].title,	0)
		paintItem(11,	mtList[count].date,	1)
		paintItem(6,	mtList[count].time,	1)
		paintItem(9,	mtList[count].duration,	1)
		local geo = ''
		if (mtList[count].geo ~= '') then geo = 'X' end
		paintItem(5,	geo,			1)
	end
end

function paintMtRightMenu()
	local bg_col		= COL.MENUCONTENT_PLUS_0
	local frameColor	= COL.FRAME
	local textColor		= COL.MENUCONTENT_TEXT

	G.paintSimpleFrame(mtRightMenu_x, mtMenu_y, mtRightMenu_w, mtMenu_h, frameColor, 0)

	local x		= mtRightMenu_x + 8
	local y		= mtMenu_y+subMenuTop
	rightItem_w	= mtRightMenu_w-subMenuLeft*2
	local item_x	= x
	rightItem_x	= x

	local function paintHeadLine()
		local function paintHead(vH, txt)
			local paint = true
			if (vH < 0) then
				vH = math.abs(vH)
				paint = false
			end
			local w = math.floor(((rightItem_w / 100) * vH))
			N:RenderString(useDynFont, fontLeftMenu1, txt, item_x, y+subMenuHight, textColor, w, subMenuHight, 1)
			item_x = item_x + w
			if (paint == true) then
				N:paintVLine(item_x, y, subMenuHight, frameColor)
			end
		end
		
		G.paintSimpleFrame(x, y, rightItem_w, subMenuHight, frameColor, 0)
		paintHead(29,	l.headerTheme)
		paintHead(40,	l.headerTitle)
		paintHead(11,	l.headerDate)
		paintHead(6,	l.headerTime)
		paintHead(9,	l.headerDuration)
		paintHead(-5,	l.headerGeo)
	end

	local function bufferEntries()
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

		local minDuration = conf.seeMinimumDuration * 60
		el['duration'] = minDuration

		local refTime = 0
		el['refTime'] = refTime

		local start = 0
		local limit = 1000

		local j = 1
		mtBuffer = {}
		local actentries = 0
		local maxentries = 999999
		local noDataOverall = false

		while (actentries < maxentries) do
			local sendData = getSendDataHead(queryMode_listVideos)
			el['limit'] = limit
			el['start'] = start
			sendData['data'] = {}
			sendData['data'] = el
			local post = J:encode(sendData)

			local dataFile = createCacheFileName(post, 'json')
			post = C:setUriData('data1', post)
			local s, err = getJsonData2(url_new .. actionCmd_sendPostData, dataFile, post, queryMode_listVideos)
			if not s then
				G.hideInfoBox(box)
				messagebox.exec{title=pluginName, text=l.networkError, buttons={'ok'}}
				return false
			end
--	H.printf("\nretData:\n%s\n", tostring(s))

			local endentries = actentries+limit-1
			if (endentries > maxentries) then
				endentries = maxentries
			end
			local totalentries = maxentries
			if (totalentries == 999999) then
				totalentries = l.searchTitleInfoAll
			end
			local box = paintAnInfoBox(string.format(l.searchTitleInfoMsg, actentries, endentries, tostring(totalentries)), WHERE.CENTER)
				local j_table = {}
			j_table, err = decodeJson(s)
			if (j_table == nil) then
				G.hideInfoBox(box)
				messagebox.exec{title=pluginName, text=l.jsonError, buttons={'ok'}}
				os.execute('rm -f ' .. dataFile)
				return false
			end
			local noData = false
			if checkJsonError(j_table) == false then
				os.execute('rm -f ' .. dataFile)
				if (j_table.err ~= 2) then
					return false
				end
				noData = true
			end

			if (noData == true) then
				noDataOverall = true
				maxentries = 0
			else
				for i=1, #j_table.entry do
					if matchesSearchFilters(j_table.entry[i]) then
						local entry = buildEntry(j_table.entry[i])
						if entryMatchesFilters(entry) then
							mtBuffer[j] = entry
							j = j + 1
						end
					end
				end
				start = start + limit
				maxentries = j_table.head.total
				actentries = actentries + limit
			end
			G.hideInfoBox(box)
		end -- while
		j = j - 1
		mtBuffer_list_total = j

		if (noDataOverall == true) or (mtBuffer_list_total <= 0) then
			mtBuffer_list_total = 1
			mtBuffer = {}
			mtBuffer[1] = {
				channel = '',
				theme = '',
				title = l.titleNotFound,
				date = '',
				time = '',
				duration = '',
				durationSec = 0,
				timestamp = 0,
				geo = '',
				description = '',
				url = '',
				url_small = '',
				url_hd = '',
				parse_m3u8 = ''
			}
		else
			sortEntries(mtBuffer)
		end

		selectionChanged = false
--		paintAnInfoBoxAndWait(string.format(l.titleRead, mtBuffer_list_total), WHERE.CENTER, 3)
	end

	itemLine_y = mtMenu_y+subMenuTop+2
	_item_x = 0
	paintHeadLine()

	local i = 1
	while (itemLine_y+subMenuHight*i < mtMenu_h+mtMenu_y-subMenuHight) do
		i = i + 1
	end
	mtRightMenu_count = i-1

	local useBuffer = requiresFullBuffer()
	if useBuffer == false then -- No dedicated theme or title selected and no advanced filter
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

		local minDuration = conf.seeMinimumDuration * 60
		el['duration'] = minDuration

		local start = mtRightMenu_list_start
		el['start'] = start

		local limit = mtRightMenu_count
		el['limit'] = limit

		local refTime = 0
		el['refTime'] = refTime

		local sendData = getSendDataHead(queryMode_listVideos)
		sendData['data'] = {}
		sendData['data'] = el
		local post = J:encode(sendData)
	
		local dataFile = createCacheFileName(post, 'json')
		post = C:setUriData('data1', post)
		local s, err = getJsonData2(url_new .. actionCmd_sendPostData, dataFile, post, queryMode_listVideos)
		if not s then
			messagebox.exec{title=pluginName, text=l.networkError, buttons={'ok'}}
			os.execute('rm -f ' .. dataFile)
			return false
		end
--		H.printf("\nretData:\n%s\n", tostring(s))
	
		local j_table = {}
		j_table, err = decodeJson(s)
		if (j_table == nil) then
			messagebox.exec{title=pluginName, text=l.jsonError, buttons={'ok'}}
			os.execute('rm -f ' .. dataFile)
			return false
		end
		local noData = false
		if checkJsonError(j_table) == false then
			os.execute('rm -f ' .. dataFile)
			if (j_table.err ~= 2) then
				return false
			end
			noData = true
		end

		if (noData == true) then
			mtRightMenu_list_total = 0
			mtRightMenu_max_page = 0
			if (#mtList > 1) then
				while (#mtList > 1) do table.remove(mtList) end
			end
			mtList[1] = {}
			mtList[1].channel	= ''
			mtList[1].theme		= ''
			mtList[1].title		= l.titleNotFound
			mtList[1].date		= ''
			mtList[1].time		= ''
			mtList[1].duration	= ''
			mtList[1].durationSec	= 0
			mtList[1].timestamp	= 0
			mtList[1].geo		= ''
			mtList[1].description	= ''
			mtList[1].url		= ''
			mtList[1].url_small	= ''
			mtList[1].url_hd	= ''
			mtList[1].parse_m3u8	= ''
		else
			mtRightMenu_list_total = j_table.head.total

			if (#mtList > #j_table.entry) then
				while (#mtList > #j_table.entry) do table.remove(mtList) end
			end
			for i=1, #j_table.entry do
				mtList[i] = {}
				mtList[i].channel	= j_table.entry[i].channel
				mtList[i].theme		= j_table.entry[i].theme
				mtList[i].title		= j_table.entry[i].title
				mtList[i].date		= os.date(l.formatDate, j_table.entry[i].date_unix)
				mtList[i].time		= os.date(l.formatTime, j_table.entry[i].date_unix)
				mtList[i].duration	= formatDuration(j_table.entry[i].duration)
				mtList[i].durationSec	= j_table.entry[i].duration
				mtList[i].timestamp	= j_table.entry[i].date_unix or 0
				mtList[i].geo		= j_table.entry[i].geo
				mtList[i].description	= j_table.entry[i].description
				mtList[i].url		= j_table.entry[i].url
				mtList[i].url_small	= j_table.entry[i].url_small
				mtList[i].url_hd	= j_table.entry[i].url_hd
				mtList[i].parse_m3u8	= j_table.entry[i].parse_m3u8
			end
		end
	else -- Use buffered list (search results or advanced filters)
		if (selectionChanged == true) then
			bufferEntries()
		end
		mtRightMenu_list_total = mtBuffer_list_total

		if mtRightMenu_list_total <= 0 then
			mtRightMenu_list_total = 1
		end

		if mtRightMenu_list_start >= mtRightMenu_list_total then
			if mtRightMenu_list_total > mtRightMenu_count then
				mtRightMenu_list_start = mtRightMenu_list_total - mtRightMenu_count
			else
				mtRightMenu_list_start = 0
			end
			mtRightMenu_view_page = math.floor(mtRightMenu_list_start / mtRightMenu_count) + 1
		end

		if (#mtList > 0) then
			while (#mtList > 0) do table.remove(mtList) end
		end
		mtList = {}
		local maxBuffer = mtRightMenu_count
		local remaining = mtBuffer_list_total - mtRightMenu_list_start
		if remaining < maxBuffer then
			maxBuffer = remaining
		end
		if maxBuffer < 1 then
			maxBuffer = 1
		end
		for i=1, maxBuffer do
			local sourceIndex = mtRightMenu_list_start + i
			if sourceIndex <= mtBuffer_list_total then
				local src = mtBuffer[sourceIndex]
				mtList[i] = {
					channel = src.channel,
					theme = src.theme,
					title = src.title,
					date = src.date,
					time = src.time,
					duration = src.duration,
					durationSec = src.durationSec,
					timestamp = src.timestamp,
					geo = src.geo,
					description = src.description,
					url = src.url,
					url_small = src.url_small,
					url_hd = src.url_hd,
					parse_m3u8 = src.parse_m3u8
				}
			end
		end
	end -- Either with theme or title selected or not

	for i=1, mtRightMenu_count do
		paint_mtItemLine(i)
	end

	mtRightMenu_max_page = math.ceil(mtRightMenu_list_total/mtRightMenu_count)
	paintLeftInfoBox(string.format(l.menuPageOfPage, mtRightMenu_view_page, mtRightMenu_max_page))
end

function paintLeftInfoBox(txt)
	G.paintSimpleFrame(leftInfoBox_x, leftInfoBox_y, leftInfoBox_w, leftInfoBox_h, COL.FRAME, COL.MENUCONTENT_PLUS_1)
	N:RenderString(useDynFont, fontLeftMenu2, txt, leftInfoBox_x, leftInfoBox_y+subMenuHight, COL.MENUCONTENT_TEXT, leftInfoBox_w, subMenuHight, 1)
end

function paintMtLeftMenu()
	local frameColor	= COL.FRAME
	local textColor		= COL.MENUCONTENT_TEXT

	local txtCol = COL.MENUCONTENT_TEXT
	local bgCol  = COL.MENUCONTENT_PLUS_0

	buttonCol_w, buttonCol_h = N:GetSize(btnBlue)	-- any color is good

	-- left frame
	G.paintSimpleFrame(mtLeftMenu_x, mtMenu_y, mtLeftMenu_w, mtMenu_h, frameColor, 0)

	-- infobox
	leftInfoBox_x = mtLeftMenu_x+subMenuLeft
	leftInfoBox_y = mtMenu_y+mtMenu_h-subMenuHight-subMenuLeft
	leftInfoBox_w = mtLeftMenu_w-subMenuLeft*2
	leftInfoBox_h = subMenuHight
	paintLeftInfoBox('')

	local y = 0
	local buttonCol_x = 0
	local buttonCol_y = 0

	local function paintLeftItem(txt1, txt2, btn, enabled)
		if (enabled == true) then
			txtCol = COL.MENUCONTENT_TEXT
			bgCol  = COL.MENUCONTENT_PLUS_0
		else
			txtCol = COL.MENUCONTENTINACTIVE_TEXT
			bgCol  = COL.MENUCONTENTINACTIVE
		end
		G.paintSimpleFrame(mtLeftMenu_x+subMenuLeft, y, mtLeftMenu_w-subMenuLeft*2, subMenuHight, frameColor, bgCol)
		N:paintVLine(mtLeftMenu_x+subMenuLeft+subMenuHight, y, subMenuHight, frameColor)
		N:RenderString(useDynFont, fontLeftMenu1, txt1, math.floor(mtLeftMenu_x+subMenuLeft+subMenuHight+subMenuHight/3), y+subMenuHight, txtCol, mtLeftMenu_w-subMenuHight-subMenuLeft*2, subMenuHight, 0)

		buttonCol_x = math.floor(mtLeftMenu_x+subMenuLeft+(subMenuHight-buttonCol_w)/2)
		buttonCol_y = y+math.floor((subMenuHight-buttonCol_h)/2)
		N:DisplayImage(btn, buttonCol_x, buttonCol_y, buttonCol_w, buttonCol_h, 1)

		y = y + subMenuHight
		local crCount = 0
		for i=1, #txt2 do
			if string.sub(txt2, i, i) == '\n' then
				crCount = crCount + 1
			end
		end
--		paintAnInfoBoxAndWait("CRs: " .. crCount, WHERE.CENTER, 3)
		if crCount == 0 then
			G.paintSimpleFrame(mtLeftMenu_x+subMenuLeft, y, mtLeftMenu_w-subMenuLeft*2, subMenuHight, frameColor, bgCol)
			N:RenderString(useDynFont, fontLeftMenu2, txt2, mtLeftMenu_x+subMenuLeft, y+subMenuHight, txtCol, mtLeftMenu_w-subMenuLeft*2, subMenuHight, 1)
		else
			crCount = crCount + 1
			txt2 = txt2 .. '\n'
			G.paintSimpleFrame(mtLeftMenu_x+subMenuLeft, y, mtLeftMenu_w-subMenuLeft*2, crCount*subMenuHight, frameColor, bgCol)
			for i=1, crCount do
				local s, e = string.find(txt2, '\n')
--				paintAnInfoBoxAndWait("s: " .. s .. " e: " .. e, WHERE.CENTER, 3)
				if s ~= nil then
					local txt = string.sub(txt2, 1, s-1)
					txt2 = string.sub(txt2, e+1)
--					paintAnInfoBoxAndWait("Teil: " .. txt, WHERE.CENTER, 3)
					N:RenderString(useDynFont, fontLeftMenu2, txt, mtLeftMenu_x+subMenuLeft, y+subMenuHight, txtCol, mtLeftMenu_w-subMenuLeft*2, subMenuHight, 0)
					y = y + subMenuHight
				end
			end
		end
	end

	-- items
	local i = 0
	y = mtMenu_y+subMenuTop
	for i=1, #leftMenuEntry do
		if (leftMenuEntry[i][4] == true) then
			paintLeftItem(leftMenuEntry[i][1], leftMenuEntry[i][2], leftMenuEntry[i][3], leftMenuEntry[i][5])
			y = y + subMenuHight + subMenuSpace
		end
	end
end

function paintMtWindow(menuOnly)
	if (menuOnly == false) then
		h_mtWindow:paint{do_save_bg=true}
	end

	local hh	= h_mtWindow:headerHeight()
	local fh	= h_mtWindow:footerHeight()
	mtMenu_y	= SCREEN.OFF_Y + hh + 14
	mtMenu_h	= SCREEN.END_Y - mtMenu_y - hh - fh + 18

	paintMtLeftMenu()
	paintMtRightMenu()
end

function hideMtWindow()
	h_mtWindow:hide()
	N:PaintBox(0, 0, SCREEN.X_RES, SCREEN.Y_RES, COL.BACKGROUND)
end

function newMtWindow()
	if h_mtWindow == nil then
		local x = SCREEN.OFF_X
		local y = SCREEN.OFF_Y
		local w = SCREEN.END_X - x
		local h = SCREEN.END_Y - y

		local transp = false
		local bgCol = COL.MENUCONTENT_PLUS_0
		if (transp == true) then
			bgCol = bit32.band(0x00FFFFFF, bgCol)
			bgCol = bit32.bor(0xA0000000, bgCol)
		end
		h_mtWindow = cwindow.new{x=x, y=y, dx=w, dy=h, color_body=bgCol, show_footer=false, name=pluginName .. ' - v' .. pluginVersion, icon=pluginIcon}
	end
	paintMtWindow(false)
end

function formatTitle(allTitles, title)
	local space_x = math.floor(N:scale2Res(6))
	local frame_w = leftInfoBox_w - 2*space_x
	local f_title = l.formatAllTitles
	if allTitles == 'off' then
		f_title = title
		if conf.partialTitle == 'on' then f_title = '... ' .. f_title .. ' ...' end
	end
	f_title = adjustStringLen(f_title, frame_w-6, fontLeftMenu2)
	return f_title
end

function formatTheme(allThemes, theme)
	local space_x = math.floor(N:scale2Res(6))
	local frame_w = leftInfoBox_w - 2*space_x
	local f_theme = l.formatAllThemes
	if allThemes == 'off' then
		f_theme = theme
	end
	f_theme = adjustStringLen(f_theme, frame_w-6, fontLeftMenu2)
	return f_theme
end

function formatseePeriod()
	local period = ''
	local s = '- '
	if (conf.seeFuturePrograms == 'on') then
		s = '+/- '
	end
	if (conf.seePeriod == 'all') then
		period = l.formatSeePeriodAll
	elseif (conf.seePeriod == '1') then
		period = s .. l.formatSeePeriod1Day
	else
		period = s .. conf.seePeriod .. ' ' .. l.formatSeePeriodDays
	end
	return period
end

function formatMinDuration(duration)
	return tostring(duration) .. ' ' .. l.formatDurationMin
end

sortModeLabels = {
	date_desc = function() return l.menuSortDateDesc end,
	date_asc = function() return l.menuSortDateAsc end,
	title_asc = function() return l.menuSortTitleAsc end,
	title_desc = function() return l.menuSortTitleDesc end,
	duration_desc = function() return l.menuSortDurationDesc end,
	duration_asc = function() return l.menuSortDurationAsc end,
}

sortModeOrder = {
	'date_desc',
	'date_asc',
	'title_asc',
	'title_desc',
	'duration_desc',
	'duration_asc'
}

geoModeLabels = {
	all = function() return l.geoFilterAll end,
	no_geo = function() return l.geoFilterNoGeo end,
	only_geo = function() return l.geoFilterOnlyGeo end,
}

geoModeOrder = {'all', 'no_geo', 'only_geo'}

qualityModeLabels = {
	all = function() return l.qualityFilterAll end,
	require_hd = function() return l.qualityFilterHD end,
	require_sd = function() return l.qualityFilterSD end,
}

qualityModeOrder = {'all', 'require_hd', 'require_sd'}

function formatSortMode()
	local fn = sortModeLabels[conf.sortMode]
	if fn then return fn() end
	return l.menuSortDateDesc
end

function formatGeoMode()
	local fn = geoModeLabels[conf.geoMode]
	if fn then return fn() end
	return l.geoFilterAll
end

function formatQualityMode()
	local fn = qualityModeLabels[conf.qualityFilter]
	if fn then return fn() end
	return l.qualityFilterAll
end

entryMatchesFilters = function(entry)
	local geo = entry.geo or ''
	if conf.geoMode == 'no_geo' and geo ~= '' then
		return false
	elseif conf.geoMode == 'only_geo' and geo == '' then
		return false
	end
	local hasHD = entry.url_hd ~= nil and entry.url_hd ~= ''
	local hasSD = entry.url ~= nil and entry.url ~= ''
	if conf.qualityFilter == 'require_hd' and not hasHD then
		return false
	elseif conf.qualityFilter == 'require_sd' and not hasSD then
		return false
	end
	return true
end

buildEntry = function(apiEntry)
	return {
		channel = apiEntry.channel,
		theme = apiEntry.theme,
		title = apiEntry.title,
		date = os.date(l.formatDate, apiEntry.date_unix),
		time = os.date(l.formatTime, apiEntry.date_unix),
		duration = formatDuration(apiEntry.duration),
		durationSec = apiEntry.duration,
		timestamp = apiEntry.date_unix or 0,
		geo = apiEntry.geo or '',
		description = apiEntry.description or '',
		url = apiEntry.url or '',
		url_small = apiEntry.url_small or '',
		url_hd = apiEntry.url_hd or '',
		parse_m3u8 = apiEntry.parse_m3u8
	}
end

sortEntries = function(list)
	local mode = conf.sortMode
	local function compare(a, b)
		if mode == 'date_asc' then
			return (a.timestamp or 0) < (b.timestamp or 0)
		elseif mode == 'title_asc' then
			return (a.title or ''):lower() < (b.title or ''):lower()
		elseif mode == 'title_desc' then
			return (a.title or ''):lower() > (b.title or ''):lower()
		elseif mode == 'duration_desc' then
			return (a.durationSec or 0) > (b.durationSec or 0)
		elseif mode == 'duration_asc' then
			return (a.durationSec or 0) < (b.durationSec or 0)
		else -- date_desc default
			return (a.timestamp or 0) > (b.timestamp or 0)
		end
	end
	table.sort(list, compare)
end

requiresFullBuffer = function()
	if conf.allThemes ~= 'on' or conf.allTitles ~= 'on' then
		return true
	end
	if conf.sortMode ~= 'date_desc' then
		return true
	end
	if conf.geoMode ~= 'all' or conf.qualityFilter ~= 'all' then
		return true
	end
	return false
end

matchesSearchFilters = function(apiEntry)
	if conf.allThemes ~= 'on' then
		if (apiEntry.theme or '') ~= (conf.theme or '') then
			return false
		end
	end

	if conf.allTitles == 'on' then
		return true
	end

	local needle = conf.title or ''
	local hayTitle = apiEntry.title or ''
	local hayDescr = apiEntry.description or ''

	if conf.ignoreCase == 'on' then
		needle = needle:upper()
		hayTitle = hayTitle:upper()
		hayDescr = hayDescr:upper()
	end

	if conf.partialTitle ~= 'on' then
		return hayTitle == needle
	end

	if string.find(hayTitle, needle, 1, true) ~= nil then
		return true
	end

	if conf.inDescriptionToo == 'on' and string.find(hayDescr, needle, 1, true) ~= nil then
		return true
	end

	return false
end

function count_active_downloads()
	local count = 0
	local command = "find /tmp -name '.mediathek_dl_*.sh' -maxdepth 1 | wc -l"
	local handle = io.popen(command)

	if handle then
		count = tonumber(handle:read("*a")) or 0
		handle:close()
	end

	return count
end

function startMediathek()
	leftMenuEntry = {}
	local function fillLeftMenuEntry(e1, e2, e3, e4, e5)
		local i = #leftMenuEntry + 1
		leftMenuEntry[i]	= {}
		leftMenuEntry[i][1]	= e1
		leftMenuEntry[i][2]	= e2
		leftMenuEntry[i][3]	= e3
		leftMenuEntry[i][4]	= e4
		leftMenuEntry[i][5]	= e5
	end

	fillLeftMenuEntry(l.menuTitle,		formatTitle(conf.allTitles, conf.title),	btnRed,    true, true)
	fillLeftMenuEntry(l.menuChannel,	conf.channel,					btnGreen,  true, true)
	fillLeftMenuEntry(l.menuTheme,		formatTheme(conf.allThemes, conf.theme),	btnYellow, true, true)
	fillLeftMenuEntry(l.menuSeePeriod,	formatseePeriod(),				btnBlue,   true, true)
	fillLeftMenuEntry(l.menuMinDuration,	formatMinDuration(conf.seeMinimumDuration),	btn1,      true, true)
	fillLeftMenuEntry(l.menuSort,		formatSortMode(),				btn2,      true, true)
	fillLeftMenuEntry(l.menuGeoFilter,	formatGeoMode(),				btn3,      true, true)
	fillLeftMenuEntry(l.menuQualityFilter,	formatQualityMode(),				btn4,      true, true)
	selectionChanged = true

	newMtWindow()
	local topRightBox = nil

	repeat
		local msg, data = N:GetInput(500)

		if (msg == RC.down) then
			local select_old = mtRightMenu_select
			local aktSelect = (mtRightMenu_view_page - 1)*mtRightMenu_count + mtRightMenu_select
			if (aktSelect < mtRightMenu_list_total) then
				mtRightMenu_select = mtRightMenu_select + 1
				if (mtRightMenu_select > mtRightMenu_count) then
					if (mtRightMenu_view_page < mtRightMenu_max_page) then
						mtRightMenu_select = 1
						msg = RC.right
					else
						mtRightMenu_select = select_old
					end
				else
					paint_mtItemLine(select_old)
					paint_mtItemLine(mtRightMenu_select)
				end
			else
				mtRightMenu_select = select_old
			end
		end
		if ((msg == RC.right) or (msg == RC.page_down)) then
			if (mtRightMenu_list_total > mtRightMenu_count) then
				local old_mtRightMenu_list_start = mtRightMenu_list_start
				mtRightMenu_list_start = mtRightMenu_list_start + mtRightMenu_count
				if (mtRightMenu_list_start < mtRightMenu_list_total) then
					mtRightMenu_view_page = mtRightMenu_view_page + 1

					local aktSelect = (mtRightMenu_view_page - 1)*mtRightMenu_count + mtRightMenu_select
					if (aktSelect > mtRightMenu_list_total) then
						mtRightMenu_select = mtRightMenu_list_total-(mtRightMenu_max_page - 1)*mtRightMenu_count
					end
					paintMtRightMenu()
				else
					mtRightMenu_list_start = old_mtRightMenu_list_start
				end
			end
		end

		if (msg == RC.up) then
			local select_old = mtRightMenu_select
			mtRightMenu_select = mtRightMenu_select - 1
			if (mtRightMenu_select < 1) then
				if (mtRightMenu_view_page > 1) then
					mtRightMenu_select = mtRightMenu_count
					msg = RC.left
				else
					mtRightMenu_select = select_old
				end
			else
				paint_mtItemLine(select_old)
				paint_mtItemLine(mtRightMenu_select)
			end
		end
		if ((msg == RC.left) or (msg == RC.page_up)) then
			if (mtRightMenu_list_total > mtRightMenu_count) then
				local old_mtRightMenu_list_start = mtRightMenu_list_start
				mtRightMenu_list_start = mtRightMenu_list_start - mtRightMenu_count
				if (mtRightMenu_list_start >= 0) then
					mtRightMenu_view_page = mtRightMenu_view_page - 1
					paintMtRightMenu()
				else
					mtRightMenu_list_start = old_mtRightMenu_list_start
				end
			end
		end

		if (msg == RC.info) then
			paintMovieInfo()
		elseif (msg == RC.red) then
			titleMenu()
		elseif (msg == RC.green) then
			channelMenu()
		elseif (msg == RC.yellow) then
			themeMenu()
		elseif (msg == RC.blue) then
			periodOfTimeMenu()
		elseif (msg == RC['1']) then
			minDurationMenu()
		elseif (msg == RC['2']) then
			sortMenu()
		elseif (msg == RC['3']) then
			geoFilterMenu()
		elseif (msg == RC['4']) then
			qualityFilterMenu()
		elseif (msg == RC.ok) then
			playOrDownloadVideo(true)
		elseif (msg == RC.record) then
			playOrDownloadVideo(false)
		end
		-- exit plugin
		checkKillKey(msg)

		local countDLRunning = tonumber(count_active_downloads())
		if (countDLRunning > 0) then
			G.hideInfoBox(topRightBox)
			if (countDLRunning == 1) then
				topRightBox = paintTopRightInfoBox(l.statusDLRunning1)
			else
				topRightBox = paintTopRightInfoBox(string.format(l.statusDLRunningN, countDLRunning))
			end
		else
			G.hideInfoBox(topRightBox)
		end

	until msg == RC.home or forcePluginExit == true
end
