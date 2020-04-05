mtLeftMenu_x	= SCREEN.OFF_X + 10
mtLeftMenu_w	= math.floor(N:scale2Res(240))
subMenuTop		= math.floor(N:scale2Res(10))
subMenuLeft		= math.floor(N:scale2Res(8))
subMenuSpace	= math.floor(N:scale2Res(16))
subMenuHight	= math.floor(N:scale2Res(26))
mtRightMenu_x	= mtLeftMenu_x + 8 + mtLeftMenu_w
mtRightMenu_w	= SCREEN.END_X - mtRightMenu_x-8
mtRightMenu_select		= 1
mtRightMenu_list_start	= 0
mtRightMenu_list_total	= 0
mtRightMenu_view_page	= 1
mtRightMenu_max_page	= 1

leftInfoBox_x	= 0
leftInfoBox_y	= 0
leftInfoBox_w	= 0
leftInfoBox_h	= 0

mtList			= {}
mtBuffer		= {}
titleList		= {}
themeList		= {}
--m_title_sel	= {}
--m_theme_sel	= {}

function playVideo()
	local flag_max = false
	local flag_normal = false
	local flag_min = false
	if (mtList[mtRightMenu_select].url_hd ~= '') then		flag_max = true end
	if (mtList[mtRightMenu_select].url ~= '') then			flag_normal = true end
	if (mtList[mtRightMenu_select].url_small ~= '') then	flag_min = true end

	local url = ''
	-- conf=max: 1. max, 2. normal, 3. min
	if (conf.streamQuality == 'max') then	-- no NLS
		if (flag_max == true) then
			url = mtList[mtRightMenu_select].url_hd
		elseif (flag_normal == true) then
			url = mtList[mtRightMenu_select].url
		else
			url = mtList[mtRightMenu_select].url_small
		end
	-- conf=min: 1. min, 2. normal, 3. max
	elseif (conf.streamQuality == 'min') then	-- no NLS
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
	playMovie(mtList[mtRightMenu_select].title, url, mtList[mtRightMenu_select].theme, url, true)
	restoreFullScreen(screen, true)
end -- function playVideo

function paint_mtItemLine(viewChannel, count)
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
	end -- function paintItem

	if (count <= #mtList) then
		local cw = 10
		if (viewChannel == true) then
			paintItem(cw, '', 1)
			cw = 0
		end
		paintItem(24+cw/2, mtList[count].theme,		0)
		paintItem(35+cw/2, mtList[count].title,		0)
		paintItem(11,      mtList[count].date,		1)
		paintItem(6,       mtList[count].time,		1)
		paintItem(9,       mtList[count].duration,	1)
		local geo = ''
		if (mtList[count].geo ~= '') then geo = 'X' end	-- no NLS
		paintItem(5,       geo,						1)
	end
end -- function paint_mtItemLine

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

	local function formatDuration(d)
		local h = math.floor(d/3600)
		d = d - h*3600
		local m = math.floor(d/60)
		d = d - m*60
		local s = d
		return string.format('%02d:%02d:%02d', h, m, s)	-- no NLS
	end -- function formatDuration

	local function paintHead(vH, txt)
		local paint = true
		if (vH < 1) then
			vH = math.abs(vH)
			paint = false
		end
		local w = math.floor(((rightItem_w / 100) * vH))
		N:RenderString(useDynFont, fontLeftMenu1, txt, item_x, y+subMenuHight, textColor, w, subMenuHight, 1)
		item_x = item_x + w
		if (paint == true) then
			N:paintVLine(item_x, y, subMenuHight, frameColor)
		end
	end -- function paintHead

	local function paintHeadLine(viewChannel)
		G.paintSimpleFrame(x, y, rightItem_w, subMenuHight, frameColor, 0)
		local cw = 10
		if (viewChannel == true) then
			paintHead(cw,	l.headerChannel)
			cw = 0
		end
		paintHead(24+cw/2,	l.headerTheme)
		paintHead(35+cw/2,	l.headerTitle)
		paintHead(11,		l.headerDate)
		paintHead(6,		l.headerTime)
		paintHead(9,		l.headerDuration)
		paintHead(-5,		l.headerGeo)
	end -- function paintHeadLine

	local function bufferEntries()
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

			local endentries = actentries+limit-1
			if (endentries > maxentries) then
				endentries = maxentries
			end
			local totalentries = maxentries
			if (totalentries == 999999) then
				totalentries = l.searchTitleInfoAll
			end
			local box = paintMiniInfoBox(string.format(l.searchTitleInfoMsg, actentries, endentries, tostring(totalentries)))
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
				noData = true
			end

			if (noData == true) then
				mtBuffer[1] = {}
				mtBuffer[1].channel		= ''
				mtBuffer[1].theme		= ''
				mtBuffer[1].title		= l.titleNotFound
				mtBuffer[1].date		= ''
				mtBuffer[1].time		= ''
				mtBuffer[1].duration	= ''
				mtBuffer[1].geo			= ''
				mtBuffer[1].description	= ''
				mtBuffer[1].url			= ''
				mtBuffer[1].url_small	= ''
				mtBuffer[1].url_hd		= ''
				mtBuffer[1].parse_m3u8	= ''
				maxentries = 1
			else
				for i=1, #j_table.entry do
					local title				= conf.title
					local allTitles			= conf.allTitles
					local partialTitle		= conf.partialTitle
					local inDescriptionToo	= conf.inDescriptionToo
					local theme				= conf.theme
					local allThemes			= conf.allThemes
					local t_title			= j_table.entry[i].title
					local t_description		= j_table.entry[i].description
					local t_theme			= j_table.entry[i].theme
					if conf.ignoreCase == 'on' then	-- no NLS
						title			= string.upper(title)
						t_title			= string.upper(t_title)
						t_description	= string.upper(t_description)
					end
					if ((theme == t_theme  and allTitles == 'on'                                                                                       ) or -- no NLS
						(allThemes == 'on' and title == t_title                                  and partialTitle == 'off'                             ) or -- no NLS
						(allThemes == 'on' and string.find(t_title, title, 1, true) ~= nil       and partialTitle == 'on'                              ) or -- no NLS
						(allThemes == 'on' and string.find(t_description, title, 1, true) ~= nil and partialTitle == 'on' and inDescriptionToo == 'on' ) or -- no NLS
						(theme == t_theme  and title == t_title                                  and partialTitle == 'off'                             ) or -- no NLS
						(theme == t_theme  and string.find(t_title, title, 1, true) ~= nil       and partialTitle == 'on'                              ) or -- no NLS
						(theme == t_theme  and string.find(t_description, title, 1, true) ~= nil and partialTitle == 'on' and inDescriptionToo == 'on' )) then -- no NLS
						mtBuffer[j] = {}
						mtBuffer[j].channel		= j_table.entry[i].channel
						mtBuffer[j].theme		= j_table.entry[i].theme
						mtBuffer[j].title		= j_table.entry[i].title
						mtBuffer[j].date		= os.date(l.formatDate, j_table.entry[i].date_unix)
						mtBuffer[j].time		= os.date(l.formatTime, j_table.entry[i].date_unix)
						mtBuffer[j].duration	= formatDuration(j_table.entry[i].duration)
						mtBuffer[j].geo			= j_table.entry[i].geo
						mtBuffer[j].description	= j_table.entry[i].description
						mtBuffer[j].url			= j_table.entry[i].url
						mtBuffer[j].url_small	= j_table.entry[i].url_small
						mtBuffer[j].url_hd		= j_table.entry[i].url_hd
						mtBuffer[j].parse_m3u8	= j_table.entry[i].parse_m3u8
						j = j + 1
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

		selectionChanged = false
		paintMiniInfoBoxAndWait(string.format(l.titleRead, mtBuffer_list_total), 1)
	end -- function bufferEntries

	itemLine_y = mtMenu_y+subMenuTop+2
	_item_x = 0
	paintHeadLine(false)

	local i = 1
	while (itemLine_y+subMenuHight*i < mtMenu_h+mtMenu_y-subMenuHight) do
		i = i + 1
	end
	mtRightMenu_count = i-1

	local allTitles = conf.allTitles
	local allThemes = conf.allThemes
	if allThemes == "on" and allTitles == 'on' then -- No dedicated theme or title selected - no NLS
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
	
		local dataFile = createCacheFileName(post, 'json')	-- no NLS
		post = C:setUriData('data1', post)	-- no NLS
		local s = getJsonData2(url_new .. actionCmd_sendPostData, dataFile, post, queryMode_listVideos)
--		H.printf("\nretData:\n%s\n", tostring(s))
	
		local j_table = {}
		j_table = decodeJson(s)
		if (j_table == nil) then
			os.execute('rm -f ' .. dataFile)	-- no NLS
			return false
		end
		local noData = false
		if checkJsonError(j_table) == false then
			os.execute('rm -f ' .. dataFile)	-- no NLS
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
			mtList[1].channel		= ''
			mtList[1].theme			= ''
			mtList[1].title			= l.titleNotFound
			mtList[1].date			= ''
			mtList[1].time			= ''
			mtList[1].duration		= ''
			mtList[1].geo			= ''
			mtList[1].description	= ''
			mtList[1].url			= ''
			mtList[1].url_small		= ''
			mtList[1].url_hd		= ''
			mtList[1].parse_m3u8	= ''
		else
			mtRightMenu_list_total = j_table.head.total

			if (#mtList > #j_table.entry) then
				while (#mtList > #j_table.entry) do table.remove(mtList) end
			end
			for i=1, #j_table.entry do
				mtList[i] = {}
				mtList[i].channel		= j_table.entry[i].channel
				mtList[i].theme			= j_table.entry[i].theme
				mtList[i].title			= j_table.entry[i].title
				mtList[i].date			= os.date(l.formatDate, j_table.entry[i].date_unix)
				mtList[i].time			= os.date(l.formatTime, j_table.entry[i].date_unix)
				mtList[i].duration		= formatDuration(j_table.entry[i].duration)
				mtList[i].geo			= j_table.entry[i].geo
				mtList[i].description	= j_table.entry[i].description
				mtList[i].url			= j_table.entry[i].url
				mtList[i].url_small		= j_table.entry[i].url_small
				mtList[i].url_hd		= j_table.entry[i].url_hd
				mtList[i].parse_m3u8	= j_table.entry[i].parse_m3u8
			end
		end
	else -- Just only the selected theme or title
		if (selectionChanged == true) then
			bufferEntries()
		end
		mtRightMenu_list_total = mtBuffer_list_total

		if (#mtList > 1) then
			while (#mtList > 1) do table.remove(mtList) end
		mtList = {}
		end
		local maxBuffer = mtRightMenu_count
		if (maxBuffer > mtBuffer_list_total - mtRightMenu_list_start) then
			maxBuffer = mtBuffer_list_total - mtRightMenu_list_start
		end
		for i=1, maxBuffer do
			mtList[i] = {}
			mtList[i].channel		= mtBuffer[mtRightMenu_list_start+i].channel
			mtList[i].theme			= mtBuffer[mtRightMenu_list_start+i].theme
			mtList[i].title			= mtBuffer[mtRightMenu_list_start+i].title
			mtList[i].date			= mtBuffer[mtRightMenu_list_start+i].date
			mtList[i].time			= mtBuffer[mtRightMenu_list_start+i].time
			mtList[i].duration		= mtBuffer[mtRightMenu_list_start+i].duration
			mtList[i].geo			= mtBuffer[mtRightMenu_list_start+i].geo
			mtList[i].description	= mtBuffer[mtRightMenu_list_start+i].description
			mtList[i].url			= mtBuffer[mtRightMenu_list_start+i].url
			mtList[i].url_small		= mtBuffer[mtRightMenu_list_start+i].url_small
			mtList[i].url_hd		= mtBuffer[mtRightMenu_list_start+i].url_hd
			mtList[i].parse_m3u8	= mtBuffer[mtRightMenu_list_start+i].parse_m3u8
		end
	end -- Either with theme or title selected or not

	for i = 1, mtRightMenu_count do
		paint_mtItemLine(false, i)
	end

	mtRightMenu_max_page = math.ceil(mtRightMenu_list_total/mtRightMenu_count)
	paintLeftInfoBox(string.format(l.menuPageOfPage, mtRightMenu_view_page, mtRightMenu_max_page))
end -- function paintMtRightMenu

function paintLeftInfoBox(txt)
	G.paintSimpleFrame(leftInfoBox_x, leftInfoBox_y, leftInfoBox_w, leftInfoBox_h,
			COL.FRAME, COL.MENUCONTENT_PLUS_1)
	N:RenderString(useDynFont, fontLeftMenu2, txt,
			leftInfoBox_x, leftInfoBox_y+subMenuHight,
			COL.MENUCONTENT_TEXT, leftInfoBox_w, subMenuHight, 1)
end -- function paintLeftInfoBox

function paintMtLeftMenu()
	local frameColor	= COL.FRAME
	local textColor		= COL.MENUCONTENT_TEXT

	local txtCol = COL.MENUCONTENT_TEXT
	local bgCol  = COL.MENUCONTENT_PLUS_0

	buttonCol_w, buttonCol_h = N:GetSize(btnBlue) 	-- any color is good

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
		N:RenderString(useDynFont, fontLeftMenu1, txt1,
				math.floor(mtLeftMenu_x+subMenuLeft+subMenuHight+subMenuHight/3), y+subMenuHight, txtCol, mtLeftMenu_w-subMenuHight-subMenuLeft*2, subMenuHight, 0)

		buttonCol_x = mtLeftMenu_x+subMenuLeft+(subMenuHight-buttonCol_w)/2
		buttonCol_y = y+(subMenuHight-buttonCol_h)/2
		N:DisplayImage(btn, buttonCol_x, buttonCol_y, buttonCol_w, buttonCol_h, 1)

		y = y + subMenuHight
		local crCount = 0
		for i=1, #txt2 do
			if string.sub(txt2, i, i) == '\n' then	-- no NLS
				crCount = crCount + 1
			end
		end
--		paintMiniInfoBoxAndWait("CRs: " .. crCount, 4)
		if crCount == 0 then
			G.paintSimpleFrame(mtLeftMenu_x+subMenuLeft, y, mtLeftMenu_w-subMenuLeft*2, subMenuHight, frameColor, bgCol)
			N:RenderString(useDynFont, fontLeftMenu2, txt2,
					mtLeftMenu_x+subMenuLeft, y+subMenuHight, txtCol, mtLeftMenu_w-subMenuLeft*2, subMenuHight, 1)
		else
			crCount = crCount + 1
			txt2 = txt2 .. '\n'	-- no NLS
			G.paintSimpleFrame(mtLeftMenu_x+subMenuLeft, y, mtLeftMenu_w-subMenuLeft*2, crCount*subMenuHight, frameColor, bgCol)
			for i=1, crCount do
				local s, e = string.find(txt2, '\n')	-- no NLS
--				paintMiniInfoBoxAndWait("s: " .. s .. " e: " .. e, 2)
				if s ~= nil then
					local txt = string.sub(txt2, 1, s-1)
					txt2 = string.sub(txt2, e+1)
--					paintMiniInfoBoxAndWait("Teil: " .. txt, 2)
					N:RenderString(useDynFont, fontLeftMenu2, txt,
							mtLeftMenu_x+subMenuLeft, y+subMenuHight, txtCol, mtLeftMenu_w-subMenuLeft*2, subMenuHight, 0)
					y = y + subMenuHight
				end
			end
		end
	end -- function paintLeftItem

	-- items
	local i = 0
	y = mtMenu_y+subMenuTop
	for i = 1, #leftMenuEntry do
		if (leftMenuEntry[i][4] == true) then
			paintLeftItem(leftMenuEntry[i][1], leftMenuEntry[i][2], leftMenuEntry[i][3], leftMenuEntry[i][5])
			y = y + subMenuHight + subMenuSpace
		end
	end
end -- function paintMtLeftMenu

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
end -- function paintMtWindow

function hideMtWindow()
	h_mtWindow:hide()
	N:PaintBox(0, 0, SCREEN.X_RES, SCREEN.Y_RES, COL.BACKGROUND)
end -- function hideMtWindow

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
		h_mtWindow = cwindow.new{x=x, y=y, dx=w, dy=h, color_body=bgCol, show_footer=false, name=pluginName .. ' - v' .. pluginVersion, icon=pluginIcon}	-- no NLS
	end
	paintMtWindow(false)
--	mtScreen = saveFullScreen()
end -- function newMtWindow

function formatTitle(allTitles, title)
	local space_x = math.floor(N:scale2Res(6))
	local frame_w = leftInfoBox_w - 2*space_x
	local f_title = l.formatAllTitles
	if allTitles == 'off' then	-- no NLS
		f_title = title 
		if conf.partialTitle == 'on' then f_title = '... ' .. f_title .. ' ...' end	-- no NLS
	end
	f_title = adjustStringLen(f_title, frame_w-6, fontLeftMenu2)
	return f_title
end -- function formatTitle

function formatTheme(allThemes, theme)
	local space_x = math.floor(N:scale2Res(6))
	local frame_w = leftInfoBox_w - 2*space_x
	local f_theme = l.formatAllThemes
	if allThemes == 'off' then f_theme = theme end	-- no NLS
	f_theme = adjustStringLen(f_theme, frame_w-6, fontLeftMenu2)
	return f_theme
end -- function formatTheme

function formatseePeriod()
	local period = ''
	local s = '- '	-- no NLS
	if (conf.seeFuturePrograms == 'on') then	-- no NLS
		s = '+/- '	-- no NLS
	end
	if (conf.seePeriod == 'all') then	-- no NLS
		period = l.formatSeePeriodAll
	elseif (conf.seePeriod == '1') then
		period = s .. l.formatSeePeriod1Day
	else
		period = s .. conf.seePeriod .. ' ' .. l.formatSeePeriodDays
	end
	return period
end -- function formatseePeriod

function formatMinDuration(duration)
	return tostring(duration) .. ' ' .. l.formatDurationMin
end -- function formatMinDuration

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
	end -- function fillLeftMenuEntry

	fillLeftMenuEntry(l.menuTitle,			formatTitle(conf.allTitles, conf.title),	btnRed,    true, true)
	fillLeftMenuEntry(l.menuChannel,		conf.channel,								btnGreen,  true, true)
	fillLeftMenuEntry(l.menuTheme,			formatTheme(conf.allThemes, conf.theme),	btnYellow, true, true)
	fillLeftMenuEntry(l.menuSeePeriod,		formatseePeriod(),							btnBlue,   true, true)
	fillLeftMenuEntry(l.menuMinDuration,	formatMinDuration(conf.seeMinimumDuration),	btn1,      true, true)
	fillLeftMenuEntry(l.menuSort,			"Datum",									btn2,      true, false) -- not yet implemented
	fillLeftMenuEntry(l.menuCaution,		l.menuWarning,								btn0,      true, true)

	selectionChanged = true

	newMtWindow()

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
					paint_mtItemLine(false, select_old)
					paint_mtItemLine(false, mtRightMenu_select)
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
				paint_mtItemLine(false, select_old)
				paint_mtItemLine(false, mtRightMenu_select)
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
		elseif ((msg == RC.red) or (msg == RC['4'])) then
			titleMenu()
		elseif ((msg == RC.green) or (msg == RC['5'])) then
			channelMenu()
		elseif ((msg == RC.yellow) or (msg == RC['6'])) then
			themeMenu()
		elseif ((msg == RC.blue) or (msg == RC['7'])) then
			periodOfTimeMenu()
		elseif (msg == RC['1']) then
			minDurationMenu()
--		elseif (msg == RC['2']) then
--			sort
		elseif (msg == RC.ok) then
			playVideo()
		end
		-- exit plugin
		checkKillKey(msg)
	until msg == RC.home or forcePluginExit == true
end -- function startMediathek

dofile(pluginScriptPath .. '/mediathek_leftMenu.lua')	-- no NLS
dofile(pluginScriptPath .. '/mediathek_movieInfo.lua')	-- no NLS
