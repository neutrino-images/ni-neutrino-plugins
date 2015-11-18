
function getVersionInfo()
	local s = getJsonData(url_versionInfo);
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
		local wText1 = n:getRenderWidth(useFixFont, fontText, info[i][1])
		if wText1 > w1 then w1 = wText1 end
		local wText2 = n:getRenderWidth(useFixFont, fontText, info[i][2])
		if wText2 > w then w = wText2 end
	end
	local h = n:getRenderWidth(useFixFont, fontText, "222")
	w1 = w1+10
	w  = w+w1*2

	local x = (SCREEN.END_X - w) / 2
	local h_tmp = (h + 3*frame)
	local h_ges = count * h_tmp
	local y_start = (SCREEN.END_Y - h_ges) / 2
	for i = 1, count do
		local y = y_start + (i-1)*h_tmp
		gui.paintFrame(x, y, w, h, frame, frameColor, 0)
		n:PaintBox(x+w1, y, frame, h, frameColor)
		
		n:RenderString(useFixFont, fontText, info[i][1], x, y+h, textColor, w1, h, 1)
		n:RenderString(useFixFont, fontText, info[i][2], x+w1+w1/4, y+h, textColor, w-w1, h, 0)
		
	end
end

function paintMainWindow()
	h_mainWindow:paint{do_save_bg=true}
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
	h_mainWindow = cwindow.new{x=x, y=y, dx=w, dy=h, name=pluginName .. " - v" .. pluginVersion, icon=pluginIcon};
	paintMainWindow()
	mainScreen = saveFullScreen()
	return h_mainWindow;
end

function mainWindow()

	os.execute("pzapit -mute")
	n:setBlank(true)

	h_mainWindow = newMainWindow()

	repeat
		local msg, data = n:GetInput(500)
		-- start
		if (msg == RC.ok) then
		end
		-- livestreams
		if (msg == RC.sat) then
			getLivestreams()
		end
		-- settings
		if (msg == RC.setup) then
			hideMainWindow()
		end
		-- info
		if (msg == RC.info) then
			getVersionInfo()
		end
		-- ;)
		if (msg == RC.www) then
			os.execute("pzapit -esb;pzapit -lsb;pzapit -rz")
			posix.sleep(5)
			msg = RC.home
		end
		ret = msg
	until msg == RC.home;

	n:StopPicture()
	os.execute("pzapit -rz")
	os.execute("pzapit -unmute")
end

-- ###########################################################################################

setFonts();
mainWindow();

-- ###########################################################################################
