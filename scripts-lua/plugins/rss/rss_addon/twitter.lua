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

function check_if_double(tab,name)
	for index,value in ipairs(tab) do
		if value == name then
			return false
		end
	end
	return true
end

function media.getAddonMedia(url,extraUrl)
	local video_url = nil
	media.PicUrl={}
	if url then
		local data = getdata(url)
		if data then
			local bpic = data:match ("background%-image:url%('(.-)'")
			if bpic then
				media.PicUrl[#media.PicUrl+1] = bpic
			end

			for pic in data:gmatch ('og:image"%s+content="(http[s]?://[%w%p]+/media/[%w%p]+.[JjGgPp][PpIiNn][Ee]?[GgFf])[%"\'%s%?:]') do
				if check_if_double(media.PicUrl,pic) then
					media.PicUrl[#media.PicUrl+1] = pic
				end
			end
			for mediapic in data:gmatch ('data%-image%-url="(http[s]?://[%w%p]+/media/[%w%p]+.[JjGgPp][PpIiNn][Ee]?[GgFf])[%"\'%s%?]') do
				if check_if_double(media.PicUrl,mediapic) then
					media.PicUrl[#media.PicUrl+1] = mediapic
				end
			end
			if data.find(data, "/videos/") then
				local vurl = "https://twitter.com/i/videos/" .. url:match('/(%d+)')
				data = getdata(vurl)
				if data then
					local skipto = data.find(data, "video_url")
					if skipto and #data > skipto then
					data = string.sub(data,skipto,#data)
					end
					local m3u8_url = data:match('(http.-%.m3u8)')
					if m3u8_url then
						m3u8_url = m3u8_url:gsub("\\","")
						video_url = getVideoUrl(m3u8_url)
					end
					skipto = data.find(data, "image_src")
					if skipto and #data > skipto then
						data = string.sub(data,skipto,#data)
					end
					local pic = data:match('(http.-%.jpg)')
					if pic then
						pic = pic:gsub("\\","")
						if check_if_double(media.PicUrl,pic) then
							media.PicUrl[#media.PicUrl+1] = pic
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
