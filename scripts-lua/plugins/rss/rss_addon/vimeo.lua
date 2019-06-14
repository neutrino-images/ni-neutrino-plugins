local media = {}

function media.getAddonMedia(url)
	local video_url = nil
	media.PicUrl={}

	local id = url:match('^.*/([%w%p]+)')
	if id then
		local domain = 'https://player.vimeo.com/video/'
		local data = getdata(domain .. id)
		if data then
			local res = 0
			for item in data:gmatch('{"profile"(.-)}') do
				local width = item:match('"width":(%d+)')
				if width then
					local res_tmp = tonumber(width)
					if res_tmp > res then
						local vurl = item:match('url":"(.-)"')
						if vurl then
							video_url = vurl
							res = res_tmp
						end
					end
				end
			end
			local img = data:match('"640":"(.-_640.jpg)"')
			if img then
				media.PicUrl[#media.PicUrl+1] = img
			end
			if video_url == nil then
				local n = (data:find'"hls":')
				data=data:sub(n,#data)
				local m3u8_url = data:match('"url":"(.-%.m3u8)"')
				if m3u8_url then
					video_url = m3u8_url
				end
			end
		end
	end
	if video_url and #video_url > 8 then
		media.VideoUrl=video_url
	end
end
return media
