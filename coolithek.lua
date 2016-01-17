
N = neutrino(0, 0, SCREEN.X_RES, SCREEN.Y_RES);
-- check lua api version
local req_major = 1
local req_minor = 37
if ((APIVERSION.MAJOR < req_major) or (APIVERSION.MAJOR == req_major and APIVERSION.MINOR < req_minor)) then
	N:checkVersion(req_major, req_minor);
end

function loadLuaLib(lib, noerror)
	local status, data = pcall(require, lib)
	if noerror == true then
		if status == true then return data
		else return nil end
	end
	if status == true then return data
	else
		error("lua library  not found: \"" .. lib .. "[.so|.lua]\"")
	end
end

V   = video.new()
M   = misc.new()
J   = loadLuaLib("json")
P   = loadLuaLib("posix")
G   = loadLuaLib("n_gui")
H   = loadLuaLib("n_helpers")
ZMQ = loadLuaLib("lzmq", true)

-- define global paths
pluginScriptPath = H.scriptPath() .. "/" .. H.scriptBase();
pluginTmpPath    = "/tmp/" .. H.scriptBase();
confFile         = "/var/tuxbox/config/" .. H.scriptBase() .. ".conf";
os.execute("rm -fr " .. pluginTmpPath);
os.execute("mkdir -p " .. pluginTmpPath);

-- include lua files
dofile(pluginScriptPath .. "/variables.lua");
dofile(pluginScriptPath .. "/functions.lua");
dofile(pluginScriptPath .. "/images.lua");
dofile(pluginScriptPath .. "/json_decode.lua");
dofile(pluginScriptPath .. "/config.lua");
dofile(pluginScriptPath .. "/parse_m3u8.lua");
dofile(pluginScriptPath .. "/livestream.lua");
dofile(pluginScriptPath .. "/mediathek.lua");
dofile(pluginScriptPath .. "/main.lua");

os.execute("rm -fr " .. pluginTmpPath);
