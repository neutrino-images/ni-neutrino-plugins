local media = {}

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
						local v_url = getVideoUrlM3U8(v.url)
						if v_url then
							video_url = v_url
							break
						end
					end
				end
			end
			if jnTab and jnTab.document and jnTab.document.teaserBild then
				for k, v in pairs(jnTab.document.teaserBild) do
					if v.height > 215 or v.height == 1 then
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
