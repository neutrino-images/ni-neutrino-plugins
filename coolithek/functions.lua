

-- ####################################################################
-- convert a image: http://websemantics.co.uk/online_tools/image_to_data_uri_convertor/
-- function from http://lua-users.org/wiki/BaseSixtyFour

-- character table string
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- decode
function dec(data)
	data = string.gsub(data, '[^'..b..'=]', '')
	return (data:gsub('.', function(x)
	if (x == '=') then return '' end
	local r,f='',(b:find(x)-1)
	for i=6,1,-1 do r=r..(f%2^i-f%2^(i-1)>0 and '1' or '0') end
	return r;
	end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(x)
	if (#x ~= 8) then return '' end
	local c=0
	for i=1,8 do c=c+(x:sub(i,i)=='1' and 2^(8-i) or 0) end
	return string.char(c)
	end))
end

function decodeImage(b64Image, path)
	local imgTyp = b64Image:match("data:image/(.-);base64,")
	local repData = "data:image/" .. imgTyp .. ";base64,"
	local b64Data = string.gsub(b64Image, repData, "");

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
		f:write(dec(b64Data))
		f:close()
	else
		print("Create image ["..retImg.."] failed.")
		return ""
	end

	return retImg
end

-- ####################################################################

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

