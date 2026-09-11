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

function get_m3u8url(url, parse_mode)
	local ret = {}
	local si = parse_m3u8Data(url, parse_mode)

	if (#si < 1) then
		ret['url']           = url
		ret['url2']          = ""
		ret['bandwidth']     = '-'
		ret['resolution']    = '-'
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

	if (conf.streamQuality == 'max') then
		-- max
		ret['url']		= maxUrl
		ret['bandwidth']	= maxBW
		ret['resolution']	= maxRes
	elseif (conf.streamQuality == 'normal') then
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
	ret['qual'] = conf.streamQuality

	return ret
end
