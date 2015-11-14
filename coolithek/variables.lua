
pluginVersion	= "0.1"
pluginName	= "Coolithek"

-- debug print for wget when 'wgetQuiet' not defined
local wgetQuiet		= 1

-- for testing only
-- use local server when 'useLocalServer' defined and flag file exist
local useLocalServer	= 1

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


mainMenuEntry		= {}
local i = 1
mainMenuEntry[i]	= {}
mainMenuEntry[i][1]	= "OK"
mainMenuEntry[i][2]	= "Mediathek starten"
i = i+1
mainMenuEntry[i] 	= {}
mainMenuEntry[i][1]	= "SAT"
mainMenuEntry[i][2]	= "Livestreams"
i = i+1
mainMenuEntry[i] 	= {}
mainMenuEntry[i][1]	= "MENÜ"
mainMenuEntry[i][2]	= "Einstellungen"
i = i+1
mainMenuEntry[i] 	= {}
mainMenuEntry[i][1]	= "INFO"
mainMenuEntry[i][2]	= "Versionsinfo"
i = i+1
mainMenuEntry[i] 	= {}
mainMenuEntry[i][1]	= ""
mainMenuEntry[i][2]	= ""
i = i+1
mainMenuEntry[i] 	= {}
mainMenuEntry[i][1]	= "EXIT"
mainMenuEntry[i][2]	= "Programm beenden"
