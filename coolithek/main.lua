
function getVersionInfo()
	local s = getJsonData(url_base .. "/?" .. actionCmd_versionInfo);
	local j_table = decodeJson(s);
	if checkJsonError(j_table) == false then return false end

	local vdate  = os.date("%d.%m.%Y / %H:%M:%S", j_table.entry[1].vdate);
	local mvdate = os.date("%d.%m.%Y / %H:%M:%S", j_table.entry[1].mvdate);
	local msg = string.format("Plugin v%s\n \n" ..
			"Datenbank\n" ..
			"Version: %s (Update %s)\n \n" ..
			"Datenbank MediathekView:\n" ..
			"%s\n" ..
			"%d Einträge (Stand vom %s)", 
			pluginVersion,
			j_table.entry[1].version, vdate,
			j_table.entry[1].mvversion,
			j_table.entry[1].mventrys, mvdate);

	messagebox.exec{title="Versionsinfo " .. pluginName, text=msg, buttons={ "ok" } };
end

function paintMainMenu(frame, frameColor, textColor, info, count)
	local fontText = fontMainMenu
	local i
	local w1 = 0
	local w = 0
	for i = 1, count do
		local wText1 = n:getRenderWidth(useDynFont, fontText, info[i][1])
		if wText1 > w1 then w1 = wText1 end
		local wText2 = n:getRenderWidth(useDynFont, fontText, info[i][2])
		if wText2 > w then w = wText2 end
	end
	local h = n:getRenderWidth(useDynFont, fontText, "222")
	w1 = w1+10
	w  = w+w1*2

	local x = (SCREEN.END_X - w) / 2
	local h_tmp = (h + 3*frame)
	local h_ges = count * h_tmp
	local y_start = (SCREEN.END_Y - h_ges) / 2
	if (bgTransp == true) then
		y_start = (SCREEN.END_Y - h_ges) / 6
	end
	for i = 1, count do
		local y = y_start + (i-1)*h_tmp
		local bg = 0
		txtC=textColor
		if ((i == 2) and (conf.enableLivestreams == "off")) then
			-- livestreams
			txtC = COL.MENUCONTENTINACTIVE_TEXT
			bg   = COL.MENUCONTENTINACTIVE
		end

		if info[i][1] == "" and info[i][2] == "" then
			goto continue
		end

		gui.paintSimpleFrame(x, y, w, h, frameColor, bg)
		n:paintVLine(x+w1, y, h, frameColor)
		n:RenderString(useDynFont, fontText, info[i][1], x, y+h, txtC, w1, h, 1)
		n:RenderString(useDynFont, fontText, info[i][2], x+w1+w1/4, y+h, txtC, w-w1, h, 0)

		::continue::
	end
end

function paintMainWindow(menuOnly, win)
	if (not win) then win = h_mainWindow end
	if (menuOnly == false) then
		win:paint{do_save_bg=true}
	end
	paintMainMenu(1, COL.MENUCONTENT_TEXT, COL.MENUCONTENT_TEXT, mainMenuEntry, #mainMenuEntry)
end

function hideMainWindow()
	h_mainWindow:hide()
	n:PaintBox(0, 0, SCREEN.X_RES, SCREEN.Y_RES, COL.BACKGROUND)

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
		bgCol = (0x6000253E)
	end

	local ret = cwindow.new{x=x, y=y, dx=w, dy=h, color_body=bgCol, show_header=showHeader, show_footer=false, name=pluginName .. " - v" .. pluginVersion, icon=pluginIcon};
	gui.hideInfoBox(startBox)
	paintMainWindow(false, ret)
	mainScreen = saveFullScreen()
	return ret
end

function mainWindow()

	os.execute("pzapit -mute")

	h_mainWindow = newMainWindow()

	repeat
		local msg, data = n:GetInput(500)
		-- start
		if (msg == RC.ok) then
			startMediathek()
			restoreFullScreen(mainScreen, false)
		end
		-- livestreams
		if (msg == RC.sat) then
			if (conf.enableLivestreams == "on") then
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
		-- ;)
		if (msg == RC.www) then
		end
		menuRet = msg
	until msg == RC.home;

	n:StopPicture()
	os.execute("pzapit -rz")
	os.execute("pzapit -unmute")
end

-- ###########################################################################################

initLocale();
initVars();
n:ShowPicture(backgroundImage)
loadConfig();
setFonts();
startBox = paintMiniInfoBox("Starte Plugin");
createImages();
mainWindow();
_saveConfig(true);

-- ###########################################################################################
