
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
	if (useFixFont == true) then
		local fontError = 0;
		fontMainMenu,  fontError = n:getDynFont(0, 50)
		fontMiniInfo,  fontError = n:getDynFont(0, 40)
		fontLeftMenu1, fontError = n:getDynFont(0, 24)
		fontLeftMenu2, fontError = n:getDynFont(0, 26, "", DYNFONT.STYLE_BOLD)
	else
		fontMainMenu  = FONT.MENU
		fontMiniInfo  = FONT.MENU_TITLE
		fontLeftMenu1 = FONT.MENU
		fontLeftMenu2 = FONT.MENU
	end
--helpers.printf("\nfontMainMenu %d, fontMiniInfo %d\n", fontMainMenu, fontMiniInfo)
end

function paintMiniInfoBox(txt)
	local _w = n:getRenderWidth(useFixFont, fontMiniInfo, txt)
	local _h = n:FontHeight(useFixFont, fontMiniInfo)
	local dx = _w + 40
	local dy = _h
	local x = ((SCREEN.END_X - SCREEN.OFF_X) - dx) / 2
	local y = ((SCREEN.END_Y - SCREEN.OFF_Y) - dy) / 2
	local ib = gui.paintMiniInfoBox("", dx, dy)
	local col_text = COL.MENUCONTENTSELECTED_TEXT
	n:RenderString(useFixFont, fontMiniInfo, txt, x, y+dy, col_text, dx, dy, 1)
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

