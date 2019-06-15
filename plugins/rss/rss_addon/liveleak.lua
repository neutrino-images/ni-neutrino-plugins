local media = {}
function media.getAddonMedia(url)
	local video_url = nil
	local id = url:match('=(.-)$')
	if id then
		local data = getdata('https://www.liveleak.com/ll_embed?i=' .. id)
		if data then
			local videodata=data:match('<video id(.-)</video>')
			if videodata then
				local image=videodata:match('poster="(.-)"')
				if image then
					media.PicUrl = image
				end
				for vidsrc in videodata:gmatch('<source(.-)>') do
					video_url=vidsrc:match('src="(.-)"')
					if video_url and video_url:find("720p") then
						break
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
