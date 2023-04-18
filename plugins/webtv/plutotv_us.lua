--[[
	plutotv_us.lua 

	minimal example entry for vevo by us plutotv
	<webtv title="Vevo '70s" url="5f32f26bcd8aea00071240e5" script="plutotv_us.lua" description="PlutoTV" />
	<webtv title="Vevo '80s" url="5fd7b8bf927e090007685853" script="plutotv_us.lua" description="PlutoTV" />
	<webtv title="Vevo '90s" url="5fd7bb1f86d94a000796e2c2" script="plutotv_us.lua" description="PlutoTV" />
	<webtv title="Vevo 2K" url="5fd7bca3e0a4ee0007a38e8c" script="plutotv_us.lua" description="PlutoTV" />
	<webtv title="Vevo Country" url="5da0d75e84830900098a1ea0" script="plutotv_us.lua" description="PlutoTV" />
	<webtv title="Vevo Latino" url="5da0d64d0e8a62000964ebe4" script="plutotv_us.lua" description="PlutoTV" />
	<webtv title="Vevo Pop" url="5d93b635b43dd1a399b39eee" script="plutotv_us.lua" description="PlutoTV" />
	<webtv title="Vevo R&amp;B" url="5da0d83f66c9700009b96d0e" script="plutotv_us.lua"description="PlutoTV" />
	<webtv title="Vevo Reggaetón &amp; Trap" url="5f32f397795b750007706448" script="plutotv_us.lua" description="PlutoTV" />
]]

json = require "json"

if #arg < 1 then
	return nil
end

local _url = arg[1]
local ret = {}

function getVideoData(url) -- Generate stream address
	http = "http://stitcher-ipv4.pluto.tv/v1/stitch/embed/hls/channel/"
	token = "?advertisingId=channel&appName=rokuchannel&appVersion=1.0&bmodel=bm1&channel_id=channel&content=channel&content_rating=ROKU_ADS_CONTENT_RATING&content_type=livefeed&coppa=false&deviceDNT=1&deviceId=channel&deviceMake=rokuChannel&deviceModel=web&deviceType=rokuChannel&deviceVersion=1.0&embedPartner=rokuChannel&genre=ROKU_ADS_CONTENT_GENRE&is_lat=1&platform=web&rdid=channel&studio_id=viacom&tags=ROKU_CONTENT_TAGS&profilesFromStream=true"
	local count = 0
	entry = {}
	entry['url'] = http .. url .. "livestitch/master.m3u8" .. token
	count = 1
	ret[count] = {}
	ret[count] = entry
	return count
end

if (getVideoData(_url) > 0) then
	return json:encode(ret)
end

return ""
