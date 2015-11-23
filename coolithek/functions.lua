
function saveFullScreen()
	return n:saveScreen(0, 0, SCREEN.X_RES, SCREEN.Y_RES);
end

function restoreFullScreen(screen, del)
	n:restoreScreen(0, 0, SCREEN.X_RES, SCREEN.Y_RES, screen, del);
end

function setFonts()
	if (useFixFont == true) then
		fontMainMenu = n:getDynFont(0, 50, fontID_MainMenu)
		fontMiniInfo = n:getDynFont(0, 35, fontID_MiniInfo)
	else
		fontMainMenu = FONT.MENU
		fontMiniInfo = FONT.MENU_TITLE
	end
--helpers.printf("\nfontMainMenu %d, fontMiniInfo %d\n", fontMainMenu, fontMiniInfo)
end

function paintMiniInfoBox(txt, w, h)
	local dx, dy
	if not w then dx = 250 else dx = w end
	if not h then dy = 50 else dy = h end
	local x = ((SCREEN.END_X - SCREEN.OFF_X) - dx) / 2
	local y = ((SCREEN.END_Y - SCREEN.OFF_Y) - dy) / 2
	local ib = gui.paintMiniInfoBox("", w, h)
	local col_text = COL.MENUCONTENTSELECTED_TEXT
	n:RenderString(useFixFont, fontMiniInfo, txt, x+15, y+dy-4, col_text, dx-30, dy-4, 1)
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

