--parse best m3u8 RESOLUTION
if #arg < 1 then return nil end

json = require "json"

local _url = arg[1]
local Curl = nil
local ret = {}

function getdata(Url)
	if Url == nil then return nil end
	if Curl == nil then
		Curl = curl.new()
	end
	local ret, data = Curl:download{ url=Url, A="Mozilla/5.0",connectTimeout=5,maxRedirs=5,followRedir=true}
	if ret == CURL.OK then
		return data
	else
		return nil
	end
end

function getVideoUrl(m3u8_url)
	if m3u8_url == nil then return nil end
	local res = 0
	local data = getdata(m3u8_url)
	if data then
		local host = m3u8_url:match('([%a]+[:]?//[_%w%-%.]+)/')
		local lastpos = (m3u8_url:reverse()):find("/")
		local hosttmp = m3u8_url:sub(1,#m3u8_url-lastpos)
		if hosttmp then
			host = hosttmp .."/"
		end
		local revision = 0
		local maxRes = 2000
		if APIVERSION ~= nil and (APIVERSION.MAJOR > 1 or ( APIVERSION.MAJOR == 1 and APIVERSION.MINOR > 82 )) then
			M = misc.new()
			revision = M:GetRevision()
			if revision == 1 then maxRes = 3840 end --for hd51 and co
		end

		local audio_url = nil
		if revision == 1 then -- separate audio for hd51 and co
			local Nconfig	= configfile.new()
			local lang1,lang2,lang3 = nil,nil,nil
			Nconfig:loadConfig("/var/tuxbox/config/neutrino.conf")
			lang1 = Nconfig:getString("pref_lang_0", "#")
			lang2 = Nconfig:getString("pref_lang_1", "#")
			lang3 = Nconfig:getString("pref_lang_2", "#")
			if lang1 == "#" then lang1 = nil end
			if lang2 == "#" then lang2 = nil end
			if lang3 == "#" then lang3 = nil end
			if lang1 == nil then
				lang1 = Nconfig:getString("language", "english")
				if lang1 == nil then
					lang1 = "english"
				end
			end

			local l1,l2,l3,l = nil,nil,nil,nil
			for lname, lang, aurl in data:gmatch('TYPE%=AUDIO.GROUP%-ID=".-",NAME="(.-)",LANGUAGE="(.-)".-URI="(.-)".-\n') do
				if lang1 and lname:lower() == lang1:lower() then
					l1 = aurl
				elseif lang2 and lname:lower() == lang2:lower() then
					l2 = aurl
				elseif lang3 and lname:lower() == lang3:lower() then
					l3 = aurl
				elseif l == nil then
					l = aurl
				end
			end
			audio_url = l1 or l2 or l3 or l
		end

		for band, res1, res2, url in data:gmatch('BANDWIDTH=(%d+).-RESOLUTION=(%d+)x(%d+).-\n(.-)\n') do
			if url and res1 then
				local nr = tonumber(res1)
				if nr <= maxRes and nr > res then
					res=nr
					if host and url:sub(1,4) ~= "http" then
						url = host .. url
					end
					if audio_url and host and audio_url:sub(1,4) ~= "http" then
						audio_url = host .. audio_url
					end
					entry = {}
					entry['url']  = url
					if audio_url then entry['url2']  = audio_url end
					entry['band'] = band
					entry['res1'] = res1
					entry['res2'] = res2
					entry['name'] = "RESOLUTION=" .. res1 .. "x" .. res2
					ret[1] = {}
					ret[1] = entry
				end
			end
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
	entry['name'] = "RESOLUTION=1x1"
	ret[1] = {}
	ret[1] = entry
	return json:encode(ret)
