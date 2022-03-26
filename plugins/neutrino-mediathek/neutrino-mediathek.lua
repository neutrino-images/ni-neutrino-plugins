------------------------------------------
-- Neutrino Plugin 'Neutrino Mediathek' --
------------------------------------------
-- First version:	long time ago		Author: Most likely several but unknown to me; Jacek
--			Base functionality based on data from mediathek.slknet.de server
-- v 0.4 beta 1:	2020-03-26			Author: Roland Oberle
--			Added search for Titles and Themes (slow and dirty)
-- v 0.4 beta 2:	2020-04-01			Author: Roland Oberle
--			Error corrections and added download capabilities
-- v 0.4 beta 3:	2020-04-05			Author: Roland Oberle
--			Error corrections and .xml generation and background cleaning
--
N = neutrino(0, 0, SCREEN.X_RES, SCREEN.Y_RES)
-- check lua api version
local req_major = 1
local req_minor = 78
if ((APIVERSION.MAJOR < req_major) or (APIVERSION.MAJOR == req_major and APIVERSION.MINOR < req_minor)) then
	N:checkVersion(req_major, req_minor)
	do return end
end

function loadLuaLib(lib, noerror)
	local status, data = pcall(require, lib)
	if noerror == true then
		if status == true then return data
		else return nil end
	end
	if status == true then return data
	else
		error('Lua library  not found: "' .. lib .. '[.so|.lua]"')
	end
end

V	= video.new()
M	= misc.new()
FH	= filehelpers.new()
C	= curl.new()
J	= loadLuaLib('json')
G	= loadLuaLib('n_gui')
H	= loadLuaLib('n_helpers')

-- define global paths
local CONF_PATH = "/var/tuxbox/config/"
if DIR and DIR.CONFIGDIR then
	CONF_PATH = DIR.CONFIGDIR .. '/'
end

pluginScriptPath = H.scriptPath() .. '/' .. H.scriptBase()
pluginTmpPath    = '/tmp/' .. H.scriptBase()
confFile         = CONF_PATH .. H.scriptBase() .. '.conf'
FH:rmdir(pluginTmpPath)
FH:mkdir(pluginTmpPath)

-- include lua files
dofile(pluginScriptPath .. '/variables.lua')
dofile(pluginScriptPath .. '/functions.lua')
dofile(pluginScriptPath .. '/images.lua')
dofile(pluginScriptPath .. '/json_decode.lua')
dofile(pluginScriptPath .. '/config.lua')
dofile(pluginScriptPath .. '/parse_m3u8.lua')
dofile(pluginScriptPath .. '/livestream.lua')
dofile(pluginScriptPath .. '/mediathek.lua')
dofile(pluginScriptPath .. '/mediathek_leftMenu.lua')
dofile(pluginScriptPath .. '/mediathek_movieInfo.lua')
dofile(pluginScriptPath .. '/main.lua')
