useDynFont = true -- Do not change!

function checkKillKey(msg)
	if (msg == RC.tv) or (msg == RC.radio) then
		forcePluginExit = true
	elseif (msg == RC.standby) then
		M:postMsg(POSTMSG.STANDBY_ON)
		forcePluginExit = true
	end
end -- function checkKillKey

function killPlugin(id)
	if (id == 'standby') then	-- no NLS
		M:postMsg(POSTMSG.STANDBY_ON)
	end
	forcePluginExit = true
	menuRet = MENU_RETURN.EXIT_ALL
	return menuRet
end -- function killPlugin

function addKillKey(menu)
	menu:addKey{directkey=RC.tv,		id='tv',		action='killPlugin'}	-- no NLS
	menu:addKey{directkey=RC.radio,		id='radio',		action='killPlugin'}	-- no NLS
	menu:addKey{directkey=RC.standby,	id='standby',	action='killPlugin'}	-- no NLS
end -- function addKillKey

function curlDownload(url, file, postData, hideBox, _ua, uriDecode)
	return downloadFileInternal(url, file, hideBox, _ua, postData, uriDecode)
end -- function curlDownload

function downloadFile(url, file, hideBox, _ua)
	return downloadFileInternal(url, file, hideBox, _ua, nil, nil)
end -- function downloadFile

function downloadFileInternal(url, file, hideBox, _ua, postData_, uriDecode)
	local ua = user_agent
	if _ua ~= nil then ua = _ua end
	box = paintAnInfoBox(l.readDataInfoMsg, WHERE.CENTER)
	if file ~= '' then os.remove(file) end
	local postData
	if postData_ ~= nil then
		postData = postData_
	else
		postData = ''
	end

	local v4 = false
	if (conf.networkIPV4Only == 'on') then	-- no NLS
		v4 = true
	end
	local s  = true
	if (conf.networkDlSilent == 'on') then	-- no NLS
		s  = false
	end
	local v = false
	if (conf.networkDlVerbose == 'on') then	-- no NLS
		v = true
	end
dlDebug = true
	if (dlDebug == true) then
		H.printf( '\n' ..	-- no NLS
				'   remote url: %s\n' ..	-- no NLS
				'         file: %s\n' ..	-- no NLS
				'     postData: %s\n' ..	-- no NLS
				'     ipv4only: %s\n' ..	-- no NLS
				'   user_agent: %s\n' ..	-- no NLS
				'       silent: %s\n' ..	-- no NLS
				'      verbose: %s' ..	-- no NLS
				'', url, tostring(file), C:decodeUri(tostring(postData)), tostring(v4), ua, tostring(s), tostring(v))
	end

s = false
v = true
	local ret, data
	if uriDecode == nil then
		if file ~= '' then
			ret, data = C:download{url=url, o=file, A=ua, ipv4=v4, s=s, v=v, postfields=postData}
		else
			ret, data = C:download{url=url,         A=ua, ipv4=v4, s=s, v=v, postfields=postData}
		end
	else
		ret, data     = C:download{url=url,         A=ua, ipv4=v4, s=s, v=v, postfields=postData}
		if (ret == 0) then
			data = C:decodeUri(data)
			if ((file ~= '') and (data ~= nil)) then
				local f = io.open(file, 'w+')	-- no NLS
				if f ~= nil then
					f:write(data)
					f:close()
					data = ''
				end
			end
		end
	end

	if (hideBox == true) then
		G.hideInfoBox(box)
		box = nil
	end
	if ret == CURL.OK then
		if file ~= '' then
			return box, ret, nil
		else
			return box, ret, data
		end
	else
		return     box, ret, data
	end
end -- function downloadFileInternal

function playMovie(title, url, info1, info2, enableMovieInfo)
	local function muteSleep(mute, wait)
		local threadFunc = [[
			local t = ...
			local P = require 'posix'	-- no NLS
			print(string.format(">>>>>[muteSleep] set AudioMute to %s, wait %d sec", tostring(t._mute), t._wait))	-- no NLS
			P.sleep(t._wait)
			M = misc.new()
			M:AudioMute(t._mute, true)
			return 1
		]]
		local mt = threads.new(threadFunc, {_mute=mute, _wait=wait})
		mt:start()
		return mt
	end -- function muteSleep

	local muteThread
	if (moviePlayed == false) then
		volumePlugin = M:getVolume()
		muteThread = muteSleep(muteStatusPlugin, 1)
	else
		M:AudioMute(muteStatusPlugin, true)
		M:setVolume(volumePlugin)
	end

	if enableMovieInfo == true then
		V:setInfoFunc('movieInfoMP')	-- no NLS
	end

	local status = V:PlayFile(title, url, info1, info2)
	if status == PLAYSTATE.LEAVE_ALL then forcePluginExit = true end

	muteStatusPlugin = M:isMuted()
	volumePlugin = M:getVolume()
	M:enableMuteIcon(false)
	M:enableInfoClock(false)

	V:ShowPicture(backgroundImage)
	moviePlayed = true
	if muteThread ~= nil then
		muteThread:join()
	end
end -- function playMovie

function downloadMovie(title, url)
	local function muteSleep(mute, wait)
		local threadFunc = [[
			local t = ...
			local P = require 'posix'	-- no NLS
			print(string.format(">>>>>[muteSleep] set AudioMute to %s, wait %d sec", tostring(t._mute), t._wait))	-- no NLS
			P.sleep(t._wait)
			M = misc.new()
			M:AudioMute(t._mute, true)
			return 1
		]]
		local mt = threads.new(threadFunc, {_mute=mute, _wait=wait})
		mt:start()
		return mt
	end -- function muteSleep

	local function validName(s)
		local t = ''
		for i=1, #s do
			local r = string.sub(s, i, i)
			if ((r >= 'A' and r <= 'Z') or	-- no NLS
				(r >= 'a' and r <= 'z') or	-- no NLS
				(r >= '0' and r <= '9') or	-- no NLS
				r == '.' or r == ',' or r == ':' or r == ';' or r == '-' or r == '(' or r == ')' or	-- no NLS
				r == '?' or r == '!') then	-- no NLS
				t = t .. r
			else
				t = t .. '_'	-- no NLS
			end
		end
		return t
	end -- function validName
	
	local muteThread
	if (moviePlayed == false) then
		volumePlugin = M:getVolume()
		muteThread = muteSleep(muteStatusPlugin, 1)
	else
		M:AudioMute(muteStatusPlugin, true)
		M:setVolume(volumePlugin)
	end

	if (conf.downloadPath ~= '/') then
		if (string.sub(url, -4) == '.mp4') then	-- no NLS
			local filePathName = conf.downloadPath .. '/' .. validName(title) .. string.sub(url, -4)	-- no NLS
			local filePathNameWOExt = string.sub(filePathName, 1, -5)
			local fileLOG = '"' .. filePathNameWOExt .. '.log"'	-- no NLS
			local fileLST = '"' .. filePathNameWOExt .. '.lst"'	-- no NLS
			local fileERR = '"' .. filePathNameWOExt .. '.err"'	-- no NLS
			local fileCMD = '"' .. filePathNameWOExt .. '.cmd"'	-- no NLS
			local info1 = l.statusDLStarted
			local info2 = string.format(l.statusDLWhat, title, filePathName, url, conf.streamQuality)
			paintInfoBoxAndWait(info1, info2, 10)
			local wgetCMD = 'wget --verbose --continue --no-check-certificate --inet4-only --user-agent=' .. user_agent2 .. ' --progress=dot:mega --output-document="' .. filePathName .. '" --output-file=' .. fileLOG .. ' ' .. url .. ' > ' .. fileLST .. ' 2> ' .. fileERR .. ' &'	-- no NLS
			os.execute('echo \'' .. wgetCMD .. '\' > ' .. fileCMD)
			os.execute(wgetCMD)
		else
			paintAnInfoBoxAndWait(l.statusDLNot, WHERE.CENTER, 10)
		end
	else
		paintAnInfoBoxAndWait(string.format(l.statusDLNoPath, conf.downloadPath), WHERE.CENTER, 10)
		local info1 = l.statusDLSpace
		local info2 = runACommand('df | grep Filesystem ; df -m | grep /dev/')	-- no NLS
		paintInfoBoxAndWait(info1, info2, 10)
	end

	muteStatusPlugin = M:isMuted()
	volumePlugin = M:getVolume()
	M:enableMuteIcon(false)
	M:enableInfoClock(false)

	V:ShowPicture(backgroundImage)
	moviePlayed = true
	if muteThread ~= nil then
		muteThread:join()
	end
end -- function downloadMovie

function debugPrint(msg)
	print('[' .. pluginName .. '] ' .. msg)	-- no NLS
end -- function debugPrint

function debugPrintf(...)
	print('[' .. pluginName .. '] ' .. string.format(...))-- no NLS
end -- function debugPrintf

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
	local ib = cwindow.new{x=x, y=y, dx=dx, dy=dy, title=hdr, btnRed=l.btnBeenden, icon="information", has_shadow=true, shadow_mode=1, show_footer=true} 	-- no NLS
	ib:paint()
	return ib
end -- function mtInfoBox

function autoLineBreak(str, len, font)
	if (not str) then return nil end
	if (not len) then return nil end
	if (not font) then return nil end

	local function checkLen(str, font)
		return N:getRenderWidth(useDynFont, font, str)
	end -- function checkLen

	local ret = {}
	local w = checkLen(str, font)
	if ((w <= len) or (len < 20)) then
		ret[1] = str
		return ret
	end

	local words = H.split(str, ' ')
	local lines = 1
	local tmpStr = ''
	for i=1, #words do
		if (checkLen(tmpStr .. ' ' .. words[i], font) <= len) then
			if (#tmpStr == 0) then
				tmpStr = words[i]
			else
				tmpStr = tmpStr .. ' ' .. words[i]
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
end -- function autoLineBreak

function adjustStringLen(str, len, font)
	local w = N:getRenderWidth(useDynFont, font, str)
	if (w <= len) then
		return str
	else
		local z = '...'	-- no NLS
		local wz = N:getRenderWidth(useDynFont, font, z)
		if (len <= 2*wz) then return str end
		str = string.sub(str, 1, #str-2)
		while (w+wz > len) do
			str = string.sub(str, 1, #str-1)
			w = N:getRenderWidth(useDynFont, font, str)
		end
		return str .. z
	end
end -- function adjustStringLen

function createCacheFileName(url, ext)
	local d = V:createChannelIDfromUrl(url)
	d = string.gsub(d, 'ffffffff', '')	-- no NLS
	return pluginTmpPath .. '/data_' .. d .. '.' .. ext	-- no NLS
end -- function createCacheFileName

-- url_decode/url_encode code from: http://lua-users.org/wiki/StringRecipes
function url_decode(str)
	str = string.gsub (str, '+', ' ')	-- no NLS
	str = string.gsub (str, '%%(%x%x)',	-- no NLS 
		function(h) return string.char(tonumber(h,16)) end)
	str = string.gsub (str, '\r\n', '\n')	-- no NLS
	return str
end -- function url_decode

function url_encode(str)
	if (str) then
		str = string.gsub (str, '\n', '\r\n')	-- no NLS
		str = string.gsub (str, '([^%w %-%_%.%~])',	-- no NLS
			function (c) return string.format ('%%%02X', string.byte(c)) end)	-- no NLS
		str = string.gsub (str, ' ', '+')	-- no NLS
	end
	return str
end -- function url_encode

function decodeImage(b64Data, imgTyp, path)
	local tmpImg = os.tmpname()
	local retImg
	if path ~= nil then
		retImg = string.gsub(tmpImg, '/tmp/', path .. '/') .. '.' .. imgTyp	-- no NLS
	else
		retImg = tmpImg .. '.' .. imgTyp	-- no NLS
	end
	os.remove(tmpImg)
	local f = io.open(retImg, 'w+')	-- no NLS
	if f ~= nil then
		f:write(H.base64Dec(b64Data))
		f:close()
	else
		print('Create image [' .. retImg .. '] failed.')	-- no NLS
		return ''
	end
	return retImg
end -- function decodeImage

function saveFullScreen()
	return N:saveScreen(0, 0, SCREEN.X_RES, SCREEN.Y_RES)
end -- function saveFullScreen

function restoreFullScreen(screen, del)
	N:restoreScreen(0, 0, SCREEN.X_RES, SCREEN.Y_RES, screen, del)
end -- function restoreFullScreen

function setFonts()
	if (useDynFont == false) then error('Failed to create fonts.') end	-- no NLS
	local fontError = 0
	if (fontMainMenu == nil) then
		fontMainMenu, fontError = N:getDynFont(0, N:scale2Res(conf.guiMainMenuSize))
		fontMainMenu_h = N:FontHeight(useDynFont, fontMainMenu)
	end
	if (fontMiniInfo == nil) then
		fontMiniInfo, fontError = N:getDynFont(0, N:scale2Res(26))
		fontMiniInfo_h = N:FontHeight(useDynFont, fontMiniInfo)
	end
	if (fontLeftMenu1 == nil) then
		fontLeftMenu1, fontError = N:getDynFont(0, N:scale2Res(24))
		fontLeftMenu1_h = N:FontHeight(useDynFont, fontLeftMenu1)
	end
	if (fontLeftMenu2 == nil) then
		fontLeftMenu2, fontError = N:getDynFont(0, N:scale2Res(26), '', DYNFONT.STYLE_BOLD)
		fontLeftMenu2_h = N:FontHeight(useDynFont, fontLeftMenu2)
	end
end -- function setFonts

function paintInfoBox(txt1, txt2)
	local tmp1_h = math.floor(fontLeftMenu1_h+N:scale2Res(4))
	local tmp2_h = math.floor(fontLeftMenu2_h+N:scale2Res(4))

	local crCount2 = 0
	for i=1, #txt2 do
		if string.sub(txt2, i, i) == '\n' then	-- no NLS
			crCount2 = crCount2 + 1
		end
	end

	crCount2 = crCount2 + 1
	txt2 = txt2 .. '\n'	-- no NLS

	local _txt = txt2
	local maxLen = 0
	for i=1, crCount2 do
		local s, e = string.find(_txt, '\n')	-- no NLS
--		paintAnInfoBoxAndWait("s: " .. s .. " e: " .. e, WHERE.CENTER, 2)
		if s ~= nil then
			local txt = string.sub(_txt, 1, s - 1)
			_txt = string.sub(_txt, e + 1)
--			paintAnInfoBoxAndWait("Teil: " .. txt, WHERE.CENTER, 2)
			local len = N:getRenderWidth(useDynFont, fontLeftMenu2, txt)
			if (len > maxLen) then maxLen = len end
		end
	end
	if (maxLen > SCREEN.END_X - SCREEN.OFF_X) then maxLen = SCREEN.END_X - SCREEN.OFF_X - 20 end

	local centerX = math.floor((SCREEN.END_X - SCREEN.OFF_X) / 2)
	local centerY = math.floor((SCREEN.END_Y - SCREEN.OFF_Y) / 2)

	local startX = math.floor(centerX - (maxLen/2))
	local startY = math.floor(centerY - (((crCount2*tmp2_h) + tmp1_h)/2))
	local dx = maxLen + 10
	local dy = (crCount2*tmp2_h) + tmp1_h + 10

--paintAnInfoBoxAndWait("tmp1_h: " .. tmp1_h, WHERE.CENTER, 10)
	G.paintSimpleFrame(startX-5, startY-5, dx, dy, COL.FRAME, COL.BACKGROUND)
	local ib = paintEmptyInfoBox(startX-5, startY-5, dx, dy)

	local _x = startX
	local _y = startY
	local widthX = N:getRenderWidth(useDynFont, fontLeftMenu1, txt1)
	_y = _y + tmp1_h
	N:RenderString(useDynFont, fontLeftMenu1, txt1, _x+5, _y+5, COL.MENUCONTENT_TEXT, widthX, tmp1_h, 0)

	_txt = txt2
	for i=1, crCount2 do
		local s, e = string.find(_txt, '\n')	-- no NLS
--		paintAnInfoBoxAndWait("s: " .. s .. " e: " .. e, WHERE.CENTER, 2)
		if s ~= nil then
			local txt = string.sub(_txt, 1, s - 1)
			_txt = string.sub(_txt, e + 1)
--			paintAnInfoBoxAndWait("Teil: " .. txt, WHERE.CENTER, 2)
			local widthX = N:getRenderWidth(useDynFont, fontLeftMenu2, txt)
			if (widthX > maxLen) then
				while N:getRenderWidth(useDynFont, fontLeftMenu2, txt) > maxLen-8 do
					txt = string.sub(txt, 1 , -2)
				end
				txt = txt .. "..."	-- no NLS
				widthX = N:getRenderWidth(useDynFont, fontLeftMenu2, txt)
			end
			local _x = math.floor(centerX - (widthX/2))
			_y = _y + tmp2_h
			N:RenderString(useDynFont, fontLeftMenu2, txt, _x, _y+5, COL.MENUCONTENT_TEXT, widthX, tmp2_h, 0)
		end
	end
	return ib
end -- function paintInfoBox

function paintInfoBoxAndWait(txt1, txt2, sec)
	local box = paintInfoBox(txt1, txt2)
	local P = require 'posix'	-- no NLS
	P.sleep(sec)
	G.hideInfoBox(box)
end -- function paintInfoBoxAndWait

function paintAnInfoBox(txt, where)
	local _w = N:getRenderWidth(useDynFont, fontMiniInfo, txt)
	local _h = N:FontHeight(useDynFont, fontMiniInfo)
	local dx = math.floor(_w + 40)
	local dy = math.floor(_h)
	local x, y
	if (where == WHERE.CENTER) then
		x  = math.floor(((SCREEN.END_X - SCREEN.OFF_X) - dx) / 2)
		y  = math.floor(((SCREEN.END_Y - SCREEN.OFF_Y) - dy) / 2)
	elseif (where == WHERE.TOPRIGHT) then
		x  = math.floor(SCREEN.END_X - dx)
		y  = math.floor(dy + 5)
	end
	local ib = paintEmptyInfoBox(x, y, dx, dy)
	N:RenderString(useDynFont, fontMiniInfo, txt, x, y+dy, COL.MENUCONTENTSELECTED_TEXT, dx, dy, 1)
	return ib
end -- function paintAnInfoBox

function paintAnInfoBoxAndWait(txt, where, sec)
	local box = paintAnInfoBox(txt, where)
	local P = require 'posix'	-- no NLS
	P.sleep(sec)
	G.hideInfoBox(box)
end -- function paintAnInfoBoxAndWait

function paintTopRightInfoBox(txt)
	local _w = N:getRenderWidth(useDynFont, fontMiniInfo, txt)
	local _h = N:FontHeight(useDynFont, fontMiniInfo)
	local dx = math.floor(_w + 40)
	local dy = math.floor(_h)
	local x  = math.floor(SCREEN.END_X - dx)
	local y  = math.floor(dy + 5)
	local ib = paintEmptyInfoBox(x, y, dx, dy)
	N:RenderString(useDynFont, fontMiniInfo, txt, x, y+dy, COL.YELLOW, dx, dy, 1)

--	local ib = cwindow.new{color_body=COL.MENUCONTENTSELECTED_PLUS_0, x=x, y=y, dx=dx+10, dy=dy, has_shadow=true, shadow_mode=1, show_footer=false, show_header=false}
--	ctext.new{parent=ib, x=0, y=0, dx=dx, dy=dy+4, text=txt, color_text=COL.YELLOW, color_body=COL.MENUCONTENTSELECTED_PLUS_0, font_text=FONT.MENU, mode="ALIGN_CENTER"}
--	ib:paint()
	return ib
end -- function paintTopRightInfoBox

function paintTopRightInfoBoxAndWait(txt, sec)
	local box = paintTopRightInfoBox(txt)
	local P = require 'posix'	-- no NLS
	P.sleep(sec)
	G.hideInfoBox(box)
end -- function paintTopRightInfoBoxAndWait

function paintEmptyInfoBox(x, y, w, h)
	local dx, dy
	if not w then dx = 250 else dx = w end
	if not h then dy = 50 else dy = h end
	if not x then x = ((SCREEN.END_X - SCREEN.OFF_X) - dx) / 2 end
	if not y then y = ((SCREEN.END_Y - SCREEN.OFF_Y) - dy) / 2 end

	local text = COL.MENUCONTENTSELECTED_TEXT
	local body = COL.MENUCONTENTSELECTED_PLUS_0
	x  = math.floor(x)
	y  = math.floor(y)
	dy = math.floor(dy)
	dx = math.floor(dx)

	local ib = cwindow.new{color_body=body, x=x, y=y, dx=dx, dy=dy, has_shadow=true, shadow_mode=1, show_footer=false, show_header=false}
	ib:paint()
	return ib
end -- function paintEmptyInfoBox

menuRet = nil -- global return value

function key_home(a)
	menuRet = MENU_RETURN.EXIT
	return menuRet
end -- function key_home

function key_setup(a)
	ret = MENU_RETURN.EXIT_ALL
	return menuRet
end -- function key_setup

function hideMenu(menu)
	if menu ~= nil then menu:hide() end
end -- function hideMenu

function getSendDataHead(mode)
	local ret = {}
	ret['software']	= softwareSig	-- no NLS
	if (pluginVersionBeta == 0) then
		ret['isBeta'] = false	-- no NLS
	else
		ret['isBeta'] = true	-- no NLS
	end
	ret['vBeta']	= pluginVersionBeta		-- no NLS
	ret['vMajor']	= pluginVersionMajor	-- no NLS
	ret['vMinor']	= pluginVersionMinor	-- no NLS
	ret['mode']		= mode					-- no NLS

	return ret
end -- function getSendDataHead

function runACommand(cmd)
	local handle = io.popen(cmd)
	local result = handle:read("*a")	-- no NLS
	handle:close()
	return result
end -- function runACommand
