NEUTRINO_MEDIATHEK_API_OVERRIDE = nil

function initLocale()
	l={}
	l.key = {}

	local language_default = 'english'
	local language = N:GetLanguage()
	if language == nil or language == '' or (H.fileExist(pluginScriptPath .. '/locale/' .. language .. '.lua') == false) then
		language = language_default
	end

	dofile(pluginScriptPath .. '/locale/' .. language .. '.lua')
end

local function detectDefaultApiBase()
	local env = os.getenv('NEUTRINO_MEDIATHEK_API')
	if env ~= nil and env ~= '' then
		NEUTRINO_MEDIATHEK_API_OVERRIDE = env
		H.printf("[neutrino-mediathek] NEUTRINO_MEDIATHEK_API=%s", env)
		return env
	end
	NEUTRINO_MEDIATHEK_API_OVERRIDE = nil
	local fallback = 'https://mt.api.tuxbox-neutrino.org/mt-api'
	H.printf("[neutrino-mediathek] NEUTRINO_MEDIATHEK_API not set, fallback to %s", fallback)
	return fallback
end

function iconRef(name)
	return { __icon_name = name }
end

function initVars()
	local function trim(str)
		return (str:gsub('^%s+', ''):gsub('%s+$', ''))
	end

	local function readVersionFile(path)
		local fh = io.open(path, 'r')
		if not fh then return nil end
		local line = fh:read('*l')
		fh:close()
		if line and #line > 0 then
			return trim(line)
		end
		return nil
	end

	local function readVersionFromGit()
		local cmd = string.format('cd %q && git describe --tags --always --dirty 2>/dev/null', pluginScriptPath)
		local handle = io.popen(cmd)
		if not handle then return nil end
		local line = handle:read('*l')
		handle:close()
		if line and #line > 0 then
			return trim(line)
		end
		return nil
	end

	local rawVersion = readVersionFile(pluginScriptPath .. '/VERSION') or readVersionFromGit() or '1.0.0-dev'
	local major, minor, patch, suffix = rawVersion:match('^v?(%d+)%.(%d+)%.(%d+)(.*)$')
	if not major then
		major, minor, patch, suffix = '1', '0', '0', '-dev'
	end
	pluginVersionMajor	= tonumber(major) or 1
	pluginVersionMinor	= tonumber(minor) or 0
	pluginVersionPatch	= tonumber(patch) or 0

	suffix = suffix or ''
	local displaySuffix = ''
	local devSuffix = ''
	local patchLabel, rest = suffix:match('^(-?p?%d+)(.*)$')
	if patchLabel then
		local tagPatch = tonumber(patchLabel:match('(%d+)'))
		if tagPatch ~= nil then
			pluginVersionPatch = tagPatch
		end
		displaySuffix = patchLabel
		if rest ~= nil and rest ~= '' then
			devSuffix = '-dev'
		end
	else
		displaySuffix = suffix
	end

	if displaySuffix:lower():find('beta', 1, true) then
		pluginVersionBeta = 1
	else
		pluginVersionBeta = 0
	end
	pluginVersion = string.format('%d.%d.%d%s%s', pluginVersionMajor, pluginVersionMinor, pluginVersionPatch, displaySuffix, devSuffix)

	pluginName	= 'Neutrino Mediathek'


	noCacheFiles	= false
	dlDebug		= true

	forcePluginExit	= false
--	Curl		= nil

	url_base_b	= 'http://mediathek.slknet.de'
	url_base_4	= 'http://mediathek4.slknet.de'
	url_base	= url_base_b
	url_new_default	= detectDefaultApiBase()
	url_new		= url_new_default

	conf		= {}
	conf.livestream	= {}
	config		= configfile.new()
	user_agent	= '"Mozilla/5.0 (compatible; ' .. pluginName .. ' plugin v' .. pluginVersion .. ')"'
	user_agent2	= '"Mozilla/5.0 (Windows NT 10.0; WOW64; rv:43.0) Gecko/20100101 Firefox/43.0"'
	user_agent3	= '"Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Mobile Safari/537.36"'
	user_agent4	= '"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_12_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.100 Safari/537.36"'
	user_agent5	= '"Mozilla/5.0 (iPhone; CPU iPhone OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B143 Safari/601.1"'
	user_agent6	= '"Mozilla/5.0 (iPad; CPU OS 9_1 like Mac OS X) AppleWebKit/601.1.46 (KHTML, like Gecko) Version/9.0 Mobile/13B143 Safari/601.1"'

	actionCmd_API		= '/api'
	actionCmd_versionInfo	= actionCmd_API .. '/info'
	actionCmd_livestream	= actionCmd_API .. '/listLivestream'
	actionCmd_listChannels	= actionCmd_API .. '/listChannels'
	actionCmd_sendPostData	= '/api.html'

	jsonData		= pluginTmpPath .. '/mediathek_data.txt'
	m3u8Data		= pluginTmpPath .. '/mediathek_data.m3u8'
	pluginIcon		= 'multimedia'
	backgroundImage		= pluginScriptPath .. '/background.jpg'
	videoTable		= {}
	h_mainWindow	= nil
	geoIcon		= nil

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

	softwareSig = 'Neutrino Mediathek'
	local rev
	rev, hardware = M:GetRevision()
	if (hardware ~= nil) then
		if (hardware == 'Coolstream') then
			softwareSig = softwareSig .. ' - CST'
		end
	end

	local function fillMainMenuEntry(e1, e2, icon)
		local i = #mainMenuEntry+1
		mainMenuEntry[i]	= {}
		mainMenuEntry[i][1]	= e1
		mainMenuEntry[i][2]	= e2
		mainMenuEntry[i][3]	= icon
	end

	mainMenuEntry = {}
	fillMainMenuEntry(l.key.ok,	l.startMediathek,	iconRef('iconOk'))
	fillMainMenuEntry(l.key.red,	l.startLivestreams,	iconRef('btnRed'))
	fillMainMenuEntry(l.key.menu,	l.settings,		iconRef('iconMenu'))
	fillMainMenuEntry(l.key.info,	l.versioninfo,	iconRef('iconInfo'))
	fillMainMenuEntry(l.empty,	l.empty,		nil)
	fillMainMenuEntry(l.key.exit,	l.exitProgram,	iconRef('iconExit'))

	if (H.fileExist(pluginScriptPath .. '/local.lua') == true) then
		-- locale settings for testing
		dofile(pluginScriptPath .. '/local.lua')
	end
end
