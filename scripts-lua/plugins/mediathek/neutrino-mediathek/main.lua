function showErrorDialog(text)
	messagebox.exec{title=pluginName, text=text, buttons={'ok'}}
end

function ensurePrivacyConsent()
	if conf.privacyAccepted == 'on' then
		return true
	end
	local notice_text = string.format(l.privacyNotice, tostring(url_new or url_new_default))
	local ret = messagebox.exec{
		title = pluginName,
		text = notice_text,
		icon = "info",
		buttons = { "yes", "no" },
		default = "no"
	}
	if ret == "yes" then
		conf.privacyAccepted = 'on'
		return true
	end
	messagebox.exec{title=pluginName, text=l.privacyDeclined, buttons={'ok'}}
	forcePluginExit = true
	return false
end

function getVersionInfo()
	local cacheKey = url_new .. actionCmd_versionInfo
	local j_table = loadJsonResponse(cacheKey, buildApiUrls(actionCmd_versionInfo), queryMode_Info, nil)
	if not j_table then
		return false
	end

	local vdate  = os.date(l.formatDate .. ' / ' .. l.formatTime, j_table.entry[1].vdate)
	local mvdate = os.date(l.formatDate .. ' / ' .. l.formatTime, j_table.entry[1].mvdate)
	local apiUrl = url_new or url_new_default or ""
	local vInfo = string.format(l.formatVersion, pluginVersion, j_table.entry[1].version, vdate, j_table.entry[1].progname, j_table.entry[1].progversion,
			j_table.entry[1].api, j_table.entry[1].apiversion, apiUrl, j_table.entry[1].mvversion, j_table.entry[1].mventrys, mvdate)
	local recStats = getLocalRecordingsStats and getLocalRecordingsStats()
	if recStats then
		vInfo = vInfo .. '\n \n' .. l.localRecordingsInfoHeader .. '\n'
		if not recStats.enabled then
			vInfo = vInfo .. l.localRecordingsInfoDisabled
		else
			vInfo = vInfo .. string.format(l.localRecordingsInfoPath, recStats.path ~= '' and recStats.path or '-')
			vInfo = vInfo .. '\n' .. string.format(l.localRecordingsInfoActive, recStats.activeEntries or 0)
			if recStats.cacheSize and recStats.cacheSize > 0 then
				vInfo = vInfo .. '\n' .. string.format(l.localRecordingsInfoCacheEntries, recStats.cachedEntries or 0)
				vInfo = vInfo .. '\n' .. string.format(l.localRecordingsInfoCachePath, recStats.cachePath or '-', recStats.cacheSizeHuman or '0 B')
				local cacheUpdated = recStats.cacheMtime and os.date(l.formatDate .. ' / ' .. l.formatTime, recStats.cacheMtime) or l.localRecordingsInfoCacheUnknown
				vInfo = vInfo .. '\n' .. string.format(l.localRecordingsInfoCacheUpdated, cacheUpdated)
			else
				vInfo = vInfo .. '\n' .. l.localRecordingsInfoCacheMissing
			end
		end
	end
	if luaRuntimeInfo and luaRuntimeInfo ~= '' then
		vInfo = vInfo .. '\n \n' .. string.format(l.runtimeInfo or 'Lua runtime: %s', luaRuntimeInfo)
	end

	local screenWidth = SCREEN and (SCREEN.END_X - SCREEN.OFF_X) or 720
	local infoWidth = math.max(520, math.floor(screenWidth / 2))
	local infoHeight = math.min(SCREEN and SCREEN.Y_RES - 40 or 2000, math.max(480, math.floor((SCREEN and SCREEN.Y_RES or 576) * 0.75)))
	messagebox.exec{
		title = l.versionHeader .. ' ' .. pluginName,
		text = vInfo,
		buttons = { 'back' },
		width = infoWidth,
		height = infoHeight
	}
end

function paintMainMenu(space, frameColor, textColor, info, count)
	local fontText = fontMainMenu
	local i
	local w1 = 0
	local w2 = 0
	local w = 0
	local iconMetrics = {}

	local labelsLeft = {}
	local labelsRight = {}

	for i=1, count do
		local entry = info[i] or {}
		local icon = resolveIconRef(entry[3])
		local labelLeft = entry[1] or ''
		local labelRight = entry[2] or ''
		labelsLeft[i] = labelLeft
		labelsRight[i] = labelRight
		if icon ~= nil and icon ~= '' then
			local iw, ih = N:GetSize(icon)
			iconMetrics[i] = { icon=icon, w=iw, h=ih }
			if iw > w1 then w1 = iw end
		else
			local wText1 = N:getRenderWidth(useDynFont, fontText, labelLeft)
			if wText1 > w1 then w1 = wText1 end
		end
		local wText2 = N:getRenderWidth(useDynFont, fontText, labelRight)
		if wText2 > w2 then w2 = wText2 end
	end
	local h = N:FontHeight(useDynFont, fontText) + 2*OFFSET.INNER_SMALL
	w = w1 + 2*OFFSET.INNER_MID + w2 + 2*OFFSET.INNER_MID

	local x = (SCREEN.OFF_X + SCREEN.END_X - w) / 2
	local h_tmp = (h + space)
	local h_ges = count * h_tmp
	local y_start = (SCREEN.END_Y - h_ges) / 2
	if (bgTransp == true) then
		y_start = (SCREEN.END_Y - h_ges) / 6
	end
	x = math.floor(x)
	x1 = x + OFFSET.INNER_MID
	x2 = x + OFFSET.INNER_MID + w1 + 2*OFFSET.INNER_MID
	h_tmp = math.floor(h_tmp)
	y_start = math.floor(y_start)

	for i=1, count do
		local labelLeft = labelsLeft[i] or ''
		local labelRight = labelsRight[i] or ''
		local y = y_start + (i-1)*h_tmp
		local bg = 0
		txtC=textColor
		local entryIcon = iconMetrics[i]
		local hasIcon = entryIcon ~= nil

		if ((i == 2) and (conf.enableLivestreams == 'off')) then
			txtC = COL.MENUCONTENTINACTIVE_TEXT
			bg   = COL.MENUCONTENTINACTIVE
		end

		if (labelLeft ~= '' or labelRight ~= '') then
			G.paintSimpleFrame(x, y, w, h, frameColor, bg)
			N:paintVLine(x + w1 + 2*OFFSET.INNER_MID, y, h, frameColor)
			if hasIcon then
				local iconX = x1 + math.floor((w1 - entryIcon.w) / 2)
				local iconY = y + math.floor((h - entryIcon.h) / 2)
				N:DisplayImage(entryIcon.icon, iconX, iconY, entryIcon.w, entryIcon.h, 1)
			else
				N:RenderString(useDynFont, fontText, labelLeft, x1, y + h, txtC, w1, h, 1)
			end
			N:RenderString(useDynFont, fontText, labelRight, x2, y + h, txtC, w2, h, 0)
		end
	end
end

function paintMainWindow(menuOnly, win)
	if (not win) then win = h_mainWindow end
	if not win then return end
	if (menuOnly == false) then
		win:paint{do_save_bg=true}
	end
	paintMainMenu(OFFSET.INNER_SMALL, COL.FRAME_PLUS_0, COL.MENUCONTENT_TEXT, mainMenuEntry, #mainMenuEntry)
end

function hideMainWindow()
	if h_mainWindow then
		h_mainWindow:hide()
	end
	N:PaintBox(0, 0, SCREEN.X_RES, SCREEN.Y_RES, COL.BACKGROUND)
end

function newMainWindow()
	local x = SCREEN.OFF_X
	local y = SCREEN.OFF_Y
	local w = SCREEN.END_X - x
	local h = SCREEN.END_Y - y

	bgTransp = true
	local showHeader = true
	local bgCol = COL.MENUCONTENT_PLUS_0
	if (bgTransp == true) then
		showHeader = false
--		bgCol = bit32.band(0x00FFFFFF, bgCol)
--		bgCol = bit32.bor(0x60000000, bgCol)
		bgCol = (0x60000000)
	end

	local ret = cwindow.new{x=x, y=y, dx=w, dy=h, color_body=bgCol, show_header=showHeader, show_footer=false, name=pluginName .. ' - v' .. pluginVersion, icon=pluginIcon}
	if startProgress then
		startProgress:close()
		startProgress = nil
	end
	paintMainWindow(false, ret)
	mainScreen = saveFullScreen()
	return ret
end

function mainWindow()

	h_mainWindow = newMainWindow()

	repeat
		local msg, data = N:GetInput(500)
		-- start
		if (msg == RC.ok) then
			if startMediathek(false) then
				restoreFullScreen(mainScreen, false)
			end
		end
		if (msg == RC.green) then
			if startMediathek(true) then
				restoreFullScreen(mainScreen, false)
			end
		end
		-- livestreams
		if ((msg == RC.sat) or (msg == RC.red)) then
			if (conf.enableLivestreams == 'on') then
				livestreamMenu()
			end
		end
		-- settings
		if (msg == RC.setup) then
			configMenu()
		end
		-- info
		if (msg == RC.info) then
			getVersionInfo()
		end
		-- exit plugin
		checkKillKey(msg)
	until msg == RC.home or msg == RC.stop or forcePluginExit == true
end

muteStatusNeutrino	= false
muteStatusPlugin	= false
volumeNeutrino		= 0
local startProgress	= nil

function beforeStart()
	V:zapitStopPlayBack()

	muteStatusNeutrino = M:isMuted()
	volumeNeutrino = M:getVolume()
	M:AudioMute(false, false)
	M:enableMuteIcon(false)

	V:ShowPicture(backgroundImage)

--	timerThread = threads.new(_timerThread)
--	timerThread:start()
end

function afterStop()
	hideMainWindow()
	V:channelRezap()

	local rev, box = M:GetRevision()
	if rev == 1 and box == 'Spark' then V:StopPicture() end

	M:enableMuteIcon(true)
	M:AudioMute(muteStatusNeutrino, true)
	M:setVolume(volumeNeutrino)

	V:StopPicture()

--	if timerThread ~= nil then
--		local ok = timerThread:cancel()
--		H.printf("timerThread cancel ok: %s", tostring(ok))
--		ok = thread:join()
--		H.printf("timerThread join ok: %s", tostring(ok))
--	end
end

--	local _timerThread = [[
--		while (true) do
--		end
--		return 1
--	]]

function main()
	initLocale()
	initVars()
	beforeStart()
	_loadConfig()
	if not ensurePrivacyConsent() then
		_saveConfig()
		afterStop()
		return
	end
	setFonts()
	startProgress = createProgressWindow(l.startPluginInfoMsg)
	if startProgress then
		startProgress:update(0, 3, l.startPluginInfoMsg)
	end
	createImages()
	if startProgress then
		startProgress:update(1, 3, l.readDataInfoMsg)
		startProgress:close()
		startProgress = nil
	end
	mainWindow()
	_saveConfig()
	afterStop()
end

main()
