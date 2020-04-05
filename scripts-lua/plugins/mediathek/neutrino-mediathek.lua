------------------------------------------
-- Neutrino Plugin 'Neutrino Mediathek' --
------------------------------------------
-- First version:	long time ago		Author: Most likely several but unknown to me; Jacek
--				Base functionality based on data from mediathek.slknet.de server
-- v 0.4 beta 1:	2020-03-26			Author: Roland Oberle
--				Added search for Titles and Themes (slow and dirty)
-- v 0.4 beta 2:	2020-04-01			Author: Roland Oberle
--				Error corrections and added download capabilities
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
		error('Lua library  not found: "' .. lib .. '[.so|.lua]"')	-- no NLS 
	end
end -- function loadLuaLib

V	= video.new()
M	= misc.new()
FH	= filehelpers.new()
C	= curl.new()
J	= loadLuaLib('json')		-- no NLS
G	= loadLuaLib('n_gui')		-- no NLS
H	= loadLuaLib('n_helpers')	-- no NLS

-- define global paths
pluginScriptPath = H.scriptPath() .. '/' .. H.scriptBase()	-- no NLS
pluginTmpPath    = '/tmp/' .. H.scriptBase()	-- no NLS
confFile         = '/var/tuxbox/config/' .. H.scriptBase() .. '.conf'	-- no NLS
FH:rmdir(pluginTmpPath)
FH:mkdir(pluginTmpPath)

-- include lua files
dofile(pluginScriptPath .. '/variables.lua')			-- no NLS
dofile(pluginScriptPath .. '/functions.lua')			-- no NLS
dofile(pluginScriptPath .. '/images.lua')				-- no NLS
dofile(pluginScriptPath .. '/json_decode.lua')			-- no NLS
dofile(pluginScriptPath .. '/config.lua')				-- no NLS
dofile(pluginScriptPath .. '/parse_m3u8.lua')			-- no NLS
dofile(pluginScriptPath .. '/livestream.lua')			-- no NLS
dofile(pluginScriptPath .. '/mediathek.lua')			-- no NLS
dofile(pluginScriptPath .. '/mediathek_leftMenu.lua')	-- no NLS
dofile(pluginScriptPath .. '/mediathek_movieInfo.lua')	-- no NLS
dofile(pluginScriptPath .. '/main.lua')					-- no NLS
