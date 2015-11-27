
function initVars()
	pluginVersion	= "0.2beta"
	pluginName	= "Coolithek"

	noCacheFiles	= false

-- 	debug print for wget when 'wgetQuiet' not defined
	local wgetQuiet		= 1

	url_base		= "http://mediathek.slknet.de";

	conf			= {}
	conf.livestream		= {}
	confChanged 		= 0
	config			= configfile.new()
	user_agent 		= "\"Mozilla/5.0 (compatible; " .. pluginName .. " plugin v" .. pluginVersion .. " for NeutrinoHD)\"";
	if (wgetQuiet ~= nil) then
		wget_cmd = "wget -q -U " .. user_agent .. " -O ";
	else
		wget_cmd = "wget -U " .. user_agent .. " -O ";
	end

	actionCmd_versionInfo	= "action=getVersionInfo"
	actionCmd_livestream	= "action=listLivestream"
	actionCmd_listChannels	= "action=listChannels"
	actionCmd_listVideos	= "action=listVideos"

	jsonData		= pluginTmpPath .. "/mediathek_data.txt";
	m3u8Data		= pluginTmpPath .. "/mediathek_data.m3u8";
	pluginIcon		= "multimedia";
	backgroundImage		= "";
	videoTable		= {};
	h_mainWindow		= nil;
	fontID_MainMenu		= 0
	fontID_MiniInfo		= 1
	fontID_LeftMenu1	= 2
	fontID_LeftMenu2	= 3
	mainScreen		= 0

	readData		= "Lese Daten..."
	saveData		= "Einstellungen werden gespeichert..."

	MINUTE			= 60
	HOUR			= 3600
	DAY			= HOUR*24
	WEEK			= DAY*7


-- ################################################

	local function fillMainMenuEntry(e1, e2)
		local i = #mainMenuEntry+1
		mainMenuEntry[i] 	= {}
		mainMenuEntry[i][1]	= e1
		mainMenuEntry[i][2]	= e2
	end

	mainMenuEntry = {}
	fillMainMenuEntry("OK",   "Mediathek starten")
	fillMainMenuEntry("SAT",  "Livestreams")
	fillMainMenuEntry("MENÜ", "Einstellungen")
	fillMainMenuEntry("INFO", "Versionsinfo")
	fillMainMenuEntry("",     "")
	fillMainMenuEntry("EXIT", "Programm beenden")

	if (helpers.fileExist(pluginScriptPath .. "/local.lua") == true) then
		-- locale settings for testing
		dofile(pluginScriptPath .. "/local.lua");
	end
end
