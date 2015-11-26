
mtLeftMenu_x		= SCREEN.OFF_X + 10
mtLeftMenu_w		= 240
subMenuTop		= 10
subMenuLeft		= 8
subMenuSpace		= 16
subMenuHight		= 26
mtRightMenu_x		= mtLeftMenu_x + 8 + mtLeftMenu_w
mtRightMenu_w		= SCREEN.END_X - mtRightMenu_x-8
mtRightMenu_select	= 1
mtRightMenu_list_start	= 0
mtRightMenu_list_total	= 0
mtRightMenu_view_page	= 1
mtRightMenu_max_page	= 1

mtInfoBox_x		= 0
mtInfoBox_y		= 0
mtInfoBox_w		= 0
mtInfoBox_h		= 0

mtList			= {}

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
		txtCol = COL.MENUCONTENT_TEXT
		bgCol  = COL.MENUCONTENT_PLUS_0
	else
		txtCol = COL.MENUCONTENT_TEXT
		bgCol  = COL.MENUCONTENT_PLUS_1
	end
	n:PaintBox(rightItem_x, _itemLine_y, rightItem_w, subMenuHight, bgCol)

	local function paintItem(vH, txt, center)
		local _x = 0
		if (center == 0) then _x=6 end
		local w = ((rightItem_w / 100) * vH)
		if (vH > 20) then txt = adjustStringLen(txt, w-_x*2, fontLeftMenu1) end
		n:RenderString(useFixFont, fontLeftMenu1, txt, _item_x+_x, _itemLine_y+subMenuHight, txtCol, w, subMenuHight, center)
		_item_x = _item_x + w
	end

	if (count <= #mtList) then
		local cw = 10
		if (viewChannel == true) then
			paintItem(cw, "", 1);	-- channel
			cw = 0
		end
		paintItem(24+cw/2, mtList[count].theme,    0);	-- theme
		paintItem(35+cw/2, mtList[count].title,    0);	-- title
		paintItem(11,      mtList[count].date,     1);	-- date
		paintItem(6,       mtList[count].time,     1);	-- time
		paintItem(9,       mtList[count].duration, 1);	-- duration
		local geo = ""
		if (mtList[count].geo ~= "") then geo = "X" end
		paintItem(5,       geo,      1);	-- geo
	end

--[[
mtList[count].theme
mtList[count].title
mtList[count].date
mtList[count].time
mtList[count].duration
mtList[count].geo
]]

end

function paintMtRightMenu()
	local bg_col		= COL.MENUCONTENT_PLUS_0
	local frameColor	= COL.MENUCONTENT_TEXT
	local textColor		= COL.MENUCONTENT_TEXT

	gui.paintSimpleFrame(mtRightMenu_x, mtMenu_y, mtRightMenu_w, mtMenu_h, frameColor, 0)

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
		local w = ((rightItem_w / 100) * vH)
		n:RenderString(useFixFont, fontLeftMenu1, txt, item_x, y+subMenuHight, textColor, w, subMenuHight, 1)
		item_x = item_x + w
		if (paint == true) then
			n:paintVLine(item_x, y, subMenuHight, frameColor)
		end
	end

	local function paintHeadLine(viewChannel)
		gui.paintSimpleFrame(x, y, rightItem_w, subMenuHight, frameColor, 0)
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
	local channel   = url_encode("ZDF")
--	local theme     = url_encode("Terra X")
	local theme     = url_encode("Volle Kanne - Service täglich")
	local timeFrom  = "now"
	local period    = 30*DAY
--	local start     = 0
	local start     = mtRightMenu_list_start
	local limit     = mtRightMenu_count
	local query_url = url_base .. "/?action=listVideos&channel=" .. channel .. 
					"&theme=" .. theme .. 
					"&timeFrom=" .. timeFrom .. 
					"&period=" .. period .. 
					"&start=" .. start .. 
					"&limit=" .. limit
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

	mtRightMenu_list_total = j_table.head.total
	mtRightMenu_max_page = math.ceil(mtRightMenu_list_total/mtRightMenu_count)

	if (#mtList > #j_table.entry) then
		while (#mtList > #j_table.entry) do table.remove(mtList) end
	end
	for i=1, #j_table.entry do
		mtList[i] = {}
		mtList[i].theme		= j_table.entry[i].theme
		mtList[i].title		= j_table.entry[i].title
		mtList[i].date		= os.date("%d.%m.%Y", j_table.entry[i].date_unix)
		mtList[i].time		= os.date("%H:%M", j_table.entry[i].date_unix)
		mtList[i].duration	= os.date("%H:%M:%S", j_table.entry[i].duration)
		mtList[i].geo		= j_table.entry[i].geo
	end

--helpers.tprint(j_table.entry[1])
--print(j_table.entry[1].url)
--[[
title
description
url
url_small
url_hd
date_unix
duration
parse_m3u8
geo
]]

	for i = 1, mtRightMenu_count do
		paint_mtItemLine(false, i)
	end

	paintInfoBox("Seite "..mtRightMenu_view_page.." von "..mtRightMenu_max_page)
end

function paintInfoBox(txt)
	gui.paintSimpleFrame(mtInfoBox_x, mtInfoBox_y, mtInfoBox_w, mtInfoBox_h,
			COL.MENUCONTENT_TEXT, COL.MENUCONTENT_PLUS_1)
	n:RenderString(useFixFont, fontLeftMenu2, txt, 
			mtInfoBox_x, mtInfoBox_y+subMenuHight,
			COL.MENUCONTENT_TEXT, mtInfoBox_w, subMenuHight, 1)
end

function paintMtLeftMenu(entry)

--	local bg_col		= COL.MENUCONTENT_PLUS_0
	local frameColor	= COL.MENUCONTENT_TEXT
	local textColor		= COL.MENUCONTENT_TEXT

	local txtCol = COL.MENUCONTENT_TEXT
	local bgCol  = COL.MENUCONTENT_PLUS_0

	-- get button size
	buttonCol_w, buttonCol_h = n:GetSize(btnBlue)

	-- left frame
	gui.paintSimpleFrame(mtLeftMenu_x, mtMenu_y, mtLeftMenu_w, mtMenu_h, frameColor, 0)

	-- infobox
	mtInfoBox_x = mtLeftMenu_x+subMenuLeft
	mtInfoBox_y = mtMenu_y+mtMenu_h-subMenuHight-subMenuLeft
	mtInfoBox_w = mtLeftMenu_w-subMenuLeft*2
	mtInfoBox_h = subMenuHight
	paintInfoBox("")

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
		gui.paintSimpleFrame(mtLeftMenu_x+subMenuLeft, y, mtLeftMenu_w-subMenuLeft*2, subMenuHight, frameColor, bgCol)
		n:paintVLine(mtLeftMenu_x+subMenuLeft+subMenuHight, y, subMenuHight, frameColor)
		n:RenderString(useFixFont, fontLeftMenu1, txt1, 
				mtLeftMenu_x+subMenuLeft+subMenuHight+subMenuHight/3, y+subMenuHight, txtCol, mtLeftMenu_w-subMenuHight-subMenuLeft*2, subMenuHight, 0)

		buttonCol_x = mtLeftMenu_x+subMenuLeft+(subMenuHight-buttonCol_w)/2
		buttonCol_y = y+(subMenuHight-buttonCol_h)/2
		n:DisplayImage(btn, buttonCol_x, buttonCol_y, buttonCol_w, buttonCol_h, 1)

		y = y + subMenuHight
		gui.paintSimpleFrame(mtLeftMenu_x+subMenuLeft, y, mtLeftMenu_w-subMenuLeft*2, subMenuHight, frameColor, bgCol)
		if (enabled == true) then
			n:RenderString(useFixFont, fontLeftMenu2, txt2, 
					mtLeftMenu_x+subMenuLeft, y+subMenuHight, txtCol, mtLeftMenu_w-subMenuLeft*2, subMenuHight, 1)
		end
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
	n:PaintBox(0, 0, SCREEN.X_RES, SCREEN.Y_RES, COL.BACKGROUND)

end

function newMtWindow()
	local x = SCREEN.OFF_X
	local y = SCREEN.OFF_Y
	local w = SCREEN.END_X - x
	local h = SCREEN.END_Y - y
	h_mtWindow = cwindow.new{x=x, y=y, dx=w, dy=h, show_footer=false, name=pluginName .. " - v" .. pluginVersion, icon=pluginIcon};
	paintMtWindow(false)
	mtScreen = saveFullScreen()
	return h_mtWindow;
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

	fillLeftMenuEntry("Senderwahl", "ZDF", btnBlue, true, true)
	fillLeftMenuEntry("Thema",      "Terra X", btnYellow, true, true)
	fillLeftMenuEntry("Zeitraum",   "30 Tage", btnGreen, true, true)
	fillLeftMenuEntry("Suche",      "", btnRed, true, false)
	fillLeftMenuEntry("Sortieren",  "Datum", btn1, true, false)

	h_mtWindow = newMtWindow()

	repeat
		local msg, data = n:GetInput(500)

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
			getVersionInfo()
		elseif (msg == RC.ok) then
		end
		menuRet = msg
	until msg == RC.home;
end
