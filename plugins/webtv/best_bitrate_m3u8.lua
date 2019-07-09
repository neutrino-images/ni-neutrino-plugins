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
	local count = 0
	local data = getdata(m3u8_url)
	if data then
		local host = m3u8_url:match('([%a]+[:]?//[_%w%-%.]+)/')
		local lastpos = (m3u8_url:reverse()):find("/")
		local hosttmp = m3u8_url:sub(1,#m3u8_url-lastpos)
		if hosttmp then
			host = hosttmp .."/"
		end
		for band, res1, res2, url in data:gmatch('BANDWIDTH=(%d+).-RESOLUTION=(%d+)x(%d+).-\n(.-)\n') do
			if url and res1 then
				local nr = tonumber(res1)
				if nr < 2000 and nr > res then
					res=nr
					if host and url:sub(1,4) ~= "http" then
						url = host .. url
					end
					entry = {}
					entry['url']  = url
					entry['band'] = band
					entry['res1'] = res1
					entry['res2'] = res2
					entry['name'] = "RESOLUTION=" .. res1 .. "x" .. res2
					count = count + 1
					ret[count] = {}
					ret[count] = entry
				end
			end
		end
	end
	return res
end

if (getVideoUrl(_url) > 0) then
	return json:encode(ret)
end

	entry = {}
	entry['url']  = _url
	entry['band'] = "1"
	entry['res1'] = "1"
	entry['res2'] = "1"
	entry['name'] = "RESOLUTION=1x1"
	ret[1] = {}
	ret[1] = entry
	return json:encode(ret)
