function paintMovieInfo(isMP, res, ratio, rate)

	local box_w	= math.floor(N:scale2Res(860))
	local box_h	= math.floor(N:scale2Res(520))
	if box_w > SCREEN.X_RES then box_w = math.floor(SCREEN.X_RES-N:scale2Res(80)) end
	if box_h > SCREEN.Y_RES then box_h = math.floor(SCREEN.Y_RES-N:scale2Res(80)) end
	local box	= mtInfoBox(string.format(l.infoHeader, mtList[mtRightMenu_select].channel), box_w, box_h)

	local hh	= box:headerHeight()
	local fh	= box:footerHeight()
	local x		= ((SCREEN.END_X - SCREEN.OFF_X) - box_w) / 2
	local y		= (((SCREEN.END_Y - SCREEN.OFF_Y) - box_h) / 2) + hh
	if x < 0 then x = 0 end
	if y < 0 then y = 0 end
	local real_h = box_h - hh - fh

	local space_x = math.floor(N:scale2Res(6))
	local space_y = math.floor(N:scale2Res(6))
	local frame_x = x + space_x
	local frame_y = y + space_y
	local frame_w = box_w - 2*space_x
	local frame_h = real_h - 2*space_y
	G.paintSimpleFrame(frame_x, frame_y, frame_w, frame_h, COL.FRAME, 0)
	local txt = ''

	local function paintInfoItem(_x, _y, info1, info2, frame)
		local tmp1_h = math.floor(fontLeftMenu1_h+N:scale2Res(4))
		local tmp2_h = math.floor(fontLeftMenu2_h+N:scale2Res(4))
		local _y1 = _y
		local _y = math.floor(_y+fontLeftMenu1_h+N:scale2Res(10))
		N:RenderString(useDynFont, fontLeftMenu1, info1, math.floor(_x+N:scale2Res(14)), _y, COL.MENUCONTENT_TEXT, frame_w, tmp1_h, 0)
		_y = _y + tmp1_h+0

		if type(info2) ~= 'table' then
			N:RenderString(useDynFont, fontLeftMenu2, info2,math.floor( _x+N:scale2Res(12+10)), _y, COL.MENUCONTENT_TEXT, frame_w, tmp2_h, 0)
		else
			local maxLines = 6
			local lines = #info2
			if (lines > maxLines) then lines = maxLines end
			local i = 1
			for i=1, lines do
				local txt = string.gsub(info2[i],'\n', ' ')
				N:RenderString(useDynFont, fontLeftMenu2, txt, math.floor(_x+N:scale2Res(12+10)), _y, COL.MENUCONTENT_TEXT, frame_w, tmp2_h, 0)
				_y = _y + tmp2_h
			end
			_y = _y - tmp2_h
		end
		if (frame == true) then
			G.paintSimpleFrame(math.floor(_x+N:scale2Res(8)), math.floor(_y1+N:scale2Res(6)), math.floor(frame_w-N:scale2Res(16)), _y-_y1, COL.FRAME, 0)
		end
		return _y
	end

	local step = math.floor(N:scale2Res(6))
	-- theme
	local start_y = frame_y
	start_y = paintInfoItem(frame_x, start_y, l.infoTheme, mtList[mtRightMenu_select].theme, true)

	-- title
	start_y = start_y + step
	txt = autoLineBreak(mtList[mtRightMenu_select].title, math.floor(frame_w-N:scale2Res(36)), fontLeftMenu2)
	start_y = paintInfoItem(frame_x, start_y, l.infoTitle, txt, true)

	-- date
	start_y = start_y + step
	txt = mtList[mtRightMenu_select].date .. ' / ' .. mtList[mtRightMenu_select].time
	paintInfoItem(frame_x, start_y, l.infoDateTime, txt, true)

	-- duration
	txt = mtList[mtRightMenu_select].duration
	start_y = paintInfoItem(frame_x+frame_w/2, start_y, l.infoDuration, txt, false)

	-- description
	if (#mtList[mtRightMenu_select].description > 0) then
		start_y = start_y + step
		txt = autoLineBreak(mtList[mtRightMenu_select].description, math.floor(frame_w-N:scale2Res(36)), fontLeftMenu2)
		start_y = paintInfoItem(frame_x, start_y, l.infoDescription, txt, true)
	end

	-- quality
	start_y = start_y + step
	local bottom_y = y+real_h-hh-fontLeftMenu1_h-fontLeftMenu2_h+0

	if (isMP == true) then
		txt = string.format('%s, %s, %s', res, ratio, rate)
		paintInfoItem(frame_x+frame_w/2, bottom_y, 'Streaminfo', txt, true)
	else
		txt = ''
		local flag_max = false
		local flag_normal = false
		local flag_min = false
		if (mtList[mtRightMenu_select].url_hd ~= '') then flag_max = true end
		if (mtList[mtRightMenu_select].url ~= '') then flag_normal = true end
		if (mtList[mtRightMenu_select].url_small ~= '') then flag_min = true end
		if (flag_max == true) then
			txt = l.infoQualityMax
			if ((flag_normal == true) or (flag_min == true)) then
				txt = txt .. ', '
			end
		end
		if (flag_normal == true) then
			txt = txt .. l.infoQualityNorm
			if (flag_min == true) then
				txt = txt .. ', '
			end
		end
		if (flag_min == true) then
			txt = txt .. l.infoQualityMin
		end

		paintInfoItem(frame_x, bottom_y, l.infoQuality, txt, true)
	end

	-- geo
	start_y = start_y + step
	txt = mtList[mtRightMenu_select].geo
	paintInfoItem(frame_x+frame_w*3/4, bottom_y, l.infoGeo, txt, false)

	repeat
		local msg, data = N:GetInput(500)
		if (msg == RC.info) then
		end
		-- exit plugin
		checkKillKey(msg)
	until msg == RC.red or msg == RC.home or forcePluginExit == true
	G.hideInfoBox(box)
end

function getStreamData(xres, yres, aspectRatio, framerate)
	local res, ratio, rate

	res = string.format('%sx%s', tostring(xres), tostring(yres))
	local r = tonumber(aspectRatio)
	if (r == 1) then
		ratio = '4:3'
	elseif (r == 2) then
		ratio = '14:9'
	elseif (r == 3) then
		ratio = '16:9'
	elseif (r == 4) then
		ratio = '20:9'
	else
		ratio = "N/A"
	end
	r = tonumber(framerate)
	if (r == 0) then
		rate = '23.976fps'
	elseif (r == 1) then
		rate = '24fps'
	elseif (r == 2) then
		rate = '25fps'
	elseif (r == 3) then
		rate = '29,976fps'
	elseif (r == 4) then
		rate = '30fps'
	elseif (r == 5) then
		rate = '50fps'
	elseif (r == 6) then
		rate = '50,94fps'
	elseif (r == 7) then
		rate = '60fps'
	else
		rate = 'N/A'
	end

	return res, ratio, rate
end

function movieInfoMP(xres, yres, aspectRatio, framerate)
	local res, ratio, rate = getStreamData(xres, yres, aspectRatio, framerate)
	paintMovieInfo(true, res, ratio, rate)
end
