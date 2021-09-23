--[[
	plutotv-update.lua

	Copyright (C) 2021 vanhofen <neutrino-images.de>
	License: WTFPLv2
]]

plugin = "Pluto TV Update v1.4"

json = require "json"
n = neutrino()

configdir = DIR.CONFIGDIR
webtvdir = DIR.WEBTVDIR

xmltv = "https://i.mjh.nz/PlutoTV/de.xml"

locale = {}
locale["deutsch"] = {
	error = "Fehler",
	update = "Erneuere Pluto TV Bouquets"
}
locale["english"] = {
	error = "Error",
	update = "Updating Pluto TV bouquets"
}

neutrino_conf = configfile.new()
neutrino_conf:loadConfig(configdir .. "/neutrino.conf")
lang = neutrino_conf:getString("language", "english")
if locale[lang] == nil then
	lang = "english"
end

function convert(s)
	s=s:gsub("&","&amp;")
	s=s:gsub("'","&apos;")
	s=s:gsub('"',"&quot;")
	s=s:gsub("<","&lt;")
	s=s:gsub(">","&gt;")
	s=s:gsub("\x0d"," ")
	s=s:gsub("\x0a"," ")
	return s
end

function get_channels()
	local r = false
	local c = curl.new()
	local c_ret, c_data = c:download{url="http://api.pluto.tv/v2/channels.json", ipv4=true, A="Mozilla/5.0"}
	if c_ret == CURL.OK and c_data then
		local jd = json:decode(c_data)
		if jd then
			local xml = io.open(webtvdir .. "/plutotv.xml", 'w+')
			if xml then
				xml:write('<?xml version="1.0" encoding="UTF-8"?>\n')
				xml:write('<webtvs name="Pluto TV">\n')
				for i = 1, #jd do
					if jd[i] then
						if jd[i]._id and jd[i].name then
							local summary = ""
							if jd[i].summary then
								summary = convert(jd[i].summary)
							end
							local category = ""
							if jd[i].category then
								category = convert(jd[i].category:gsub(" auf Pluto TV",""))
							end
							xml:write('	<webtv genre="' .. category .. '" title="' .. convert(jd[i].name) ..  '" url="' .. jd[i]._id .. '" xmltv="' .. xmltv .. '" epgmap="' .. jd[i]._id .. '" logo="https://images.pluto.tv/channels/' .. jd[i]._id .. '/logo.png" script="plutotv.lua" description="' .. summary .. '" />\n')
						end
					end
				end
				xml:write('</webtvs>\n')
				xml:close()
				r = true
			end
		end
	end
	return r
end

h = hintbox.new{caption=plugin, text=locale[lang].update}
h:paint()

if get_channels() then
	os.execute("pzapit -c")
else
	h:hide()
	h = hintbox.new{caption=plugin, text=locale[lang].error}
	h:paint()
	repeat
		msg, data = n:GetInput(500)
	until msg == RC.ok or msg == RC.home
end

h:hide()
