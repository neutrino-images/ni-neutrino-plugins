-- 13/12/2025 by jokel

function sleep(a)
	local sec = tonumber(os.clock() + a)
	while (os.clock() < sec) do
	end
end

function pop(cmd)
	local f = assert(io.popen(cmd, 'r'))
	local s = assert(f:read('*a'))
	f:close()
	return s
end

---------------------------------- streamlink ---------------------------------

local url = arg[1]

if not url then
	print("Keine URL übergeben")
	return nil
end

run = {}
entry = {}
json = require "json"

os.execute("pkill streamlink")

-- URL auflösen
local cmd = string.format(
	"curl -kLs -o /dev/null -w %%{url_effective} %q",
	url
)

local handle = io.popen(cmd)
local final_url = handle:read("*a")
handle:close()

-- print("Finale URL: " .. final_url)

-- Hintergrund-Lua-Script erzeugen
local watcher = string.format([[
local url = %q

local cmd = string.format(
	'streamlink --hls-live-edge 6 "hls://%%s" --default-stream 720p,2300k,3300k,best -O | \
	ffmpeg -loglevel quiet -nostats -i pipe:0 -vcodec copy -acodec copy -f mpegts tcp://127.0.0.1:4444?listen > /dev/null 2>&1 &',
	url
)

local handle = io.popen(cmd)
handle:close()
]], final_url)

local f = io.open("/tmp/streamlink_watcher.lua", "w")
f:write(watcher)
f:close()

-- Hintergrund-Lua starten
os.execute(string.format("lua /tmp/streamlink_watcher.lua '%s' &", final_url))

-- Warten, bis Port aktiv ist (max. 15 Sekunden)
local port_open = false
for i = 1, 15 do
	local run = pop("fuser 4444/tcp 2>/dev/null")
	if #run ~= 0 then
		port_open = true
		break
	end
	sleep(1)
end

-- Wenn Port nicht geöffnet wurde, streamlink beenden
if not port_open then
	os.execute("pkill streamlink")
	return nil
end

entry['url'] = 'tcp://127.0.0.1:4444'
return json:encode(entry)
