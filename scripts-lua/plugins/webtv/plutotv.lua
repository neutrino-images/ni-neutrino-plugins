--[[
	plutotv.lua

	minimal example entry for plutotv.xml
	<webtv title="Pluto TV Nature" url="5be1c3f9851dd5632e2c91b2" script="plutotv.lua" />
]]

json = require "json"

if #arg < 1 then return nil end
local _url = arg[1]
local ret = {}
local Curl = nil
local fname = ""

function getdata(Url, File)
	if Url == nil then return nil end
	if Curl == nil then
		Curl = curl.new()
	end
	local ret, data = Curl:download{ url=Url, ipv4=true, A="Mozilla/5.0", o=File}
	if ret == CURL.OK then
		if File then
			return 1
		else
			return data
		end
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
	token = "?advertisingId=&appName=web&appVersion=unknown&appStoreUrl=&architecture=&buildVersion=&clientTime=0&deviceDNT=0&deviceId=" .. gen_ids() .. "&deviceMake=Chrome&deviceModel=web&deviceType=web&deviceVersion=unknown&includeExtendedEvents=false&sid=" .. gen_ids() .. "&userId=&serverSideAds=true"
	local data = getdata(http .. url .."/master.m3u8" ..token) -- Calling the generated master.m3u8 
	local count = 0
	if data then
		local name = "auf Pluto TV"
--[[
		local start = os.date('%Y-%m-%dT%H:%M:%S.000Z')
		local stop = os.date('%Y-%m-%dT%H:%M:%S.000Z', os.time() + 60 * 60 * 2)
		local channels_data = getdata("http://api.pluto.tv/v2/channels?start=" .. start .. "&stop=" .. stop)
]]
		local channels_data = getdata("http://api.pluto.tv/v2/channels")
		if channels_data then
			local jd = json:decode(channels_data)
			if jd then
				for i = 1, #jd do
					if jd[i] and jd[i]._id == url and jd[i].category then
						if string.find(jd[i].category, name) then
							name = jd[i].category
						else
							name = jd[i].category .. " " .. name
						end
						break
					end
				end
			end
		end
		local res = 0
		for band, url2 in data:gmatch('BANDWIDTH=(%d+),.-\n(%d+.-m3u8)') do
			if band and url2 then
				local nr = tonumber(band)
				if nr > res then
					res=nr
					entry = {}
					entry['url']  = http .. url .. "/" .. url2 .. token 
					entry['band'] = band
					entry['name'] = name
					count = 1
					ret[count] = {}
					ret[count] = entry
				end
			end
		end
	end
	return count
end

--[[
function getLogo(url)
	local data = getdata("http://127.0.0.1/control/getchannelid?format=json")
	if data then
		local jd = json:decode(data)
		if jd and jd.data and jd.data.id and jd.data.id.short_id then
			local logo = "/var/tuxbox/icons/logo/" .. jd.data.id.short_id .. ".png"
			local fh = filehelpers.new()
			if not fh:exist(logo, "f") then
				getdata("https://images.pluto.tv/channels/" .. url .. "/logo.png?fit=fill&fm=png&h=40", logo)
			end
		end
	end
end
]]

if (getVideoData(_url) > 0) then
	--getLogo(_url)
	return json:encode(ret)
end

return ""
