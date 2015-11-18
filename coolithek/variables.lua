
pluginVersion	= "0.1"
pluginName	= "Coolithek"

-- debug print for wget when 'wgetQuiet' not defined
local wgetQuiet		= 1

-- for testing only
-- use local server when 'useLocalServer' defined and flag file exist
--local useLocalServer	= 1

if (helpers.fileExist(pluginScriptPath .. "/.local") == true and useLocalServer ~= nil) then
	url_base = "http://192.168.0.100/mediathek";
else
	url_base = "http://mediathek.slknet.de";
end

user_agent 		= "\"" .. pluginName .. " plugin v" .. pluginVersion .. " for NeutrinoHD\"";
if (wgetQuiet ~= nil) then
	wget_cmd = "wget -q -U " .. user_agent .. " -O ";
else
	wget_cmd = "wget -U " .. user_agent .. " -O ";
end

url_versionInfo		= url_base .. "/?action=getVersionInfo";
url_channelInfo		= url_base .. "/?action=getChannelInfo";

url_listChannels1a	= url_base .. "/?action=listVideo&channel=";
url_listChannels1b	= "&mode=weekly";

url_livestream		= url_base .. "/?action=listLivestream";

jsonData		= pluginTmpPath .. "/mediathek_data.txt";
pluginIcon		= "multimedia";
backgroundImage		= "";
videoTable		= {};
h_mainWindow		= nil;
useFixFont		= true
fontID_MainMenu		= 0
fontID_MiniInfo		= 1
mainScreen		= 0


-- ################################################

function fillMainMenuEntry(e1, e2)
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
