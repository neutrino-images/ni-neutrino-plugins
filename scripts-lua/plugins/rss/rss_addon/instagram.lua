local media = {}

function media.getAddonMedia(url,extraUrl)
	local video_url = nil
	local newText = nil
	media.PicUrl={}
	if url then
		local data = getdata(url)
		if data then
			video_url = data:match('og:video"%s+content="(.-)"')
			if video_url == nil then
				video_url = data:match('og:video:secure_url"%s+content="(.-)"')
			end
		end
	end
	if video_url and #video_url > 8 then
		media.VideoUrl=video_url
	end
end
return media
