function initLocale()
	l={}
	l.key = {}

	local language_default = 'english'	-- no NLS
	local language = N:GetLanguage()
	if language == nil or language == '' or (H.fileExist(pluginScriptPath .. '/locale/' .. language .. '.lua') == false) then	-- no NLS
		language = language_default
	end

	dofile(pluginScriptPath .. '/locale/' .. language .. '.lua')	-- no NLS
end -- function initLocale

function initVars()
	pluginVersionMajor	= 0
	pluginVersionMinor	= 4
	pluginVersionBeta	= 3
	if (pluginVersionBeta == 0) then
		pvbTmp = ''
	else
		pvbTmp = ' beta ' .. tostring(pluginVersionBeta)	-- no NLS
	end
	pluginVersion	= tostring(pluginVersionMajor) .. '.' .. tostring(pluginVersionMinor) .. pvbTmp	-- no NLS

	pluginName	= 'Neutrino Mediathek'	-- no NLS


	noCacheFiles	= false
	dlDebug		= true

	forcePluginExit	= false
--	Curl		= nil

	url_base_b	= 'http://mediathek.slknet.de'	-- no NLS
	url_base_4	= 'http://mediathek4.slknet.de'	-- no NLS
	url_base	= url_base_b
	url_new		= 'https://api.coolithek.slknet.de'	-- no NLS

	conf		= {}
	conf.livestream	= {}
	config		= configfile.new()
	user_agent	= '"Mozilla/5.0 (compatible; ' .. pluginName .. ' plugin v' .. pluginVersion .. ')"'	-- no NLS
	user_agent2	= '"Mozilla/5.0 (Windows NT 10.0; WOW64; rv:43.0) Gecko/20100101 Firefox/43.0"'	-- no NLS
	user_agent3	= '"Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Mobile Safari/537.36"'	-- no NLS
	user_agent4	= '"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.100 Safari/537.36"'	-- no NLS
	user_agent5	= '"Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B143 Safari/601.1"'	-- no NLS
	user_agent6	= '"Mozilla/5.0 (iPad; CPU OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B143 Safari/601.1"'	-- no NLS

	actionCmd_API		= '/api'					-- no NLS
	actionCmd_versionInfo	= actionCmd_API ..	'/info'			-- no NLS
	actionCmd_livestream	= actionCmd_API ..	'/listLivestream'	-- no NLS
	actionCmd_listChannels	= actionCmd_API ..	'/listChannels'		-- no NLS
	actionCmd_sendPostData	=			'/api.html'		-- no NLS

	jsonData		= pluginTmpPath ..	'/mediathek_data.txt'	-- no NLS
	m3u8Data		= pluginTmpPath ..	'/mediathek_data.m3u8'	-- no NLS
	pluginIcon		=			'multimedia'		-- no NLS
	backgroundImage		= pluginScriptPath .. '/background.jpg'		-- no NLS
	videoTable		= {}
	h_mainWindow	= nil

	fontMainMenu	= nil
	fontMiniInfo	= nil
	fontLeftMenu1	= nil
	fontLeftMenu2	= nil

	h_mtWindow	= nil
	mtScreen	= nil

	WHERE		= {}
	WHERE.TOPRIGHT	= 3
	WHERE.CENTER	= 5

	mainScreen	= 0
	moviePlayed	= false

	MINUTE	= 60
	HOUR	= 3600
	DAY	= HOUR*24
	WEEK	= DAY*7

	queryMode_None			= 0
	queryMode_Info			= 1
	queryMode_listChannels		= 2
	queryMode_listLivestreams	= 3
	queryMode_beginPOSTmode		= 4
	queryMode_listVideos		= 5

	timeMode_normal	= 1
	timeMode_future	= 2

	softwareSig = 'Neutrino Mediathek'	-- no NLS
	local rev
	rev, hardware = M:GetRevision()
	if (hardware ~= nil) then
		if (hardware == 'Coolstream') then	-- no NLS
			softwareSig	= softwareSig .. ' - CST'	-- no NLS
		end
	end -- function initVars

	local function fillMainMenuEntry(e1, e2)
		local i = #mainMenuEntry+1
		mainMenuEntry[i]	= {}
		mainMenuEntry[i][1]	= e1
		mainMenuEntry[i][2]	= e2
	end -- function fillMainMenuEntry

	mainMenuEntry = {}
	fillMainMenuEntry(l.key.ok,	l.startMediathek)
	fillMainMenuEntry(l.key.red,	l.startLivestreams)
	fillMainMenuEntry(l.key.menu,	l.settings)
	fillMainMenuEntry(l.key.info,	l.versioninfo)
	fillMainMenuEntry(l.empty,	l.empty)
	fillMainMenuEntry(l.key.exit,	l.exitProgram)

	if (H.fileExist(pluginScriptPath .. '/local.lua') == true) then	-- no NLS
		-- locale settings for testing
		dofile(pluginScriptPath .. '/local.lua')	-- no NLS
	end
end
