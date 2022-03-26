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
	if (id == 'standby') then
		M:postMsg(POSTMSG.STANDBY_ON)
	end
	forcePluginExit = true
	menuRet = MENU_RETURN.EXIT_ALL
	return menuRet
end -- function killPlugin

function addKillKey(menu)
	menu:addKey{directkey=RC.tv,		id='tv',	action='killPlugin'}
	menu:addKey{directkey=RC.radio,		id='radio',	action='killPlugin'}
	menu:addKey{directkey=RC.standby,	id='standby',	action='killPlugin'}
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
	if (conf.networkIPV4Only == 'on') then
		v4 = true
	end
	local s  = true
	if (conf.networkDlSilent == 'on') then
		s  = false
	end
	local v = false
	if (conf.networkDlVerbose == 'on') then
		v = true
	end
dlDebug = true
	if (dlDebug == true) then
		H.printf( '\n' ..
			'   remote url: %s\n' ..
			'         file: %s\n' ..
			'     postData: %s\n' ..
			'     ipv4only: %s\n' ..
			'   user_agent: %s\n' ..
			'       silent: %s\n' ..
			'      verbose: %s' ..
			'', url, tostring(file), C:decodeUri(tostring(postData)), tostring(v4), ua, tostring(s), tostring(v))
	end

	s = false
	v = true
	local ret, data
	if uriDecode == nil then
		if file ~= '' then
			ret, data	= C:download{url=url, o=file, A=ua, ipv4=v4, s=s, v=v, postfields=postData}
		else
			ret, data	= C:download{url=url,         A=ua, ipv4=v4, s=s, v=v, postfields=postData}
		end
	else
		ret, data		= C:download{url=url,         A=ua, ipv4=v4, s=s, v=v, postfields=postData}
		if (ret == 0) then
			data = C:decodeUri(data)
			if ((file ~= '') and (data ~= nil)) then
				local f = io.open(file, 'w+')
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

function playMovie(url, title, info1, info2, enableMovieInfo)
	local function muteSleep(mute, wait)
		local threadFunc = [[
			local t = ...
			local P = require 'posix'
			print(string.format(">>>>>[muteSleep] set AudioMute to %s, wait %d sec", tostring(t._mute), t._wait))
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
		V:setInfoFunc('movieInfoMP')
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

function downloadMovie(url, channel, title, description, theme, duration, date, time)
	local function constructXMLFile(channel, title, description, theme, duration, date, time, downloadQuality)
		local function escape(s, w)
			local t = ''
			for i=1, #s do
				c = string.sub(s, i, i)
				t = t .. c
				if (c == w) then t = t .. c end
			end
			return t
		end -- function escape
		
		local xml = {}
		xml[1]	= '<?xml version="1.0" encoding="UTF-8"?>'
		xml[2]	= '<neutrino commandversion="1">'
		xml[3]	= '	<record command="record">'
		xml[4]	= '		<channelname>' .. channel .. '</channelname>'
		xml[5]	= '		<epgtitle>' .. title .. '</epgtitle>'
		xml[6]	= '		<id>0</id>'
		xml[7]	= '		<info1>' .. description .. '</info1>'
		xml[8]	= '		<info2>' .. string.format(l.xmlInfo2, theme, downloadQuality, date, time) .. '</info2>'
		xml[9]	= '		<epgid>0</epgid>'
		xml[10]	= '		<mode>1</mode>'
		xml[11]	= '		<videopid>0</videopid>'
		xml[12]	= '		<videotype>0</videotype>'
		xml[13]	= '		<vtxtpid>0</vtxtpid>'
		xml[14]	= '		<genremajor>0</genremajor>'
		xml[15]	= '		<genreminor>0</genreminor>'
		xml[16]	= '		<seriename></seriename>'
		xml[17]	= '		<length>' .. duration .. '</length>'
		xml[18]	= '		<productioncountry></productioncountry>'
		xml[19]	= '		<productiondate></productiondate>'
		xml[20]	= '		<rating>0</rating>'
		xml[21]	= '		<quality>' .. downloadQuality .. '</quality>'
		xml[22]	= '		<parentallockage>0</parentallockage>'
		xml[23]	= '		<dateoflastplay>0</dateoflastplay>'
		xml[24]	= '		<bookmark>'
		xml[25]	= '			<bookmarkstart>0</bookmarkstart>'
		xml[26]	= '			<bookmarkend>0</bookmarkend>'
		xml[27]	= '			<bookmarklast>0</bookmarklast>'
		xml[28]	= '			<bookmarkuser bookmarkuserpos="0" bookmarkusertype="0" bookmarkusername=""/>'
		xml[29]	= '		</bookmark>'
		xml[30]	= '	</record>'
		xml[31]	= '</neutrino>'

		local s = ''
		for i=1, #xml do
			s = s .. escape(xml[i], '\'') .. string.char(10)	-- NL
		end
		return s
	end -- function constructXMLFile

	local function muteSleep(mute, wait)
		local threadFunc = [[
			local t = ...
			local P = require 'posix'
			print(string.format(">>>>>[muteSleep] set AudioMute to %s, wait %d sec", tostring(t._mute), t._wait))
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
			if ((r >= 'A' and r <= 'Z') or
				(r >= 'a' and r <= 'z') or
				(r >= '0' and r <= '9') or
				r == '.' or r == ',' or r == '-' or
				r == '(' or r == ')' or r == '!') then
				t = t .. r
			else
				t = t .. '_'
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
		if (string.sub(url, -4) == '.mp4') then
			local date4Name = string.sub(date, 7, 10) .. string.sub(date, 4, 5) .. string.sub(date, 1, 2)
			local time4Name = string.sub(time, 1,  2) .. string.sub(time, 4, 5) .. '00'
			local filePathNameWOExt = conf.downloadPath .. '/' .. validName(channel) .. '_' .. validName(title) .. '_' .. date4Name .. '_' .. time4Name
			local fileMP4 = '"' .. filePathNameWOExt .. '.mp4"'
			local fileLOG = '"' .. filePathNameWOExt .. '.log"'
			local fileLST = '"' .. filePathNameWOExt .. '.lst"'
			local fileERR = '"' .. filePathNameWOExt .. '.err"'
			local fileCMD = '"' .. filePathNameWOExt .. '.cmd"'
			local fileXML = '"' .. filePathNameWOExt .. '.xml"'
			local info1 = l.statusDLStarted
			local info2 = string.format(l.statusDLWhat, channel, title, description, theme, duration, date, time, conf.downloadQuality, fileMP4, url)
			paintInfoBoxAndWait(info1, info2, conf.guiTimeMsg)
			local durationInMinutes = tostring(tonumber(string.sub(duration, 1, 2)) * 60 + tonumber(string.sub(duration, 4, 5)) + 1)
			local tagsXML = constructXMLFile(channel, title, description, theme, durationInMinutes, date, time, conf.downloadQuality)
			os.execute('echo \'' .. tagsXML .. '\' > ' .. fileXML)
			local wgetCMD = 'wget --verbose --continue --no-check-certificate --inet4-only --user-agent=' .. user_agent2 .. ' --progress=dot:mega --output-document=' .. fileMP4 .. ' --output-file=' .. fileLOG .. ' ' .. url .. ' > ' .. fileLST .. ' 2> ' .. fileERR .. ' &'
			os.execute('echo \'' .. wgetCMD .. '\' > ' .. fileCMD)
			os.execute(wgetCMD)
		else
			paintAnInfoBoxAndWait(l.statusDLNot, WHERE.CENTER, conf.guiTimeMsg)
		end
	else
		paintAnInfoBoxAndWait(string.format(l.statusDLNoPath, conf.downloadPath), WHERE.CENTER, conf.guiTimeMsg)
		local info1 = l.statusDLSpace
		local info2 = runACommand('df | grep Filesystem ; df -m | grep /dev/')
		paintInfoBoxAndWait(info1, info2, conf.guiTimeMsg)
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
	print('[' .. pluginName .. '] ' .. msg)
end -- function debugPrint

function debugPrintf(...)
	print('[' .. pluginName .. '] ' .. string.format(...))
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
	local ib = cwindow.new{x=x, y=y, dx=dx, dy=dy, title=hdr, btnRed=l.btnBeenden, icon="information", has_shadow=true, shadow_mode=1, show_footer=true}
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
		local z = '...'
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
	d = string.gsub(d, 'ffffffff', '')
	return pluginTmpPath .. '/data_' .. d .. '.' .. ext
end -- function createCacheFileName

-- url_decode/url_encode code from: http://lua-users.org/wiki/StringRecipes
function url_decode(str)
	str = string.gsub (str, '+', ' ')
	str = string.gsub (str, '%%(%x%x)',
		function(h) return string.char(tonumber(h,16)) end)
	str = string.gsub (str, '\r\n', '\n')
	return str
end -- function url_decode

function url_encode(str)
	if (str) then
		str = string.gsub (str, '\n', '\r\n')
		str = string.gsub (str, '([^%w %-%_%.%~])',
			function (c) return string.format ('%%%02X', string.byte(c)) end)
		str = string.gsub (str, ' ', '+')
	end
	return str
end -- function url_encode

function decodeImage(b64Data, imgTyp, path)
	local tmpImg = os.tmpname()
	local retImg
	if path ~= nil then
		retImg = string.gsub(tmpImg, '/tmp/', path .. '/') .. '.' .. imgTyp
	else
		retImg = tmpImg .. '.' .. imgTyp
	end
	os.remove(tmpImg)
	local f = io.open(retImg, 'w+')
	if f ~= nil then
		f:write(H.base64Dec(b64Data))
		f:close()
	else
		print('Create image [' .. retImg .. '] failed.')
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
	if (useDynFont == false) then error('Failed to create fonts.') end
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
		if string.sub(txt2, i, i) == '\n' then
			crCount2 = crCount2 + 1
		end
	end

	crCount2 = crCount2 + 1
	txt2 = txt2 .. '\n'

	local _txt = txt2
	local maxLen = 0
	for i=1, crCount2 do
		local s, e = string.find(_txt, '\n')
--		paintAnInfoBoxAndWait("s: " .. s .. " e: " .. e, WHERE.CENTER, 3)
		if s ~= nil then
			local txt = string.sub(_txt, 1, s - 1)
			_txt = string.sub(_txt, e + 1)
--			paintAnInfoBoxAndWait("Teil: " .. txt, WHERE.CENTER, 3)
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

--paintAnInfoBoxAndWait("tmp1_h: " .. tmp1_h, WHERE.CENTER, 3)
	G.paintSimpleFrame(startX-5, startY-5, dx, dy, COL.FRAME, COL.BACKGROUND)
	local ib = paintEmptyInfoBox(startX-5, startY-5, dx, dy)

	local _x = startX
	local _y = startY
	local widthX = N:getRenderWidth(useDynFont, fontLeftMenu1, txt1)
	_y = _y + tmp1_h
	N:RenderString(useDynFont, fontLeftMenu1, txt1, _x+5, _y+5, COL.MENUCONTENT_TEXT, widthX, tmp1_h, 0)

	_txt = txt2
	for i=1, crCount2 do
		local s, e = string.find(_txt, '\n')
--		paintAnInfoBoxAndWait("s: " .. s .. " e: " .. e, WHERE.CENTER, 3)
		if s ~= nil then
			local txt = string.sub(_txt, 1, s - 1)
			_txt = string.sub(_txt, e + 1)
--			paintAnInfoBoxAndWait("Teil: " .. txt, WHERE.CENTER, 3)
			local widthX = N:getRenderWidth(useDynFont, fontLeftMenu2, txt)
			if (widthX > maxLen) then
				while N:getRenderWidth(useDynFont, fontLeftMenu2, txt) > maxLen-8 do
					txt = string.sub(txt, 1 , -2)
				end
				txt = txt .. "..."
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
	local P = require 'posix'
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
	local P = require 'posix'
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
	return ib
end -- function paintTopRightInfoBox

function paintTopRightInfoBoxAndWait(txt, sec)
	local box = paintTopRightInfoBox(txt)
	local P = require 'posix'
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
	ret['software']	= softwareSig
	if (pluginVersionBeta == 0) then
		ret['isBeta'] = false
	else
		ret['isBeta'] = true
	end
	ret['vBeta']	= pluginVersionBeta
	ret['vMajor']	= pluginVersionMajor
	ret['vMinor']	= pluginVersionMinor
	ret['mode']	= mode		

	return ret
end -- function getSendDataHead

function runACommand(cmd)
	local handle = io.popen(cmd)
	local result = handle:read("*a")
	handle:close()
	return result
end -- function runACommand
