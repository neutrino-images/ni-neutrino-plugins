--parse best m3u8 RESOLUTION
if #arg < 1 then return nil end

json = require "json"

local _url = arg[1]
local Curl = nil
local ret = {}

function getdata(Url,Agent)
	if Url == nil then return nil end
	if Curl == nil then
		Curl = curl.new()
	end
	if Agent == nil then Agent = "Mozilla/5.0" end
	local ret, data = Curl:download{ url=Url, A=Agent,connectTimeout=5,maxRedirs=5,followRedir=true}
	if ret == CURL.OK then
		return data
	else
		return nil
	end
end

function getMaxRes()
	local maxRes = 1280
	local Nconfig = configfile.new()
	if Nconfig then
		Nconfig:loadConfig("/var/tuxbox/config/neutrino.conf")
		maxRes = Nconfig:getInt32("livestreamResolution", 1280)
	end
	return maxRes
end

function getVideoUrl(m3u8_url)
	if m3u8_url == nil then return nil end
	local tmpurl = m3u8_url:lower()
	if not tmpurl:find('m3u8') then return -2 end

	local res = 0
	local agent = m3u8_url:match("User%-Agent=(.*)")
	local data = getdata(m3u8_url,agent)
	if data then
		res = 1
		entry = {}
		entry['url']  = m3u8_url
		entry['name'] = "org m3u8 url"
		ret[1] = {}
		ret[1] = entry

		local host = m3u8_url:match('([%a]+[:]?//[_%w%-%.]+)/')
		local lastpos = (m3u8_url:reverse()):find("/")
		local hosttmp = m3u8_url:sub(1,#m3u8_url-lastpos)
		if hosttmp then
			host = hosttmp .."/"
		end
		local revision = 0
		local maxRes = getMaxRes()
		if APIVERSION ~= nil and (APIVERSION.MAJOR > 1 or ( APIVERSION.MAJOR == 1 and APIVERSION.MINOR > 82 )) then
			M = misc.new()
			revision = M:GetRevision()
		end
		local audio_url = nil
		if revision == 1 then -- separate audio for hd51 and co
			local Nconfig	= configfile.new()
			local lang1,lang2,lang3 = nil,nil,nil
			Nconfig:loadConfig("/var/tuxbox/config/neutrino.conf")
			lang1 = Nconfig:getString("pref_lang_0", "#")
			lang2 = Nconfig:getString("pref_lang_1", "#")
			lang3 = Nconfig:getString("pref_lang_2", "#")
			if lang1 == "#" then lang1 = nil else lang1 = lang1:lower() lang1 = lang1:sub(1,3) end
			if lang2 == "#" then lang2 = nil else lang2 = lang2:lower() lang2 = lang2:sub(1,3) end
			if lang3 == "#" then lang3 = nil else lang3 = lang3:lower() lang3 = lang3:sub(1,3) end
			if lang1 == nil then
				lang1 = Nconfig:getString("language", "english")
				if lang1 == nil then
					lang1 = "eng"
				else
					lang1 = lang1:lower() lang1 = lang1:sub(1,3)
				end
			end

			local l1,l2,l3,l4,l = nil,nil,nil,nil,nil
			for adata in data:gmatch('TYPE%=AUDIO.GROUP%-ID=".-",(.-)\n') do
				local lname = adata:match('NAME="(.-)"')
				local lang = adata:match('LANGUAGE="(.-)"')
				local aurl = adata:match('URI="(.-)"')
				if aurl then
					local low_lang = lang:lower()
					if l1 == nil and lname and lang1 and low_lang == lang1 then
						l1 = aurl
					elseif l2 == nil and lname and lang2 and low_lang == lang2 then
						l2 = aurl
					elseif l3 == nil and lname and lang3 and low_lang == lang3 then
						l3 = aurl
					elseif l4 == nil and lname and low_lang == "deu" then
						l4 = aurl
					elseif l == nil then
						l = aurl
					end
				end
			end
			audio_url = l1 or l2 or l3 or l4 or l
		end
		local first = true
		local allres = {}
		local allbands = {}
		for band, res1, res2, url in data:gmatch('BANDWIDTH=(%d+).-RESOLUTION=(%d+)x(%d+).-\n(.-)\n') do
			if url and res1 and url:sub(1,3) ~= '../' then
				local nr = tonumber(res1)
				if (nr <= maxRes and nr > res) or first then
					if not first then res=nr end
					first = false
					if host and url:sub(1,4) ~= "http" then
						if host:sub(-1) == '/' and url:sub(1,1) == '/' then
							url = host:sub(1,-2) .. url
						else
							url = host .. url
						end
					end
					if audio_url and host and audio_url:sub(1,4) ~= "http" then
						audio_url = host .. audio_url
					end
					entry = {}
					url = url:gsub("\x0d","")
					entry['url']  = url
					if audio_url then
						audio_url = audio_url:gsub("\x0d","")
						entry['url2'] = audio_url
					end
					if agent then entry['header']  = agent end
					entry['band'] = band
					entry['res1'] = res1
					entry['res2'] = res2
					entry['name'] = "RESOLUTION=" .. res1 .. "x" .. res2
					ret[1] = {}
					ret[1] = entry
					res = 2
				end
				if res1 then
					local Res = res1 .. "x" .. res2
					if allres[Res] ~= true then
						allres[Res] = true
					end
				end
			end
		end
		if allres then
			local otherRes = ''
			for Res, _ in pairs(allres) do
				if not entry['name']:find(Res) then
					otherRes = otherRes .. ' ' .. Res
				end
			end
			if #otherRes > 1 then entry['name'] = entry['name'] .. ' :' .. otherRes end
		end

		if res == 1 then
			for band, url in data:gmatch('BANDWIDTH=(%d+).-\n(.-)\n') do
				if url and band  and url:sub(1,3) ~= '../' then
					local nr = tonumber(band)
					if nr > res then
						if not first then res=nr end
						first = false
						if host and url:sub(1,4) ~= "http" then
							if host:sub(-1) == '/' and url:sub(1,1) == '/' then
								url = host:sub(1,-2) .. url
							else
								url = host .. url
							end
						end
						if audio_url and host and audio_url:sub(1,4) ~= "http" then
							audio_url = host .. audio_url
						end
						entry = {}
						url = url:gsub("\x0d","")
						entry['url']  = url
						if audio_url then
							audio_url = audio_url:gsub("\x0d","")
							entry['url2'] = audio_url
						end
						if agent then entry['header']  = agent end
						entry['band'] = band
						local otherBand = ''
						entry['name'] = "BANDWIDTH=" .. band
						ret[1] = {}
						ret[1] = entry
					end
					if band then
						if allbands[band] ~= true then
							allbands[band] = true
						end
					end
				end
			end
		end
		if allbands then
			local otherBands = ''
			for Band, _ in pairs(allbands) do
				if not entry['name']:find(Band) then
					otherBands = otherBands .. ' ' .. Band
				end
			end
			if #otherBands > 1 then entry['name'] = entry['name'] .. ' :' .. otherBands end
		end
	else
		return -1 --url is offline
	end
	return res
end

local have_url = getVideoUrl(_url)
if have_url > 0 then
	return json:encode(ret)
end
if have_url == -1 then return "" end --url is offline

	entry = {}
	entry['url']  = _url
	entry['band'] = "1"
	entry['res1'] = "1"
	entry['res2'] = "1"
	entry['name'] = "not m3u8"
	ret[1] = {}
	ret[1] = entry
	return json:encode(ret)
