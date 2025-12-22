-- 20/12/2025 by jokel
-- Version 0.1.2

function sleep(a)
	local sec = tonumber(os.clock() + a)
	while (os.clock() < sec) do end
end

function pop(cmd)
	local f = assert(io.popen(cmd, 'r'))
	local s = assert(f:read('*a'))
	f:close()
	return s
end

------------------------- streamlink + ffmpeg STARTER -------------------------

local url = arg[1]

if not url then
	print("Keine URL übergeben")
	return nil
end

json = require "json"

-- URL auflösen (nur wenn KEIN .m3u8 enthalten ist)
local final_url = url

if not url:match("%.m3u8") then
	local cmd = string.format(
		"curl -kLs -o /dev/null -w %%{url_effective} %q",
		url
	)
	local handle = io.popen(cmd)
	final_url = handle:read("*a")
	handle:close()
end

-- freien Port finden (4444–4499)
local function find_free_port()
	for port = 4444, 4499 do
		local used = pop("fuser " .. port .. "/tcp 2>/dev/null")
		if #used == 0 then
			return port
		end
	end
	return nil
end

local port = find_free_port()

if not port then
	print("Kein freier Port gefunden")
	return nil
end

-- STARTER-Lua erzeugen (pro Instanz eigene Datei)
local starter = string.format([[
local url = %q
local port = %d

local cmd = string.format(
	'streamlink --config "/root/.config/streamlink/config" "%%s" -O | ' ..
	'ffmpeg -loglevel quiet -nostats -i pipe:0 -vcodec copy -acodec copy ' ..
	'-f mpegts -flush_packets 0 -max_delay 5000000 -muxdelay 0.5 -muxpreload 0.5 ' ..
	'tcp://127.0.0.1:%%d?listen > /dev/null 2>&1 &',
	url, port
)
os.execute(cmd)
]], final_url, port)

local starter_file = "/tmp/streamlink_starter_" .. port .. ".lua"
local f = io.open(starter_file, "w")
f:write(starter)
f:close()

-- STARTER im Hintergrund starten
os.execute(string.format("lua %s &", starter_file))

-- Warten, bis Port aktiv ist (max. 15 Sekunden)
local port_open = false
for i = 1, 15 do
	local run = pop("fuser " .. port .. "/tcp 2>/dev/null")
	if #run ~= 0 then
		port_open = true
		break
	end
	sleep(1)
end

if not port_open then
	os.execute("fuser -k " .. port .. "/tcp 2>/dev/null")
	return nil
end

-- Player-URL zurückgeben
local entry = {}
entry['url'] = 'tcp://127.0.0.1:' .. port
return json:encode(entry)
