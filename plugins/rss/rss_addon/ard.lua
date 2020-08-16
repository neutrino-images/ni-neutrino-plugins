local media = {}

function media.getAddonMedia(url)
	local json = require "json"
	local domain = 'http://www.ardmediathek.de/play/media/'
	local id = url:match('documentId=(%d+)$?')
	local video_url = nil
	media.PicUrl={}
	if id then
		local data = getdata(domain .. id)
		if data then
			local jnTab = json:decode(data)
			if jnTab == nil then return end
			local tmp__quality = 0
			local videoTab = nil
			if jnTab._previewImage then
				media.PicUrl[#media.PicUrl+1] = jnTab._previewImage .. id
			end
			local stop = false
			local maxRes = getMaxVideoRes()
			for j,videoTab in ipairs(jnTab._mediaArray) do
				if type(videoTab) == "table" then
					for i,va in pairs(videoTab) do
						if type(va) == "table" then
							if stop then
								break
							end
							for i,v in pairs(va) do
								if type(v._stream)=="string" and v._stream:find("m3u8") then
									local v_url,result = getVideoUrlM3U8(v._stream)
									if v_url then
										video_url = v_url
										if result >= maxRes then
											stop = true
											break
										end
									end
								end
								if  v._quality and type(v._stream)=="string" and v._stream:sub(#v._stream-3,#v._stream) == ".mp4" then
										video_url = v._stream
								elseif type(v._stream) == "table" then
									for j,k in pairs(v._stream) do
										video_url = k
									end
								end
							end
						end
					end
				end
			end
		end
	end
	if video_url and #video_url > 8 then
		media.VideoUrl=video_url
	end
end
return media
