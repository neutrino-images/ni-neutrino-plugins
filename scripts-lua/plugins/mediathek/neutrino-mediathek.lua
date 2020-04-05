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

V   = video.new()
M   = misc.new()
FH  = filehelpers.new()
C   = curl.new()
J   = loadLuaLib('json')		-- no NLS
G   = loadLuaLib('n_gui')		-- no NLS
H   = loadLuaLib('n_helpers')	-- no NLS

-- define global paths
pluginScriptPath = H.scriptPath() .. '/' .. H.scriptBase()	-- no NLS
pluginTmpPath    = '/tmp/' .. H.scriptBase()	-- no NLS
confFile         = '/var/tuxbox/config/' .. H.scriptBase() .. '.conf'	-- no NLS
--os.execute("rm -fr " .. pluginTmpPath)
--os.execute("mkdir -p " .. pluginTmpPath)
FH:rmdir(pluginTmpPath)
FH:mkdir(pluginTmpPath)

-- include lua files
dofile(pluginScriptPath .. '/variables.lua')	-- no NLS
dofile(pluginScriptPath .. '/functions.lua')	-- no NLS
dofile(pluginScriptPath .. '/images.lua')		-- no NLS
dofile(pluginScriptPath .. '/json_decode.lua')	-- no NLS
dofile(pluginScriptPath .. '/config.lua')		-- no NLS
dofile(pluginScriptPath .. '/parse_m3u8.lua')	-- no NLS
dofile(pluginScriptPath .. '/livestream.lua')	-- no NLS
dofile(pluginScriptPath .. '/mediathek.lua')	-- no NLS
dofile(pluginScriptPath .. '/main.lua')			-- no NLS

--os.execute("rm -fr " .. pluginTmpPath)
FH:rmdir(pluginTmpPath)
