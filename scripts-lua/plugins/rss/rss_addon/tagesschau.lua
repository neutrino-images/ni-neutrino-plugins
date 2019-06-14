local media = {}
function media.getAddonMedia(url)
	local video_url = nil
	local audio_url = nil
	if url then
		local data = getdata(url)
		if data then
			local video_url = nil
			local videodata=data:match('<fieldset>(.-)</fieldset>')
			if videodata then
				for vidsrc in videodata:gmatch('<a(.-)</a>') do
					video_url=vidsrc:match('href="(.-mp4)"')
					if video_url and #video_url > 8 then
						media.VideoUrl=video_url
					else
						local audio = vidsrc:match('href="(.-mp3)"')
						if audio then
							audio_url = audio
						end
					end
				end
			end
		end
	end
	if video_url and #video_url > 8 then
		media.VideoUrl=video_url
	end
	if not video_url and audio_url and #audio_url > 8 then
		media.AudioUrl = audio_url
	end

end
return media
