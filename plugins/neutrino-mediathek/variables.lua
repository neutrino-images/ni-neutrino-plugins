
function initLocale()
	l={}
	l.key = {}

	local language_default = "english"
	local language = N:GetLanguage()
	if language == nil or language == "" or (H.fileExist(pluginScriptPath .. "/locale/" .. language .. ".lua") == false) then
		language = language_default
	end

	dofile(pluginScriptPath .. "/locale/" .. language .. ".lua");
end

function initVars()

	pluginVersionMajor	= 0
	pluginVersionMinor	= 3
	pluginVersionBeta	= 2
	if (pluginVersionBeta == 0) then
		pvbTmp = ""
	else
		pvbTmp = " beta " .. tostring(pluginVersionBeta)
	end
	pluginVersion		= tostring(pluginVersionMajor) .. "." .. tostring(pluginVersionMinor) .. pvbTmp

	pluginName		= "Neutrino Mediathek"

	noCacheFiles		= false
	dlDebug			= false

	forcePluginExit		= false
--	Curl			= nil

	url_base_b		= "http://mediathek.slknet.de"
	url_base_4		= "http://mediathek4.slknet.de"
	url_base		= url_base_b
	url_new			= "https://api.coolithek.slknet.de"

	conf			= {}
	conf.livestream		= {}
	config			= configfile.new()
--	user_agent		= "\"Mozilla/5.0 (compatible; " .. pluginName .. " plugin v" .. pluginVersion .. " for NeutrinoHD)\"";
	user_agent		= "\"Mozilla/5.0 (compatible; " .. pluginName .. " plugin v" .. pluginVersion .. ")\"";
	user_agent2		= "\"Mozilla/5.0 (Windows NT 10.0; WOW64; rv:43.0) Gecko/20100101 Firefox/43.0\""
	user_agent3		= "\"Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Mobile Safari/537.36\""
	user_agent4		= "\"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.100 Safari/537.36\""
	user_agent5		= "\"Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B143 Safari/601.1\""
	user_agent6		= "\"Mozilla/5.0 (iPad; CPU OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B143 Safari/601.1\""

	actionCmd_API		= "/api"
	actionCmd_versionInfo	= actionCmd_API .. "/info"
	actionCmd_livestream	= actionCmd_API .. "/listLivestream"
	actionCmd_listChannels	= actionCmd_API .. "/listChannels"
	actionCmd_sendPostData	= "/api.html"

	jsonData		= pluginTmpPath .. "/mediathek_data.txt";
	m3u8Data		= pluginTmpPath .. "/mediathek_data.m3u8";
	pluginIcon		= "multimedia";
	backgroundImage		= pluginScriptPath .. "/background.jpg";
	videoTable		= {};
	h_mainWindow		= nil;

	fontMainMenu		= nil;
	fontMiniInfo		= nil;
	fontLeftMenu1		= nil;
	fontLeftMenu2		= nil;

	h_mtWindow		= nil
	mtScreen		= nil

	mainScreen		= 0
	moviePlayed		= false

	MINUTE			= 60
	HOUR			= 3600
	DAY			= HOUR*24
	WEEK			= DAY*7

	queryMode_None			= 0
	queryMode_Info			= 1
	queryMode_listChannels		= 2
	queryMode_listLivestreams	= 3
	queryMode_beginPOSTmode		= 4
	queryMode_listVideos		= 5

	timeMode_normal			= 1
	timeMode_future			= 2

	softwareSig			= 'Neutrino Mediathek'
	local rev
	rev, hardware = M:GetRevision()
	if (hardware ~= nil) then
		if (hardware == "Coolstream") then
			softwareSig	= softwareSig .. ' - CST'
		end
	end

-- ################################################

	local function fillMainMenuEntry(e1, e2)
		local i = #mainMenuEntry+1
		mainMenuEntry[i] 	= {}
		mainMenuEntry[i][1]	= e1
		mainMenuEntry[i][2]	= e2
	end

	mainMenuEntry = {}
	fillMainMenuEntry(l.key.ok,	l.start_mediathek)
	fillMainMenuEntry(l.key.red,	l.start_livestreams)
	fillMainMenuEntry(l.key.menu,	l.settings)
	fillMainMenuEntry(l.key.info,	l.versioninfo)
	fillMainMenuEntry(l.empty,	l.empty)
	fillMainMenuEntry(l.key.exit,	l.exit_program)

	if (H.fileExist(pluginScriptPath .. "/local.lua") == true) then
		-- locale settings for testing
		dofile(pluginScriptPath .. "/local.lua");
	end
end
