
n = neutrino();
-- check lua api version
n:checkVersion(1, 10);

json    = require "json"
posix   = require "posix"
gui     = require "n_gui"
helpers = require "n_helpers"

-- define global paths
pluginScriptPath = helpers.scriptPath() .. "/" .. helpers.scriptBase();
pluginTmpPath    = "/tmp/" .. helpers.scriptBase();
confFile         = "/var/tuxbox/config/" .. helpers.scriptBase() .. ".conf";
os.execute("mkdir -p " .. pluginTmpPath);

-- include lua files
dofile(pluginScriptPath .. "/variables.lua");
dofile(pluginScriptPath .. "/functions.lua");
dofile(pluginScriptPath .. "/images.lua");
dofile(pluginScriptPath .. "/json.lua");
dofile(pluginScriptPath .. "/config.lua");
dofile(pluginScriptPath .. "/parse_m3u8.lua");
dofile(pluginScriptPath .. "/livestream.lua");
dofile(pluginScriptPath .. "/main.lua");

--os.execute("rm -fr " .. pluginTmpPath);
