--[[
	ZDF sport live 0.9
	satbaby

	The live stream list comes from the ZDF GraphQL API; zdf.de no longer
	embeds it in the page HTML. The page is fetched only for the API token.
]]

local n = neutrino(0, 0, SCREEN.X_RES, SCREEN.Y_RES)

json = require "json"

if #arg < 1 then
	return nil
end

local _url0 = arg[1]
local ret0 = {}
local Curl = nil
local sm = nil
local nr = 0

function conv_str(_string)
	if _string == nil then return _string end
	_string = string.gsub(_string,"&amp;","&");
	_string = string.gsub(_string,"&quot;","\"");
	_string = string.gsub(_string,"&#039;","'");
	_string = string.gsub(_string,"\\u0026","&");
	_string = string.gsub(_string,"\\u00a0"," ");
	_string = string.gsub(_string,"\\u00b4","´");
	_string = string.gsub(_string,"\\u00c4","Ä");
	_string = string.gsub(_string,"\\u00d6","Ö");
	_string = string.gsub(_string,"\\u00dc","Ü");
	_string = string.gsub(_string,"\\u00df","ß");
	_string = string.gsub(_string,"\\u00e1","á");
	_string = string.gsub(_string,"\\u00e4","ä");
	_string = string.gsub(_string,"\\u00e8","è");
	_string = string.gsub(_string,"\\u00e9","é");
	_string = string.gsub(_string,"\\u00f4","ô");
	_string = string.gsub(_string,"\\u00f6","ö");
	_string = string.gsub(_string,"\\u00fb","û");
	_string = string.gsub(_string,"\\u00fc","ü");
	_string = string.gsub(_string,"\\u2013","–");
	_string = string.gsub(_string,"\\u201c","“");
	_string = string.gsub(_string,"\\u201e","„");
	_string = string.gsub(_string,"\\u2026","…");
	_string = string.gsub(_string,"&#038;","&");
	_string = string.gsub(_string,"&#8211;","–");
	_string = string.gsub(_string,"&#8212;","—");
	_string = string.gsub(_string,"&#8216;","‘");
	_string = string.gsub(_string,"&#8217;","’");
	_string = string.gsub(_string,"&#8230;","…");
	_string = string.gsub(_string,"&#8243;","?");
	_string = string.gsub(_string,"<[^>]*>","");
	_string = string.gsub(_string,"\\/","/");
	_string = string.gsub(_string,"\\n","");
	return _string
end

function getdata(Url,headers,Agent)
	if Url == nil then return nil end
	if Curl == nil then
		Curl = curl.new()
	end
	if Agent == nil then Agent = "Mozilla/5.0" end

	local ret, data = Curl:download{ url=Url, A=Agent, httpheader=headers, connectTimeout=5, maxRedirs=5, followRedir=true}
	if ret == CURL.OK then
		return data
	else
		return nil
	end
end

function godirectkey(d)
	if d == nil then
		return d
	end
	local _dkey = ""
	if d == 1 then
		_dkey = RC.red
	elseif d == 2 then
		_dkey = RC.green
	elseif d == 3 then
		_dkey = RC.yellow
	elseif d == 4 then
		_dkey = RC.blue
	elseif d < 14 then
		_dkey = RC["" .. (d - 4) .. ""]
	elseif d == 14 then
		_dkey = RC["0"]
	else
		-- rest
		_dkey = ""
	end
	return _dkey
end

function getid(id)
	sm:hide()
	nr = tonumber(id)
	return MENU_RETURN.EXIT_ALL
end

function getNeutrinoConf(Pattern)
	local conf_dir = "/var/tuxbox/config"
	if DIR and DIR.CONFIGDIR then
		conf_dir = DIR.CONFIGDIR
	end
	local neutrino_conf = conf_dir .. "/neutrino.conf"
	local liveScrPath = nil
	local fh = filehelpers.new()
	if fh:exist(neutrino_conf, "f") == true then
		local config = configfile.new()
		config:loadConfig(neutrino_conf)
		liveScrPath = config:getString(Pattern, "#")
	end
	return liveScrPath
end

local GRAPHQL_URL = "https://api.zdf.de/graphql"
local PTMD_PLAYER = "ngplayer_2_5"
local SPORT_GENRE = "genre-10290" -- genreMetaCollection id of "Sport"

local function trim(s)
	return (s:gsub("^%s*(.-)%s*$", "%1"))
end

-- the API delivers UTC timestamps; os.time() reads a table as local
-- time, so shift the result by the UTC offset valid at that moment
local function utcToLocal(utcTable)
	local t0 = os.time(utcTable)
	local u = os.date("!*t", t0)
	u.isdst = os.date("*t", t0).isdst
	return t0 + (t0 - os.time(u))
end

local function convertToLocalTime(isoStr)
	if isoStr == nil then
		return nil
	end
	local year, month, day, hour, min, sec = isoStr:match("(%d%d%d%d)-(%d%d)-(%d%d)T(%d%d):(%d%d):(%d%d)")
	if not year then
		return nil
	end

	local timestamp = utcToLocal({
		year  = tonumber(year),
		month = tonumber(month),
		day   = tonumber(day),
		hour  = tonumber(hour),
		min   = tonumber(min),
		sec   = tonumber(sec)
	})
	local localTime = os.date("*t", timestamp)
	local today = os.date("*t")

	local hm = string.format("%02d:%02d", localTime.hour, localTime.min)
	if localTime.year == today.year and localTime.yday == today.yday then
		return hm
	end
	return string.format("%02d.%02d. %s", localTime.day, localTime.month, hm)
end

local function postdata(Url, body, headers)
	if Url == nil then return nil end
	if Curl == nil then
		Curl = curl.new()
	end
	local ret, data = Curl:download{ url=Url, A="Mozilla/5.0", postfields=body, httpheader=headers, connectTimeout=5, maxRedirs=5, followRedir=true}
	if ret == CURL.OK then
		return data
	else
		return nil
	end
end

-- running (LIVE) and announced (SCHEDULED_LIVE) streams of all ZDF
-- channels; the sport filter is applied by the caller
local function getLiveStreams(token)
	-- no double quotes inside the query, so the JSON body can be built by hand
	local query = "{ videos(filterBy: {availableStreamTypeIn: [LIVE, SCHEDULED_LIVE]},"
		.. " sortBy: [{field: EDITORIAL_DATE, direction: ASC}]) {"
		.. " nodes { canonical currentMediaType excludeFromIndex"
		.. " teaser { title }"
		.. " scheduledMedia { availableFrom availableTo }"
		.. " currentMedia { nodes { ptmdTemplate ... on LiveMedia { plannedStart } } }"
		.. " smartCollection { title structuralMetadata { genreMetaCollection { id title } } }"
		.. " } } }"
	local body = '{"query":"' .. query .. '"}'
	local headers = {"Api-Auth: Bearer " .. token, "Content-Type: application/json"}
	local data = postdata(GRAPHQL_URL, body, headers)
	if data == nil then
		return {}
	end
	local js = json:decode(data)
	if not js or not js.data or not js.data.videos or not js.data.videos.nodes then
		return {}
	end
	return js.data.videos.nodes
end

local function isSportStream(node)
	if node.excludeFromIndex == true then
		return false
	end
	local sc = node.smartCollection
	local genre = sc and sc.structuralMetadata and sc.structuralMetadata.genreMetaCollection
	if genre == nil then
		return false
	end
	return genre.title == "Sport" or genre.id == SPORT_GENRE
end

local function streamTitle(node)
	local title = trim(node.teaser and node.teaser.title or "")
	local sc = node.smartCollection
	if sc and sc.title then
		local prefix = trim(sc.title)
		if prefix ~= "" and prefix ~= title then
			title = prefix .. ": " .. title
		end
	end
	return conv_str(title)
end

function playmenu(data)
	local urls = {}
	local d = 0
	local key = nil

	if data then
		local videotoken = data:match('videoToken\\":{\\"apiToken\\":\\"(.-)\\"')
		local Hurls = {}
		if videotoken then
			for _, node in ipairs(getLiveStreams(videotoken)) do
				if isSportStream(node) then
					local title = streamTitle(node)
					local media = node.currentMedia and node.currentMedia.nodes and node.currentMedia.nodes[1]
					if node.currentMediaType == "LIVE" and media and media.ptmdTemplate then
						local Url = (media.ptmdTemplate:gsub("{playerId}", PTMD_PLAYER))
						if Hurls[Url] ~= true then
							Hurls[Url] = true
							d = d + 1
							key = godirectkey(d)
							local time = convertToLocalTime(media.plannedStart)
							if time then title = time .. " " .. title end
							table.insert(urls, {
								title = title,
								url = Url,
								videotoken = videotoken,
								enabled = true,
								dkey = key
							})
						end
					elseif node.scheduledMedia and node.scheduledMedia.availableFrom then
						local id = node.canonical or title
						if Hurls[id] ~= true then
							Hurls[id] = true
							d = d + 1
							key = godirectkey(d)
							local time = convertToLocalTime(node.scheduledMedia.availableFrom)
							if time then title = "ab " .. time .. " " .. title end
							table.insert(urls, {
								title = title,
								enabled = false,
								videotoken = nil,
								url = nil,
								dkey = key
							})
						end
					end
				end
			end
		end
		key = nil
	end

	if #urls > 0 then
		sm = menu.new{name = "ZDFsport", icon = "icon_blue"}
		for index, w in ipairs(urls) do
			sm:addItem{
				type = "forwarder",
				name = w.title,
				action = "getid",
				id = index,
				enabled = w.enabled,
				directkey = w.dkey
			}
		end
		sm:exec()
		sm:hide()
	end

	if #urls == 1 then
		nr = 1
	end

	if nr > 0  and urls and urls[nr].url and urls[nr].videotoken then
		local scpath = getNeutrinoConf("livestreamScriptPath")
		if scpath then
			local header = {"api-auth: Bearer " .. urls[nr].videotoken }
			local jsdata = getdata("https://api.zdf.de" .. urls[nr].url, header)
			local url_m3u8 = nil
			if jsdata then
				local jsT = json:decode(jsdata)
				if jsT.priorityList and jsT.priorityList[1].formitaeten[1]
					and jsT.priorityList[1].formitaeten[1].qualities[1]
					and jsT.priorityList[1].formitaeten[1].qualities[1].audio
					and jsT.priorityList[1].formitaeten[1].qualities[1].audio.tracks[1] then
					url_m3u8 = jsT.priorityList[1].formitaeten[1].qualities[1].audio.tracks[1].uri
				end
			end
			if url_m3u8 then
				arg = {}
				arg[1] = url_m3u8
				arg[2] = nil
				local scriptfile = "/best_bitrate_m3u8.lua"
				local r = dofile(scpath .. scriptfile)
				if r then
					local js = json:decode(r)
					if js and next(js) ~= nil then
						for k, v in ipairs(js) do
							js[k].name = urls[nr].title
						end
						return json:encode(js)
					end
				end
			end
		end
	end
	return nil
end

function getVideoData(url)
	if url == nil then
		return 0
	end
	local data = getdata(url)
	if data then
		ret0 = playmenu(data)
		if ret0 then
			return 1
		end
	end
	return 0
end

if getVideoData(_url0) > 0 then
	return ret0
end

return ""
