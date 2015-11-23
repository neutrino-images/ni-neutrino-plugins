
function saveFullScreen()
	return n:saveScreen(0, 0, SCREEN.X_RES, SCREEN.Y_RES);
end

function restoreFullScreen(screen, del)
	n:restoreScreen(0, 0, SCREEN.X_RES, SCREEN.Y_RES, screen, del);
end

function setFonts()
	if (useFixFont == true) then
		fontMainMenu = n:getDynFont(0, 50, fontID_MainMenu)
		fontMiniInfo = n:getDynFont(0, 40, fontID_MiniInfo)
	else
		fontMainMenu = FONT.MENU
		fontMiniInfo = FONT.MENU_TITLE
	end
--helpers.printf("\nfontMainMenu %d, fontMiniInfo %d\n", fontMainMenu, fontMiniInfo)
end

function paintMiniInfoBox(txt)
	local _w = n:getRenderWidth(useFixFont, fontMiniInfo, txt)
	local _h = n:FontHeight(useFixFont, fontMiniInfo)
	local dx = _w + 40
	local dy = _h + 0.2*_h
	local x = ((SCREEN.END_X - SCREEN.OFF_X) - dx) / 2
	local y = ((SCREEN.END_Y - SCREEN.OFF_Y) - dy) / 2
	local ib = gui.paintMiniInfoBox("", dx, dy)
	local col_text = COL.MENUCONTENTSELECTED_TEXT
	n:RenderString(useFixFont, fontMiniInfo, txt, x, y+dy-0.1*_h, col_text, dx, dy-0, 1)
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

