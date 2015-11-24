
mtLeftMenu_x	= SCREEN.OFF_X + 10
mtLeftMenu_w	= 260
subMenuTop	= 10
subMenuLeft	= 8
subMenuSpace	= 16

function paintMtRightMenu(frame, frameColor, textColor)

	local mtRightMenu_x	= mtLeftMenu_x + 8 + mtLeftMenu_w
	local mtRightMenu_w	= SCREEN.END_X - mtRightMenu_x-8

	local bg_col		= COL.MENUCONTENT_PLUS_0
	local subMenuHight	= 26

	gui.paintSimpleFrame(mtRightMenu_x, mtMenu_y, mtRightMenu_w, mtMenu_h, frameColor, 0)

	local x		= mtRightMenu_x + 8
	local y		= mtMenu_y+subMenuTop
	local item_w	= mtRightMenu_w-subMenuLeft*2
	local item_x	= x

	local function paintHead(proz, txt)
		local paint = true
		if (proz < 1) then
			proz = math.abs(proz)
			paint = false
		end
		local w = ((item_w / 100) * proz)
		n:RenderString(useFixFont, fontLeftMenu1, txt, item_x, y+subMenuHight, textColor, w, subMenuHight, 1)
		item_x = item_x + w
		if (paint == true) then
			n:paintVLine(item_x, y, subMenuHight, frameColor)
		end
	end

	gui.paintSimpleFrame(x, y, item_w, subMenuHight, frameColor, 0)

	paintHead(10, "Sender")
	paintHead(25, "Thema")
	paintHead(36, "Titel")
	paintHead(8, "Datum")
	paintHead(8, "Zeit")
	paintHead(8, "Dauer")
	paintHead(-5, "Geo")

end

function paintMtLeftMenu(frame, frameColor, textColor, entry)

	local bg_col		= COL.MENUCONTENT_PLUS_0
	local subMenuHight	= 26

	-- get button size
	buttonCol_w, buttonCol_h = n:GetSize(btnBlue)

	-- left frame
	gui.paintSimpleFrame(mtLeftMenu_x, mtMenu_y, mtLeftMenu_w, mtMenu_h, frameColor, 0)

	local y = 0
	local buttonCol_x = 0
	local buttonCol_y = 0

	local function paintItem(txt1, txt2, btn)
		gui.paintSimpleFrame(mtLeftMenu_x+subMenuLeft, y, mtLeftMenu_w-subMenuLeft*2, subMenuHight, frameColor, 0)
		n:paintVLine(mtLeftMenu_x+subMenuLeft+subMenuHight, y, subMenuHight, frameColor)
		n:RenderString(useFixFont, fontLeftMenu1, txt1, 
				mtLeftMenu_x+subMenuLeft+subMenuHight+subMenuHight/3, y+subMenuHight, textColor, mtLeftMenu_w-subMenuHight-subMenuLeft*2, subMenuHight, 0)

		buttonCol_x = mtLeftMenu_x+subMenuLeft+(subMenuHight-buttonCol_w)/2
		buttonCol_y = y+(subMenuHight-buttonCol_h)/2
		n:DisplayImage(btn, buttonCol_x, buttonCol_y, buttonCol_w, buttonCol_h, 1)

		y = y + subMenuHight
		gui.paintSimpleFrame(mtLeftMenu_x+subMenuLeft, y, mtLeftMenu_w-subMenuLeft*2, subMenuHight, frameColor, bg)
		n:RenderString(useFixFont, fontLeftMenu2, txt2, 
				mtLeftMenu_x+subMenuLeft, y+subMenuHight, textColor, mtLeftMenu_w-subMenuLeft*2, subMenuHight, 1)
	end

	-- item 1
	local i = 1
	if (entry[i][3] == true) then
		y = mtMenu_y+subMenuTop
		paintItem(entry[i][1], entry[i][2], btnBlue)
	end

	-- item 2
	i = i+1
	if (entry[i][3] == true) then
		y = y + subMenuHight + subMenuSpace
		paintItem(entry[i][1], entry[i][2], btnYellow)
	end

	-- item 3
	i = i+1
	if (entry[i][3] == true) then
		y = y + subMenuHight + subMenuSpace
		paintItem(entry[i][1], entry[i][2], btnGreen)
	end

	-- item 4
	i = i+1
	if (entry[i][3] == true) then
		y = y + subMenuHight + subMenuSpace
		paintItem(entry[i][1], entry[i][2], btnRed)
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

	paintMtLeftMenu(1, COL.MENUCONTENT_TEXT, COL.MENUCONTENT_TEXT, leftMenuEntry)
	paintMtRightMenu(1, COL.MENUCONTENT_TEXT, COL.MENUCONTENT_TEXT)
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

	h_mtWindow = newMtWindow()

	repeat
		local msg, data = n:GetInput(500)
		-- settings
		if (msg == RC.setup) then
		end
		-- info
		if (msg == RC.info) then
			getVersionInfo()
		end
		ret = msg
	until msg == RC.home;

end
