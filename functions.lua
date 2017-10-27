
-- Do not change!
useDynFont = true

function checkKillKey(msg)
	if (msg == RC.tv) or (msg == RC.radio) then
		forcePluginExit = true
	elseif (msg == RC.standby) then
		M:postMsg(POSTMSG.STANDBY_ON)
		forcePluginExit = true
	end
end

function killPlugin(id)
	if (id == "standby") then
		M:postMsg(POSTMSG.STANDBY_ON)
	end
	forcePluginExit = true
	menuRet = MENU_RETURN.EXIT_ALL
	return menuRet
end

function addKillKey(menu)
	menu:addKey{directkey=RC.tv,      id="tv",      action="killPlugin"}
	menu:addKey{directkey=RC.radio,   id="radio",   action="killPlugin"}
	menu:addKey{directkey=RC.standby, id="standby", action="killPlugin"}
end

function curlDownload(Url, file, postData, hideBox, _ua, uriDecode)
	return downloadFileInternal(Url, file, hideBox, _ua, postData, uriDecode)
end

function downloadFile(Url, file, hideBox, _ua)
	return downloadFileInternal(Url, file, hideBox, _ua, nil, nil)
end

function downloadFileInternal(Url, file, hideBox, _ua, postData_, uriDecode)
	local ua = user_agent
	if _ua ~= nil then ua = _ua end
	box = paintMiniInfoBox(l.read_data)
	if file ~= "" then os.remove(file) end
	local postData
	if postData_ ~= nil then
		postData = postData_
	else
		postData = ""
	end

	local v4 = false
	if (conf.networkIPV4Only == "on") then
		v4 = true
	end
	local s  = true
	if (conf.networkDlSilent == "on") then
		s  = false
	end
	local v = false
	if (conf.networkDlVerbose == "on") then
		v = true
	end
	
	if (dlDebug == true) then
		H.printf( "\n" ..
				"   remote url: %s\n" ..
				"         file: %s\n" ..
				"     postData: %s\n" ..
				"     ipv4only: %s\n" ..
				"   user_agent: %s\n" ..
				"       silent: %s\n" ..
				"      verbose: %s" ..
				"", Url, tostring(file), C:decodeUri(tostring(postData)), tostring(v4), ua, tostring(s), tostring(v))
	end

	local ret, data;
	if uriDecode == nil then
		if file ~= "" then
			ret, data = C:download{ url=Url, o=file, A=ua, ipv4=v4, s=s, v=v, postfields=postData }
		else
			ret, data = C:download{ url=Url, A=ua, ipv4=v4, s=s, v=v, postfields=postData }
		end
	else
		ret, data = C:download{ url=Url, A=ua, ipv4=v4, s=s, v=v, postfields=postData }
		if (ret == 0) then
			data = C:decodeUri(data)
			if ((file ~= "") and (data ~= nil)) then
				local f = io.open(file, "w+")
				if f ~= nil then
					f:write(data)
					f:close()
					data = ""
				end
			end
		end
	end

	if (hideBox == true) then
		G.hideInfoBox(box)
		box = nil
	end
	if ret == CURL.OK then
		if file ~= "" then
			return box, ret, nil
		else
			return box, ret, data
		end
	else
		return box, ret, data
	end
end

function PlayMovie(title, url, info1, info2, enableMovieInfo)

	local function muteSleep(mute, wait)
		local threadFunc = [[
			local t = ...
			local P = require "posix"
			print(string.format(">>>>>[muteSleep] set AudioMute to %s, wait %d sec", tostring(t._mute), t._wait))
			P.sleep(t._wait)
			M = misc.new()
			M:AudioMute(t._mute, true)
			return 1
		]]
		local mt = threads.new(threadFunc, {_mute=mute, _wait=wait})
		mt:start()
		return mt
	end

	local muteThread;
	if (moviePlayed == false) then
		volumePlugin = M:getVolume()
		muteThread = muteSleep(muteStatusPlugin, 1)
	else
		M:AudioMute(muteStatusPlugin, true)
		M:setVolume(volumePlugin)
	end

	if enableMovieInfo == true then
		V:setInfoFunc("movieInfoMP")
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
end

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
		return N:getRenderWidth(useDynFont, font, str)
	end

	local ret = {}
	local w = checkLen(str, font)
	if ((w <= len) or (len < 20)) then
		ret[1] = str
		return ret
	end

	local words = H.split(str, " ")
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
	local w = N:getRenderWidth(useDynFont, font, str)
	if (w <= len) then
		return str
	else
		local z = "..."
		local wz = N:getRenderWidth(useDynFont, font, z)
		if (len <= 2*wz) then return str end
		str = string.sub(str, 1, #str-2)
		while (w+wz > len) do
			str = string.sub(str, 1, #str-1)
			w = N:getRenderWidth(useDynFont, font, str)
		end
		return str .. z
	end
end

function createCacheFileName(url, ext)
	local d = V:createChannelIDfromUrl(url);
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
		f:write(H.base64Dec(b64Data))
		f:close()
	else
		print("Create image ["..retImg.."] failed.")
		return ""
	end

	return retImg
end

function saveFullScreen()
	return N:saveScreen(0, 0, SCREEN.X_RES, SCREEN.Y_RES);
end

function restoreFullScreen(screen, del)
	N:restoreScreen(0, 0, SCREEN.X_RES, SCREEN.Y_RES, screen, del);
end

function setFonts()
	if (useDynFont == false) then error("Failed to create fonts.") end
	local fontError = 0;
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
		fontLeftMenu2, fontError = N:getDynFont(0, N:scale2Res(26), "", DYNFONT.STYLE_BOLD)
		fontLeftMenu2_h = N:FontHeight(useDynFont, fontLeftMenu2)
	end
end

function paintMiniInfoBox(txt)
	local _w = N:getRenderWidth(useDynFont, fontMiniInfo, txt)
	local _h = N:FontHeight(useDynFont, fontMiniInfo)
	local dx = _w + 40
	local dy = _h
	local x = math.floor(((SCREEN.END_X - SCREEN.OFF_X) - dx) / 2)
	local y = math.floor(((SCREEN.END_Y - SCREEN.OFF_Y) - dy) / 2)
	local ib = G.paintMiniInfoBox("", dx, dy)
	local col_text = COL.MENUCONTENTSELECTED_TEXT
	N:RenderString(useDynFont, fontMiniInfo, txt, x, y+dy, col_text, dx, dy, 1)
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
end
