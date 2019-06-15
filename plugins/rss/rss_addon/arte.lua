local media = {}
local hex={}
for i=0,255 do
    hex[string.format("%0x",i)]=string.char(i)
    hex[string.format("%0X",i)]=string.char(i)
end

local function decodeURI(s)
    return (s:gsub('%%(%x%x)',hex))
end

function media.getAddonMedia(url,extraUrl)
	local video_url = nil
	local json = require "json"
	local videoTab = nil
	if extraUrl then
		local data = getdata(extraUrl)
		if data then
			local jnTab = json:decode(data)
			if jnTab == nil then return end
			videoTab = jnTab.video
			jnTab = nil
		end
	end
	if url and videoTab == nil then
		local data = getdata(url)
		if data then
			local jsonurl = nil
			local playerdata= data:match('<div class="video%-player"(.-)</div>')
			if playerdata == nil then
				jsonurl = data:match("arte_vp_url='(.-)'") or data:match('json_url=(.-)"')
			else
				jsonurl = playerdata:match('json_url=(.-)"')
			end
			if jsonurl == nil then return end
			jsonurl=jsonurl:gsub('&amp;','&')
			jsonurl = decodeURI(jsonurl)
			data = getdata(jsonurl)
			if data == nil then return end
			local jnTab = json:decode(data)
			if jnTab == nil then return end
			videoTab = jnTab.videoJsonPlayer
-- 			if videoTab.V7T then
-- 				media.newText = videoTab.V7T
-- 			end
			if videoTab.VDE then
				media.newText = videoTab.VDE
			end

			jnTab = nil
		end
	end
	if videoTab then
		local tmp_bitrate = 0
		if videoTab.VTU and videoTab.VTU.IUR then
			media.PicUrl = videoTab.VTU.IUR
		end
		for i,v in pairs(videoTab.VSR) do
			if v.bitrate and v.url then
				v.bitrate = tonumber(v.bitrate)
				local vUrl = nil
				if v.url and v.versionShortLibelle == "DE" then --"DE" "FR" "DE-ANG" "DE-ESP" 
					vUrl = v.url
				elseif v.url and v.versionShortLibelle == "OmU" then --"DE" "FR" "DE-ANG" "DE-ESP" 
					vUrl = v.url
				elseif v.VUR then
					vUrl = v.VUR
				elseif v.url and v.versionShortLibelle then
					vUrl = v.url
					v.bitrate=v.bitrate-4
				end
				if vUrl then
					if vUrl:find("m3u8") then
						v.bitrate=v.bitrate-1 --prio for mp4
					elseif v.mediaType and v.mediaType == "hls" then
						v.bitrate=v.bitrate-2 --prio for mp4
					elseif v.mediaType and v.mediaType == "f4m" then
						v.bitrate=v.bitrate-3 --prio for mp4
					end
					if v.bitrate > tmp_bitrate then
						video_url = vUrl
						tmp_bitrate = v.bitrate
					end
				end
			end
		end
	end
	if video_url and #video_url > 8 then
		if video_url:find("m3u8") then
			local videodata = getdata(video_url)
			local res = 0
			for band, res1, res2, url in videodata:gmatch('#EXT.X.STREAM.INF.-BANDWIDTH=(%d+).-RESOLUTION=(%d+)x(%d+).-(http.-)\n') do
				if url and res1 then
					local nr = tonumber(res1)
					if nr < 2000 and nr > res then
						res=nr
						video_url = url
					end
				end
			end
		end
		media.VideoUrl=video_url
	end
end
return media
