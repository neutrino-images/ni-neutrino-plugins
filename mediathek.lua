
mtLeftMenu_x		= SCREEN.OFF_X + 10
mtLeftMenu_w		= math.floor(N:scale2Res(240))
subMenuTop		= math.floor(N:scale2Res(10))
subMenuLeft		= math.floor(N:scale2Res(8))
subMenuSpace		= math.floor(N:scale2Res(16))
subMenuHight		= math.floor(N:scale2Res(26))
mtRightMenu_x		= mtLeftMenu_x + 8 + mtLeftMenu_w
mtRightMenu_w		= SCREEN.END_X - mtRightMenu_x-8
mtRightMenu_select	= 1
mtRightMenu_list_start	= 0
mtRightMenu_list_total	= 0
mtRightMenu_view_page	= 1
mtRightMenu_max_page	= 1

leftInfoBox_x		= 0
leftInfoBox_y		= 0
leftInfoBox_w		= 0
leftInfoBox_h		= 0

mtList			= {}

old_selectChannel	= ""

function playVideo()
	local flag_max = false
	local flag_normal = false
	local flag_min = false
	if (mtList[mtRightMenu_select].url_hd ~= "") then flag_max = true end
	if (mtList[mtRightMenu_select].url ~= "") then flag_normal = true end
	if (mtList[mtRightMenu_select].url_small ~= "") then flag_min = true end

	local url = ""
	-- conf=max: 1. max, 2. normal, 3. min
	if (conf.streamQuality == "max") then
		if (flag_max == true) then
			url = mtList[mtRightMenu_select].url_hd
		elseif (flag_normal == true) then
			url = mtList[mtRightMenu_select].url
		else
			url = mtList[mtRightMenu_select].url_small
		end
	-- conf=min: 1. min, 2. normal, 3. max
	elseif (conf.streamQuality == "min") then
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
	PlayMovie(mtList[mtRightMenu_select].title, url, mtList[mtRightMenu_select].theme, url, true);
	restoreFullScreen(screen, true)
end

function paint_mtItemLine(viewChannel, count)
	_item_x = mtRightMenu_x + 8
	_itemLine_y = itemLine_y + subMenuHight*count
	local bgCol  = 0
	local txtCol = 0
	local select
	if (count == mtRightMenu_select) then select=true else select=false end
--print(select)
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
		local cw = 10
		if (viewChannel == true) then
			paintItem(cw, "", 1);
			cw = 0
		end
		paintItem(24+cw/2, mtList[count].theme,    0);
		paintItem(35+cw/2, mtList[count].title,    0);
		paintItem(11,      mtList[count].date,     1);
		paintItem(6,       mtList[count].time,     1);
		paintItem(9,       mtList[count].duration, 1);
		local geo = ""
		if (mtList[count].geo ~= "") then geo = "X" end
		paintItem(5,       geo,      1);
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
	end

	local function paintHeadLine(viewChannel)
		G.paintSimpleFrame(x, y, rightItem_w, subMenuHight, frameColor, 0)
		local cw = 10
		if (viewChannel == true) then
			paintHead(cw, "Sender")
			cw = 0
		end
		paintHead(24+cw/2, "Thema")
		paintHead(35+cw/2, "Titel")
		paintHead(11, "Datum")
		paintHead(6, "Zeit")
		paintHead(9, "Dauer")
		paintHead(-5, "Geo")
	end

	itemLine_y = mtMenu_y+subMenuTop+2
	_item_x = 0
	paintHeadLine(false)

	local i = 1
	while (itemLine_y+subMenuHight*i < mtMenu_h+mtMenu_y-subMenuHight) do
		i = i + 1
	end
	mtRightMenu_count = i-1

-- json query
	local channel   = conf.playerSelectChannel
	local theme     = ""

	local timeMode  = timeMode_normal
	if (conf.playerSeeFuturePrograms == "on") then
		timeMode = timeMode_future
	end
	local period = 0
	if (conf.playerSeePeriod == "all") then
		period = -1
	else
		period = tonumber(conf.playerSeePeriod)
		if (period == nil) then
			period = 7
			conf.playerSeePeriod = period
		end
	end

	local minDuration = conf.playerSeeMinimumDuration * 60
	local start       = mtRightMenu_list_start
	local limit       = mtRightMenu_count
	local refTime     = 0

	-- make json for post request
	local sendData = getSendDataHead(queryMode_listVideos)
	local el = {}
	el['channel']		= channel
	el['duration']		= minDuration
	el['epoch']		= period
	el['limit']		= limit
	el['refTime']		= refTime
	el['start']		= start
	el['timeMode']		= timeMode
	sendData['data']	= {}
	sendData['data']	= el
	local post = J:encode(sendData)

	local dataFile = createCacheFileName(post, "json")
	post = C:setUriData("data1", post)
	local s = getJsonData2(url_new .. actionCmd_sendPostData, dataFile, post, queryMode_listVideos);
--	H.printf("\nretData:\n%s\n", tostring(s))

	local j_table = {}
	j_table = decodeJson(s)
	if (j_table == nil) then
		os.execute("rm -f " .. dataFile)
		return false
	end
	local noData = false
	if checkJsonError(j_table) == false then
		os.execute("rm -f " .. dataFile)
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
		mtList[1].channel	= ""
		mtList[1].theme		= ""
		mtList[1].title		= "Huhu..."
		mtList[1].date		= ""
		mtList[1].time		= ""
		mtList[1].duration	= ""
		mtList[1].geo		= ""
		mtList[1].description	= ""
		mtList[1].url		= ""
		mtList[1].url_small	= ""
		mtList[1].url_hd	= ""
		mtList[1].parse_m3u8	= ""
	else
		mtRightMenu_list_total = j_table.head.total
		mtRightMenu_max_page = math.ceil(mtRightMenu_list_total/mtRightMenu_count)

		if (#mtList > #j_table.entry) then
			while (#mtList > #j_table.entry) do table.remove(mtList) end
		end
		for i=1, #j_table.entry do
			mtList[i] = {}
			mtList[i].channel	= j_table.entry[i].channel
			mtList[i].theme		= j_table.entry[i].theme
			mtList[i].title		= j_table.entry[i].title
			mtList[i].date		= os.date("%d.%m.%Y", j_table.entry[i].date_unix)
			mtList[i].time		= os.date("%H:%M", j_table.entry[i].date_unix)
			mtList[i].duration	= formatDuration(j_table.entry[i].duration)
			mtList[i].geo		= j_table.entry[i].geo
			mtList[i].description	= j_table.entry[i].description
			mtList[i].url		= j_table.entry[i].url
			mtList[i].url_small	= j_table.entry[i].url_small
			mtList[i].url_hd	= j_table.entry[i].url_hd
			mtList[i].parse_m3u8	= j_table.entry[i].parse_m3u8
		end
	end

	for i = 1, mtRightMenu_count do
		paint_mtItemLine(false, i)
	end

	paintLeftInfoBox("Seite "..mtRightMenu_view_page.." von "..mtRightMenu_max_page)
end

function paintLeftInfoBox(txt)
	G.paintSimpleFrame(leftInfoBox_x, leftInfoBox_y, leftInfoBox_w, leftInfoBox_h,
			COL.FRAME, COL.MENUCONTENT_PLUS_1)
	N:RenderString(useDynFont, fontLeftMenu2, txt,
			leftInfoBox_x, leftInfoBox_y+subMenuHight,
			COL.MENUCONTENT_TEXT, leftInfoBox_w, subMenuHight, 1)
end

function paintMtLeftMenu(entry)

--	local bg_col		= COL.MENUCONTENT_PLUS_0
	local frameColor	= COL.FRAME
	local textColor		= COL.MENUCONTENT_TEXT

	local txtCol = COL.MENUCONTENT_TEXT
	local bgCol  = COL.MENUCONTENT_PLUS_0

	-- get button size
	buttonCol_w, buttonCol_h = N:GetSize(btnBlue)

	-- left frame
	G.paintSimpleFrame(mtLeftMenu_x, mtMenu_y, mtLeftMenu_w, mtMenu_h, frameColor, 0)

	-- infobox
	leftInfoBox_x = mtLeftMenu_x+subMenuLeft
	leftInfoBox_y = mtMenu_y+mtMenu_h-subMenuHight-subMenuLeft
	leftInfoBox_w = mtLeftMenu_w-subMenuLeft*2
	leftInfoBox_h = subMenuHight
	paintLeftInfoBox("")

	local y = 0
	local buttonCol_x = 0
	local buttonCol_y = 0

	local function paintItem(txt1, txt2, btn, enabled)
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
		G.paintSimpleFrame(mtLeftMenu_x+subMenuLeft, y, mtLeftMenu_w-subMenuLeft*2, subMenuHight, frameColor, bgCol)
--		if (enabled == true) then
			N:RenderString(useDynFont, fontLeftMenu2, txt2,
					mtLeftMenu_x+subMenuLeft, y+subMenuHight, txtCol, mtLeftMenu_w-subMenuLeft*2, subMenuHight, 1)
--		end
	end

	-- items
	local i = 0
	y = mtMenu_y+subMenuTop
	for i = 1, #entry do
		if (entry[i][4] == true) then
			paintItem(entry[i][1], entry[i][2], entry[i][3], entry[i][5])
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

	paintMtLeftMenu(leftMenuEntry)
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
		h_mtWindow = cwindow.new{x=x, y=y, dx=w, dy=h, color_body=bgCol, show_footer=false, name=pluginName .. " - v" .. pluginVersion, icon=pluginIcon};
	end
	paintMtWindow(false)
--	mtScreen = saveFullScreen()
end

function startMediathek()

	leftMenuEntry = {}
	local function fillLeftMenuEntry(e1, e2, e3, e4, e5)
		local i = #leftMenuEntry+1
		leftMenuEntry[i]	= {}
		leftMenuEntry[i][1]	= e1
		leftMenuEntry[i][2]	= e2
		leftMenuEntry[i][3]	= e3
		leftMenuEntry[i][4]	= e4
		leftMenuEntry[i][5]	= e5
	end

	fillLeftMenuEntry("Suche",		"",				btnRed,    true, false)
	fillLeftMenuEntry("Senderwahl",		conf.playerSelectChannel,	btnGreen,  true, true)
	fillLeftMenuEntry("Thema",		"",				btnYellow, true, false)
	fillLeftMenuEntry("Zeitraum",		set_playerSeePeriod(),		btnBlue,   true, true)
	local md = tostring(conf.playerSeeMinimumDuration) .. " Minuten"
	fillLeftMenuEntry("min. Sendungsdauer",	md,				btn1,      true, true)
	fillLeftMenuEntry("Sortieren",		"Datum",			btn2,      true, false)

	newMtWindow()

	repeat
		local msg, data = N:GetInput(500)

		if (msg == RC.down) then
			local select_old = mtRightMenu_select
			local aktSelect = (mtRightMenu_view_page-1)*mtRightMenu_count + mtRightMenu_select
			if (aktSelect < mtRightMenu_list_total) then
				mtRightMenu_select = mtRightMenu_select+1
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
				local old_start = mtRightMenu_list_start
				mtRightMenu_list_start = mtRightMenu_list_start + mtRightMenu_count
				if (mtRightMenu_list_start < mtRightMenu_list_total) then
					mtRightMenu_view_page = mtRightMenu_view_page+1

					local aktSelect = (mtRightMenu_view_page-1)*mtRightMenu_count + mtRightMenu_select
					if (aktSelect > mtRightMenu_list_total) then
						mtRightMenu_select = mtRightMenu_list_total-(mtRightMenu_max_page-1)*mtRightMenu_count
					end
					paintMtRightMenu()
				else
					mtRightMenu_list_start = old_start
				end
			end
		end

		if (msg == RC.up) then
			local select_old = mtRightMenu_select
			mtRightMenu_select = mtRightMenu_select-1
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
				local old_start = mtRightMenu_list_start
				mtRightMenu_list_start = mtRightMenu_list_start - mtRightMenu_count
				if (mtRightMenu_list_start >= 0) then
					mtRightMenu_view_page = mtRightMenu_view_page-1
					paintMtRightMenu()
				else
					mtRightMenu_list_start = old_start
				end
			end
		end

		if (msg == RC.info) then
			paintMovieInfo()
--		elseif ((msg == RC.red) or (msg == RC['4'])) then
--			serach
		elseif ((msg == RC.green) or (msg == RC['5'])) then
			channelMenu()
--		elseif ((msg == RC.yellow) or (msg == RC['6'])) then
--			theme
		elseif ((msg == RC.blue) or (msg == RC['7'])) then
			periodOfTime()
		elseif (msg == RC['1']) then
			minDurationMenu()
--		elseif (msg == RC['2']) then
--			sort
		elseif (msg == RC.ok) then
			playVideo()
		end
		-- exit plugin
		checkKillKey(msg)
	until msg == RC.home or forcePluginExit == true;
end

dofile(pluginScriptPath .. "/mediathek_leftMenu.lua");
dofile(pluginScriptPath .. "/mediathek_movieInfo.lua");
