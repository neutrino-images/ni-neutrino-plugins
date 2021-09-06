--[[	plutotv.lua 

	minimal example entry for plutotv.xml
	<webtv title="Pluto TV Nature" url="5be1c3f9851dd5632e2c91b2" script="plutotv.lua" />
]]

json = require "json"

if #arg < 1 then return nil end
local _url = arg[1]
local ret = {}
local Curl = nil
local fname = ""

function getdata(Url)
	if Url == nil then return nil end
	if Curl == nil then
		Curl = curl.new()
	end
	local ret, data = Curl:download{ url=Url, ipv4=true, A="Mozilla/5.0"}
	if ret == CURL.OK then
		return data
	else
		return nil
	end
end

function gen_ids() -- Generation of a random sid 
	local a = string.format("%x", math.random(1000000000,9999999999)) 
	local b = string.format("%x", math.random(1000,9999)) 
	local c = string.format("%x", math.random(1000,9999)) 
	local d = string.format("%x", math.random(10000000000000,99999999999999))
	local id = tostring(a) .. '-' .. tostring(b) .. '-' .. tostring(c) .. '-' .. tostring(d)
	return id
end
function getVideoData(url) -- Generate stream address and evaluate it according to the best resolution 
	http = "http://service-stitcher.clusters.pluto.tv/stitch/hls/channel/"
	token = "?advertisingId=&appName=web&appVersion=unknown&appStoreUrl=&architecture=&buildVersion=&clientTime=0&deviceDNT=0&deviceId=" .. gen_ids() .. "&deviceMake=Chrome&deviceModel=web&deviceType=web&deviceVersion=unknown&includeExtendedEvents=false&sid=" .. gen_ids() .. "&userId=&serverSideAds=true'"
	local data = getdata(http .. url .."/master.m3u8" ..token) -- Calling the generated master.m3u8 
	local count = 0
	if data then
		local res = 0
		for band, url2 in data:gmatch('BANDWIDTH=(%d+),.-\n(%d+.-m3u8)') do
			if band and url2 then
				local nr = tonumber(band)
				if nr > res then
					res=nr
					local bnum = tonumber(band)
					entry = {}
					entry['url']  = http .. url .. "/" .. url2 .. token 
					entry['band'] = band
					entry['name'] = "by Pluto TV"
					count = 1
					ret[count] = {}
					ret[count] = entry
				end
			end
		end
	end
	return count
end

if (getVideoData(_url) > 0) then
	return json:encode(ret)
end

return ""
