
function initVars()
	pluginVersion	= "0.1"
	pluginName	= "Coolithek"

	noCacheFiles	= false

-- 	debug print for wget when 'wgetQuiet' not defined
	local wgetQuiet		= 1

-- 	for testing only
-- 	use local server when 'useLocalServer' defined and flag file exist
--	local useLocalServer	= 1

	if (helpers.fileExist(pluginScriptPath .. "/.local") == true and useLocalServer ~= nil) then
		url_base = "http://192.168.0.100/mediathek";
	else
		url_base = "http://mediathek.slknet.de";
	end

	conf			= {}
	conf.livestream		= {}
	confChanged 		= 0
	config			= configfile.new()
--	user_agent 		= "\"Mozilla/5.0 (iPad; U; CPU OS 4_3_3 like Mac OS X; en-us) AppleWebKit/533.17.9 (KHTML, like Gecko) Version/5.0.2 Mobile/8J2 Safari/6533.18.5\"";
	user_agent 		= "\"Mozilla/5.0 (compatible; " .. pluginName .. " plugin v" .. pluginVersion .. " for NeutrinoHD)\"";
	if (wgetQuiet ~= nil) then
		wget_cmd = "wget -q -U " .. user_agent .. " -O ";
	else
		wget_cmd = "wget -U " .. user_agent .. " -O ";
	end

	url_versionInfo		= url_base .. "/?action=getVersionInfo";
	url_livestream		= url_base .. "/?action=listLivestream";

--	url_channelInfo		= url_base .. "/?action=getChannelInfo";
--	url_listChannels1a	= url_base .. "/?action=listVideo&channel=";
--	url_listChannels1b	= "&mode=weekly";

	jsonData		= pluginTmpPath .. "/mediathek_data.txt";
	m3u8Data		= pluginTmpPath .. "/mediathek_data.m3u8";
	pluginIcon		= "multimedia";
	backgroundImage		= "";
	videoTable		= {};
	h_mainWindow		= nil;
	useFixFont		= true
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
end
