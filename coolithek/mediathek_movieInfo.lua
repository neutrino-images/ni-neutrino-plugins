
function paintMovieInfo()

	local box_w	= 860
	local box_h	= 520
	if box_w > SCREEN.X_RES then box_w = SCREEN.X_RES-80 end
	if box_h > SCREEN.Y_RES then box_h = SCREEN.Y_RES-80 end
	local box	= mtInfoBox("Filminfo (" .. mtList[mtRightMenu_select].channel .. " Mediathek)", box_w, box_h)

	local hh	= box:headerHeight()
	local fh	= box:footerHeight()
	local x		= ((SCREEN.END_X - SCREEN.OFF_X) - box_w) / 2
	local y		= (((SCREEN.END_Y - SCREEN.OFF_Y) - box_h) / 2) + hh
	if x < 0 then x = 0 end
	if y < 0 then y = 0 end
	local real_h	= box_h - hh - fh

	local space_x = 6
	local space_y = 6
	local frame_x = x + space_x
	local frame_y = y + space_y
	local frame_w = box_w - 2*space_x
	local frame_h = real_h - 2*space_y
	gui.paintSimpleFrame(frame_x, frame_y, frame_w, frame_h,
			COL.MENUCONTENT_TEXT, 0)

	local function paintInfoItem(_x, _y, info1, info2, frame)
		local tmp1_h = fontLeftMenu1_h+4
		local tmp2_h = fontLeftMenu2_h+4
		local _y1 = _y
		local _y = _y+fontLeftMenu1_h+10
		n:RenderString(useDynFont, fontLeftMenu1, info1, _x+14, _y,
				COL.MENUCONTENT_TEXT, frame_w, tmp1_h, 0)
		_y = _y + tmp1_h+0

		if type(info2) ~= "table" then
			n:RenderString(useDynFont, fontLeftMenu2, info2, _x+12+10, _y,
					COL.MENUCONTENT_TEXT, frame_w, tmp2_h, 0)
		else
			local maxLines = 4
			local lines = #info2
			if (lines > maxLines) then lines = maxLines end
			local i = 1
			for i=1, lines do
				local txt = string.gsub(info2[i],"\n", " ");
				n:RenderString(useDynFont, fontLeftMenu2, txt, _x+12+10, _y,
						COL.MENUCONTENT_TEXT, frame_w, tmp2_h, 0)
				_y = _y + tmp2_h
			end
			_y = _y - tmp2_h
		end
		if (frame == true) then
			gui.paintSimpleFrame(_x+8, _y1+6, frame_w-16, _y-_y1, COL.MENUCONTENT_TEXT, 0)
		end
		return _y
	end

	local step = 6
	-- theme
	local start_y = frame_y
	start_y = paintInfoItem(frame_x, start_y, "Thema", mtList[mtRightMenu_select].theme, true)

	-- title
	start_y = start_y + step
	local txt = adjustStringLen(mtList[mtRightMenu_select].title, frame_w-36, fontLeftMenu2)
	start_y = paintInfoItem(frame_x, start_y, "Titel", txt, true)

	-- date
	start_y = start_y + step
	txt = mtList[mtRightMenu_select].date .. " / " .. mtList[mtRightMenu_select].time
	paintInfoItem(frame_x, start_y, "Datum / Zeit", txt, true)
		-- duration
		txt = mtList[mtRightMenu_select].duration
		start_y = paintInfoItem(frame_x+frame_w/2, start_y, "Dauer", txt, false)

	-- description
	if (#mtList[mtRightMenu_select].description > 0) then
		start_y = start_y + step
		txt = autoLineBreak(mtList[mtRightMenu_select].description, frame_w-36, fontLeftMenu2)
		start_y = paintInfoItem(frame_x, start_y, "Beschreibung", txt, true)
	end

	-- qual
	start_y = start_y + step
	local bottom_y = y+real_h-hh-fontLeftMenu1_h-fontLeftMenu2_h+0
	txt = ""
	local flag_max = false
	local flag_normal = false
	local flag_min = false
	if (mtList[mtRightMenu_select].url_hd ~= "") then flag_max = true end
	if (mtList[mtRightMenu_select].url ~= "") then flag_normal = true end
	if (mtList[mtRightMenu_select].url_small ~= "") then flag_min = true end
	if (flag_max == true) then
		txt = "Maximal"
		if ((flag_normal == true) or (flag_min == true)) then
			txt = txt .. ", "
		end
	end
	if (flag_normal == true) then
		txt = txt .. "Normal"
		if (flag_min == true) then
			txt = txt .. ", "
		end
	end
	if (flag_min == true) then
		txt = txt .. "Minimal"
	end

	paintInfoItem(frame_x, bottom_y, "verfügbare Streamqualität", txt, true)
		-- geo
		start_y = start_y + step
		txt = mtList[mtRightMenu_select].geo
		paintInfoItem(frame_x+frame_w/2, bottom_y, "Geoblocking", txt, false)

	repeat
		local msg, data = n:GetInput(500)
		if (msg == RC.info) then
		end
		menuRet = msg
	until msg == RC.red or msg == RC.home;
	gui.hideInfoBox(box)
end
