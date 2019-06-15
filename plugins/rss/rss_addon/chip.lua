local media = {}
function media.getAddonMedia(url)
	local video_url = nil
	media.PicUrl={}
	if url then
		local data = getdata(url)
		if data then
			local image = data:match('thumbnailUrl" content="(.-)"/>')
			local contentURL = data:match('contentURL" content="(.-)"/>')
			if image then
				media.PicUrl[#media.PicUrl+1] = image
			end
			local vdata = data:match('<video style=(.-)</video>')
			if vdata then
				local pic = vdata:match('thumbnailUrl" content="(.-)"')
				if image == nil and pic then
					media.PicUrl[#media.PicUrl+1] = pic
				end

				local videourl = vdata:match('contentURL" content="(.-)"')
				if videourl then
					video_url = videourl
				end
			end
			if video_url == nil then
				local res = 0
				for item in data:gmatch('<formitaet(.-)</formitaet>') do
					local basetype = item:match('basetype="(.-)"')
					local width = item:match('<width>(%d+)</width>')
					local url = item:match('<url>(.-%.mp4)</url>')
					if url and width then
						local nr = tonumber(width)
						if nr < 2000 and nr > res then
							res=nr
							video_url = url
							break
						end
					end
				end
			end
			if video_url == nil then
				local ytdata = data:match('<div class="NewsArticle__ChapterVideo">(.-)</div>')
				if ytdata then
					local id=ytdata:match('/([_%w%-]+)?')
					if id == nil then
						id=ytdata:match('embed/(.*)?')
					end
					if id then
						local hasaddon,b = pcall(require,"yt_video_url")
						if hasaddon then
							b.getVideoUrl('https://youtube.com/watch?v=' .. id)
							video_url = b.VideoUrl
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
