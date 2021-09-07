local media = {}

function media.getAddonMedia(url,exturl)
	local video_url = nil
	media.PicUrl={}
	if exturl and exturl:find('ardmediathek') then
		local data = getdata(exturl .. '/')
		if data then
			local picurl = data:match('(https://img.ardmediathek.de/.-/16x9)')
			if picurl then
				media.PicUrl[#media.PicUrl+1] = picurl .. '/384'
			end
			video_url = data:match('"(https://[%w-_%.%?%.:/%+=&]+m3u8)"')
			if video_url then
				video_url = getVideoUrlM3U8(video_url)
			end
		end
	elseif exturl and exturl:find('zdf.de') then
		local data = getdata(exturl)
		if data then
			local picurl = data:match('image" content="(https://[%w-_%.%?%.:/%+=&~]+)"')
			if picurl then
				picurl = picurl:gsub('%d+x%d+','384x216')
				media.PicUrl[#media.PicUrl+1] = picurl
			end
		end
	end

	if video_url == nil and url and url:find('m3u8') then
		video_url = url
	end
	if video_url and #video_url > 8 then
		media.VideoUrl = video_url
	end
end
return media
