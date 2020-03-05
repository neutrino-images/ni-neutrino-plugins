local media = {}

function media.getAddonMedia(url,extraUrl)
	if url == nil then
		url = extraUrl
	end
	if url then
		local data = getdata(url)
		if data then
			local id = data:match('mediaId.-;(%w+)["&]')
			if id then
				video_url = 'https://cdn.jwplayer.com/manifests/' .. id .. '.m3u8'
				if video_url:find("m3u8") then
					local videodata = getdata(video_url)
					local res = 0
					for band, res1, res2, url in videodata:gmatch('#EXT.X.STREAM.INF.-BANDWIDTH=(%d+).-RESOLUTION=(%d+)x(%d+).-(http.-)\n') do
					if url and res1 then
						local nr = tonumber(res1)
						if nr < 4000 and nr > res then
							res=nr
							video_url = url
						end
					end
				end
			end
			media.VideoUrl=video_url
			end
		end
	end
end

return media
