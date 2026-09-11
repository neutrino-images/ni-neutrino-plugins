EXT_X_STREAM_INF = '#EXT%-X%-STREAM%-INF%:'
EXT_X_MEDIA = '#EXT%-X%-MEDIA%:'
local languages = {"de", "deu"}

-- Helper function to check if a value exists in a table
local function is_in_list(value, list)
    for _, v in ipairs(list) do
        if v == value then
            return true
        end
    end
    return false
end

function parse_m3u8Data(url, parse_mode)
	local box = downloadFile(url, m3u8Data, false, user_agent2)

	local streamInfo = {}
	local fp = io.open(m3u8Data, "r")
	if not fp then
		G.hideInfoBox(box)
		error("Error connecting URL.")
	end

	local current_stream = nil
	local audio_url = nil

	-- playlist uris come in four shapes: full urls (http, rtmp, ...),
	-- scheme-relative "//host/...", root-relative paths (the zdf live
	-- masters use "/hls/live/...") and paths relative to the master's
	-- directory
	local scheme = url:match('^(%a[%w+.-]*):')
	local root = url:match('^(%a[%w+.-]*://[^/?]+)')
	local base = url:match('^(.*/)')
	local function resolve(u)
		if u == nil or u:find('^%a[%w+.-]*://') then return u end
		if u:sub(1, 2) == "//" then return scheme and (scheme .. ":" .. u) or u end
		if u:sub(1, 1) == "/" then return root and (root .. u) or u end
		return base and (base .. u) or u
	end

	-- A table to store the audio URIs found
	local audio_uris = {}

	for line in fp:lines() do
		line = line:gsub("[\n\r]", "")

		-- find Stream-Information
		if line:find(EXT_X_STREAM_INF) then
			current_stream = {}
			for key, value in line:gmatch("([%w%-]+)=([^,]+)") do
				if key == "BANDWIDTH" then
					current_stream.bandwidth = tonumber(value)
				elseif key == "RESOLUTION" then
					current_stream.resolution = value
				elseif key == "CODECS" then
					value = value:gsub('"', "")  -- Entfernen der Anführungszeichen
					current_stream.codec = H.split(value, ",")
				end
			end
			if not current_stream.bandwidth then
				current_stream.bandwidth = 0
			end
			if not current_stream.resolution then
				current_stream.resolution = "-"
			end
		elseif line:find(EXT_X_MEDIA) then
			-- Check if the media line contains the desired audio language
			local is_audio = false
			local is_language = false
			local is_default = false
			local temp_audio_url = nil

			for key, value in line:gmatch("([%w%-]+)=([^,]+)")  do
				-- Handling values with or without quotes
				value = value:gsub('"', "")

				if key == "TYPE" and value == "AUDIO" then
					is_audio = true
				elseif is_audio and key == "LANGUAGE" then
					if is_in_list(value, languages) then
						is_language = true
					end
				elseif is_audio and is_language and key == "DEFAULT" and value == "YES" then
					is_default = true
				elseif is_audio and is_language and is_default and key == "URI" then
					temp_audio_url = value
				end
			end
			-- Store the URI in the audio_uris table, ensuring it is unique
			if temp_audio_url then
				audio_uris.audio = resolve(temp_audio_url)
			end

		elseif current_stream and #line > 2 and not line:find("^#") then
			-- add URL to Stream-Info; tag lines between the stream
			-- info and its uri (i-frame playlists) are not the uri
			current_stream.url = resolve(line)

			table.insert(streamInfo, current_stream)
			current_stream = nil -- reset stream
		end
	end
	table.insert(streamInfo, audio_uris)

	fp:close()
	G.hideInfoBox(box)
	return streamInfo
end

function get_m3u8url(url, parse_mode, quality)
	local ret = {}
	quality = quality or conf.streamQuality
	local si = parse_m3u8Data(url, parse_mode)

	if (#si < 1) then
		ret['url']           = url
		ret['url2']          = ""
		ret['bandwidth']     = '-'
		ret['resolution']    = '-'
		ret['qual']          = quality
		return ret
	end

	local i
	local minBW	= 1000000000
	local maxBW	= 0
	local tmpBW	= 0
	local xBW	= 0
	local maxRes	= ''
	local minRes	= ''
	local xRes	= ''
	local minUrl	= ''
	local maxUrl	= ''
	local xUrl	= ''

	-- min/max bandwidth
	for i=1, #si do
		if (si[i]['bandwidth'] == nil) then si[i]['bandwidth'] = 0 end
		if (si[i]['bandwidth'] > 65000) then -- skip audio streams
			if (si[i]['bandwidth'] <= minBW) then
				minBW  = si[i]['bandwidth']
				minUrl = si[i]['url']
				minRes = si[i]['resolution']
			end
			if (si[i]['bandwidth'] >= maxBW) then
				maxBW  = si[i]['bandwidth']
				maxUrl = si[i]['url']
				maxRes = si[i]['resolution']
			end
		end
	end

	-- average bandwidth
	tmpBW = (maxBW+minBW)/2
	local diff = 1000000000
	for i=1, #si do
		if (si[i]['bandwidth'] == nil) then si[i]['bandwidth'] = 0 end
		if (si[i]['bandwidth'] > 65000) then -- skip audio streams
			if (math.abs(tmpBW - si[i]['bandwidth']) < diff) then
				diff = math.abs(tmpBW - si[i]['bandwidth'])
				xUrl = si[i]['url']
				xBW  = si[i]['bandwidth']
				xRes = si[i]['resolution']
			end
		end
	end
	for i=1, #si do
		if si[i]['audio'] then
			ret['url2'] = si[i]['audio']
		end
	end

	--H.tprint(si)
	H.printf("minBW: %d, maxBW: %d, tmpBW: %d", minBW, maxBW, tmpBW)

	if (quality == 'max') then
		-- max
		ret['url']		= maxUrl
		ret['bandwidth']	= maxBW
		ret['resolution']	= maxRes
	elseif (quality == 'normal') then
		-- normal
		ret['url']		= xUrl
		ret['bandwidth']	= xBW
		ret['resolution']	= xRes
	else
		-- min
		ret['url']		= minUrl
		ret['bandwidth']	= minBW
		ret['resolution']	= minRes
	end
	-- a media playlist (no stream-inf) or a master without usable
	-- variants leaves the chosen url empty; hand the input back
	-- instead, like the empty stream list above
	if ret['url'] == nil or ret['url'] == '' then
		ret['url']		= url
		ret['url2']		= ""
		ret['bandwidth']	= '-'
		ret['resolution']	= '-'
	end
	ret['qual'] = quality

	return ret
end

-- vod entries may point at a media playlist (segments only) whose audio
-- lives in a separate rendition next to it; find the master in the same
-- directory so get_m3u8url can hand back video and audio like for
-- livestreams. anything that is not an hls master with external audio
-- listing this very variant comes back untouched.
function resolveHlsVod(url, quality)
	if type(url) ~= 'string' or not url:lower():find('%.m3u8$') then
		return url, ""
	end

	local function readPlaylist(u)
		local _, ret = downloadFile(u, m3u8Data, true, user_agent2)
		if ret ~= 0 then return nil end
		local fp = io.open(m3u8Data, "r")
		if not fp then return nil end
		local data = fp:read("*a")
		fp:close()
		if not data or data:sub(1, 7) ~= '#EXTM3U' then return nil end
		return data
	end
	local function isMaster(data)
		return data ~= nil and data:find('#EXT-X-STREAM-INF:', 1, true) ~= nil
	end
	-- a rendition without uri describes audio muxed into the variants
	local function hasExternalAudio(data)
		if data == nil then return false end
		for line in data:gmatch('[^\r\n]+') do
			if line:find('#EXT-X-MEDIA:', 1, true) and line:find('TYPE=AUDIO', 1, true) and line:find('URI=', 1, true) then
				return true
			end
		end
		return false
	end
	local function listsVariant(data, name)
		for line in data:gmatch('[^\r\n]+') do
			if line == name then return true end
		end
		return false
	end
	local function pick(masterUrl, needAudio)
		local ok, ret = pcall(get_m3u8url, masterUrl, 0, quality)
		if ok and type(ret) == 'table' and ret.url and ret.url ~= '' then
			local audio = ret.url2 or ""
			if not needAudio or audio ~= "" then
				return ret.url, audio
			end
		end
		return url, ""
	end

	local data = readPlaylist(url)
	if data == nil then
		return url, ""
	end
	if isMaster(data) then
		return pick(url, hasExternalAudio(data))
	end

	-- media playlist: look for the master next to it
	local base, name = url:match('^(.*/)([^/]*)$')
	if not base or name:lower() == 'master.m3u8' then
		return url, ""
	end
	local candidate = base .. 'master.m3u8'
	local master = readPlaylist(candidate)
	if isMaster(master) and hasExternalAudio(master) and listsVariant(master, name) then
		local v, a = pick(candidate, true)
		H.printf("resolveHlsVod: %s -> %s | %s", url, v, a)
		return v, a
	end
	return url, ""
end
