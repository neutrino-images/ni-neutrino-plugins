local media = {}

function getVideoUrl(m3u8_url)
	if m3u8_url == nil then return nil end
	local videoUrl = nil
	local res = 0
	local data = getdata(m3u8_url)
	if data then
		local host = m3u8_url:match('([%a]+[:]?//[_%w%-%.]+)/')
		if m3u8_url:find('/master.m3u8') then
			local lastpos = (m3u8_url:reverse()):find("/")
			local hosttmp = m3u8_url:sub(1,#m3u8_url-lastpos)
			if hosttmp then
				host = hosttmp .."/"
			end
		end
		for band, res1, res2, url in data:gmatch('BANDWIDTH=(%d+).-RESOLUTION=(%d+)x(%d+).-\n(.-)\n') do
			if url and res1 then
				local nr = tonumber(res1)
				if nr < 2000 and nr > res then
					res=nr
					if host and url:sub(1,4) ~= "http" then
						url = host .. url
					end
					videoUrl = url
				end
			end
		end
	end
	return videoUrl,res
end

function media.getAddonMedia(url)
	local video_url = nil
	local video_url_high = nil
	media.PicUrl={}

	local id = url:match('^.*/([%w%p]+)%.html')
	if id then
		local domain = 'https://zdf-cdn.live.cellular.de/mediathekV2/document/'
		local data = getdata(domain .. id)
		if data then
			local json = require "json"
			local jnTab = json:decode(data)
			if jnTab and jnTab.document and jnTab.document.formitaeten then
				for k, v in pairs(jnTab.document.formitaeten) do
					if v.quality == "veryhigh" and v.url:find("mp4") then
						video_url = v.url
					end
					if v.quality == "high" and v.url:find("mp4") then
						video_url_high = v.url
					end
					if v.quality == "high" and v.url:find("m3u8") then
						local v_url = getVideoUrl(v.url)
						if v_url then
							video_url = v_url
							break
						end
					end
				end
			end
			if jnTab and jnTab.document and jnTab.document.teaserBild then
				for k, v in pairs(jnTab.document.teaserBild) do
					if v.height == 216 then
						media.PicUrl[#media.PicUrl+1] = v.url
					end
				end
			end
		end
	end
	if video_url == nil then
		video_url = video_url_high
	end
	if video_url and #video_url > 8 then
		media.VideoUrl=video_url
	end
end
return media
