
-- Do not change!
useDynFont = true

function debugPrint(msg)
	print("[" .. pluginName .. "] " .. msg)
end

function debugPrintf(...)
	print("[" .. pluginName .. "] " .. string.format(...))
end

function formatDuration(d)
	local h = math.floor(d/3600)
	d = d - h*3600
	local m = math.floor(d/60)
	local s = d - m*60
	return string.format("%02d:%02d:%02d", h, m, s)
end

--function round(x) return math.floor(x + 0.5) end

function mtInfoBox(hdr, w, h)
	local dx, dy
	if not w then dx = 800 else dx = w end
	if not h then dy = 360 else dy = h end
	if dx > SCREEN.X_RES then dx = SCREEN.X_RES end
	if dy > SCREEN.Y_RES then dx = SCREEN.Y_RES end
	local x = ((SCREEN.END_X - SCREEN.OFF_X) - dx) / 2
	local y = ((SCREEN.END_Y - SCREEN.OFF_Y) - dy) / 2
	if x < 0 then x = 0 end
	if y < 0 then y = 0 end
	local ib = cwindow.new{x=x, y=y, dx=dx, dy=dy, title=hdr, btnRed="Beenden", icon="information", has_shadow=true, shadow_mode=1, show_footer=true}
	ib:paint()
	return ib
end

function autoLineBreak(str, len, font)
	if (not str) then return nil end
	if (not len) then return nil end
	if (not font) then return nil end

	local function checkLen(str, font)
		return n:getRenderWidth(useDynFont, font, str)
	end

	local ret = {}
	local w = checkLen(str, font)
	if ((w <= len) or (len < 20)) then
		ret[1] = str
		return ret
	end

	local words = helpers.split(str, " ")
	local lines = 1
	local tmpStr = ""
	local i
	for i = 1, #words do
		if (checkLen(tmpStr .. " " .. words[i], font) <= len) then
			if (#tmpStr == 0) then
				tmpStr = words[i]
			else
				tmpStr = tmpStr .. " " .. words[i]
			end
		else
			ret[lines] = tmpStr
			lines = lines + 1
			tmpStr = words[i]
		end
		if ((i == #words) and (#tmpStr > 0)) then
			ret[lines] = tmpStr
		end
	end
	return ret
end

function adjustStringLen(str, len, font)
	local w = n:getRenderWidth(useDynFont, font, str)
	if (w <= len) then
		return str
	else
		local z = "..."
		local wz = n:getRenderWidth(useDynFont, font, z)
		if (len <= 2*wz) then return str end
		str = string.sub(str, 1, #str-2)
		while (w+wz > len) do
			str = string.sub(str, 1, #str-1)
			w = n:getRenderWidth(useDynFont, font, str)
		end
		return str .. z
	end
end

function createCacheFileName(url, ext)
	local d = n:createChannelIDfromUrl(url);
	d = string.gsub(d, "ffffffff", "")
	return pluginTmpPath .. "/data_" .. d .. "." .. ext
end

-- url_decode/url_encode code from: http://lua-users.org/wiki/StringRecipes
function url_decode(str)
	str = string.gsub (str, "+", " ")
	str = string.gsub (str, "%%(%x%x)",
		function(h) return string.char(tonumber(h,16)) end)
	str = string.gsub (str, "\r\n", "\n")
	return str
end

function url_encode(str)
	if (str) then
		str = string.gsub (str, "\n", "\r\n")
		str = string.gsub (str, "([^%w %-%_%.%~])",
			function (c) return string.format ("%%%02X", string.byte(c)) end)
		str = string.gsub (str, " ", "+")
	end
	return str
end

function decodeImage(b64Data, imgTyp, path)
	local tmpImg = os.tmpname()
	local retImg
	if path ~= nil then
		retImg = string.gsub(tmpImg, "/tmp/", path .. "/") .. "." .. imgTyp
	else
		retImg = tmpImg .. "." .. imgTyp
	end
	os.remove(tmpImg)
	local f = io.open(retImg, "w+")
	if f ~= nil then
		f:write(helpers.base64Dec(b64Data))
		f:close()
	else
		print("Create image ["..retImg.."] failed.")
		return ""
	end

	return retImg
end

function saveFullScreen()
	return n:saveScreen(0, 0, SCREEN.X_RES, SCREEN.Y_RES);
end

function restoreFullScreen(screen, del)
	n:restoreScreen(0, 0, SCREEN.X_RES, SCREEN.Y_RES, screen, del);
end

function setFonts()
	if (useDynFont == false) then error("Failed to create fonts.") end
	local fontError = 0;
	if (fontMainMenu == nil) then
		fontMainMenu, fontError = n:getDynFont(0, conf.guiMainMenuSize)
		fontMainMenu_h = n:FontHeight(useDynFont, fontMainMenu)
	end
	if (fontMiniInfo == nil) then
		fontMiniInfo, fontError = n:getDynFont(0, 26)
		fontMiniInfo_h = n:FontHeight(useDynFont, fontMiniInfo)
	end
	if (fontLeftMenu1 == nil) then
		fontLeftMenu1, fontError = n:getDynFont(0, 24)
		fontLeftMenu1_h = n:FontHeight(useDynFont, fontLeftMenu1)
	end
	if (fontLeftMenu2 == nil) then
		fontLeftMenu2, fontError = n:getDynFont(0, 26, "", DYNFONT.STYLE_BOLD)
		fontLeftMenu2_h = n:FontHeight(useDynFont, fontLeftMenu2)
	end
end

function paintMiniInfoBox(txt)
	local _w = n:getRenderWidth(useDynFont, fontMiniInfo, txt)
	local _h = n:FontHeight(useDynFont, fontMiniInfo)
	local dx = _w + 40
	local dy = _h
	local x = ((SCREEN.END_X - SCREEN.OFF_X) - dx) / 2
	local y = ((SCREEN.END_Y - SCREEN.OFF_Y) - dy) / 2
	local ib = gui.paintMiniInfoBox("", dx, dy)
	local col_text = COL.MENUCONTENTSELECTED_TEXT
	n:RenderString(useDynFont, fontMiniInfo, txt, x, y+dy, col_text, dx, dy, 1)
	return ib
end

menuRet = nil -- global return value
function key_home(a)
	menuRet = MENU_RETURN.EXIT
	return menuRet
end

function key_setup(a)
	ret = MENU_RETURN.EXIT_ALL
	return menuRet
end

function hideMenu(menu)
	if menu ~= nil then menu:hide() end
end

function dummy()
end

